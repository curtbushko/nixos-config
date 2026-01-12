# API Design Reference

## REST API Structure

### Route Organization

```javascript
// src/components/users/user.routes.js
import { Router } from 'express';
import { UserController } from './user.controller.js';
import { validateBody } from '../../middleware/validation.js';
import { authenticate } from '../../middleware/auth.js';
import { createUserSchema, updateUserSchema } from './user.validation.js';

const router = Router();
const controller = new UserController();

// Public routes
router.post('/', validateBody(createUserSchema), controller.create);

// Protected routes
router.use(authenticate);
router.get('/', controller.list);
router.get('/:id', controller.getById);
router.patch('/:id', validateBody(updateUserSchema), controller.update);
router.delete('/:id', controller.delete);

export default router;
```

### Controller Pattern

```javascript
// src/components/users/user.controller.js
export class UserController {
  constructor(userService = new UserService()) {
    this.userService = userService;
  }

  // Arrow functions to preserve 'this' binding
  create = async (req, res, next) => {
    try {
      const user = await this.userService.createUser(req.body);
      res.status(201).json(user);
    } catch (error) {
      next(error);
    }
  };

  list = async (req, res, next) => {
    try {
      const { page = 1, limit = 20, sort } = req.query;
      const result = await this.userService.listUsers({ page, limit, sort });
      res.json(result);
    } catch (error) {
      next(error);
    }
  };

  getById = async (req, res, next) => {
    try {
      const user = await this.userService.getUserById(req.params.id);
      res.json(user);
    } catch (error) {
      next(error);
    }
  };

  update = async (req, res, next) => {
    try {
      const user = await this.userService.updateUser(req.params.id, req.body);
      res.json(user);
    } catch (error) {
      next(error);
    }
  };

  delete = async (req, res, next) => {
    try {
      await this.userService.deleteUser(req.params.id);
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  };
}
```

### Service Layer

```javascript
// src/components/users/user.service.js
import { NotFoundError, ValidationError } from '../../errors/index.js';
import { UserRepository } from './user.repository.js';
import { hashPassword } from '../../utils/crypto.js';

export class UserService {
  constructor(userRepository = new UserRepository()) {
    this.userRepository = userRepository;
  }

  async createUser(userData) {
    // Business logic validation
    const existingUser = await this.userRepository.findByEmail(userData.email);
    if (existingUser) {
      throw new ValidationError('Email already registered');
    }

    // Transform data
    const hashedPassword = await hashPassword(userData.password);
    
    // Persist
    const user = await this.userRepository.create({
      ...userData,
      password: hashedPassword,
    });

    // Return sanitized result
    return this.sanitize(user);
  }

  async getUserById(id) {
    const user = await this.userRepository.findById(id);
    if (!user) {
      throw new NotFoundError(`User ${id} not found`);
    }
    return this.sanitize(user);
  }

  async listUsers({ page, limit, sort }) {
    const offset = (page - 1) * limit;
    const [users, total] = await Promise.all([
      this.userRepository.findAll({ offset, limit, sort }),
      this.userRepository.count(),
    ]);

    return {
      data: users.map(this.sanitize),
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  sanitize(user) {
    const { password, ...safe } = user;
    return safe;
  }
}
```

## Request Validation

### Using Zod

```javascript
// src/components/users/user.validation.js
import { z } from 'zod';

export const createUserSchema = z.object({
  email: z.string().email('Invalid email format'),
  password: z.string()
    .min(8, 'Password must be at least 8 characters')
    .max(100, 'Password too long'),
  name: z.string()
    .min(1, 'Name is required')
    .max(255, 'Name too long'),
});

export const updateUserSchema = z.object({
  name: z.string().min(1).max(255).optional(),
  email: z.string().email().optional(),
}).refine(data => Object.keys(data).length > 0, {
  message: 'At least one field must be provided',
});

export const querySchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  sort: z.enum(['name', 'email', 'createdAt']).optional(),
  order: z.enum(['asc', 'desc']).default('asc'),
});
```

### Validation Middleware

```javascript
// src/middleware/validation.js
import { ValidationError } from '../errors/index.js';

export function validateBody(schema) {
  return (req, res, next) => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      const errors = result.error.errors.map(e => ({
        field: e.path.join('.'),
        message: e.message,
      }));
      throw new ValidationError('Validation failed', errors);
    }
    req.body = result.data;
    next();
  };
}

export function validateQuery(schema) {
  return (req, res, next) => {
    const result = schema.safeParse(req.query);
    if (!result.success) {
      const errors = result.error.errors.map(e => ({
        field: e.path.join('.'),
        message: e.message,
      }));
      throw new ValidationError('Invalid query parameters', errors);
    }
    req.query = result.data;
    next();
  };
}
```

## Error Response Format

### Consistent Error Structure

```javascript
// Error response format
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": [
      { "field": "email", "message": "Invalid email format" },
      { "field": "password", "message": "Password must be at least 8 characters" }
    ]
  }
}

// Not found response
{
  "error": {
    "code": "NOT_FOUND",
    "message": "User abc123 not found"
  }
}

// Internal error response (production)
{
  "error": {
    "code": "INTERNAL_ERROR",
    "message": "An unexpected error occurred"
  }
}
```

### Error Handler Implementation

```javascript
// src/middleware/error-handler.js
import { logger } from '../utils/logger.js';
import { AppError, ValidationError, NotFoundError } from '../errors/index.js';

const ERROR_CODES = {
  ValidationError: 'VALIDATION_ERROR',
  NotFoundError: 'NOT_FOUND',
  UnauthorizedError: 'UNAUTHORIZED',
  ForbiddenError: 'FORBIDDEN',
  ConflictError: 'CONFLICT',
};

export function errorHandler(err, req, res, next) {
  // Log error with context
  logger.error({
    message: err.message,
    stack: err.stack,
    code: err.code,
    path: req.path,
    method: req.method,
    requestId: req.requestId,
  });

  // Handle known operational errors
  if (err.isOperational) {
    const code = ERROR_CODES[err.name] || 'ERROR';
    return res.status(err.statusCode).json({
      error: {
        code,
        message: err.message,
        ...(err.errors && { details: err.errors }),
      },
    });
  }

  // Handle unknown errors
  res.status(500).json({
    error: {
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred',
    },
  });
}
```

## Response Formats

### Success Responses

```javascript
// Single resource
// GET /api/users/123
{
  "id": "123",
  "email": "user@example.com",
  "name": "John Doe",
  "createdAt": "2024-01-15T10:30:00Z"
}

// Collection with pagination
// GET /api/users?page=1&limit=20
{
  "data": [
    { "id": "123", "email": "user@example.com", "name": "John Doe" },
    { "id": "124", "email": "jane@example.com", "name": "Jane Doe" }
  ],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 150,
    "totalPages": 8
  }
}

// Created resource
// POST /api/users (201 Created)
{
  "id": "125",
  "email": "new@example.com",
  "name": "New User",
  "createdAt": "2024-01-15T12:00:00Z"
}
```

### HTTP Status Codes

```javascript
// Success codes
200 // OK - GET, PUT, PATCH
201 // Created - POST
204 // No Content - DELETE

// Client error codes
400 // Bad Request - Validation errors
401 // Unauthorized - Authentication required
403 // Forbidden - Insufficient permissions
404 // Not Found - Resource doesn't exist
409 // Conflict - Resource already exists
422 // Unprocessable Entity - Business rule violation

// Server error codes
500 // Internal Server Error
503 // Service Unavailable
```

## API Versioning

### URL Path Versioning

```javascript
// src/app.js
import v1Routes from './routes/v1/index.js';
import v2Routes from './routes/v2/index.js';

app.use('/api/v1', v1Routes);
app.use('/api/v2', v2Routes);
```

## OpenAPI Documentation

```javascript
// Using swagger-jsdoc
/**
 * @openapi
 * /api/users:
 *   post:
 *     summary: Create a new user
 *     tags: [Users]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/CreateUser'
 *     responses:
 *       201:
 *         description: User created successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/User'
 *       400:
 *         description: Validation error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */
```

## Security Headers

```javascript
// src/app.js
import helmet from 'helmet';

app.use(helmet());

// Custom CORS configuration
import cors from 'cors';

app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
  maxAge: 86400, // 24 hours
}));
```

## Rate Limiting

```javascript
import rateLimit from 'express-rate-limit';

// General API rate limit
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error: {
      code: 'RATE_LIMIT_EXCEEDED',
      message: 'Too many requests, please try again later',
    },
  },
});

// Strict limit for authentication endpoints
const authLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 5,
  message: {
    error: {
      code: 'RATE_LIMIT_EXCEEDED',
      message: 'Too many login attempts, please try again later',
    },
  },
});

app.use('/api', apiLimiter);
app.use('/api/auth/login', authLimiter);
```
