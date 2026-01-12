---
name: nodejs-tdd
description: Comprehensive Node.js development skill with best practices for project structure, coding patterns, and Test-Driven Development. Use this skill when building Node.js applications, APIs, or backend services. Covers project layout, ES modules, async patterns, error handling, security, and implements TDD with a structured workflow (Investigate → Reproduce → Test → Fix → Validate → Finalize).
---

# Node.js TDD Development Skill

This skill provides guidance for building high-quality Node.js applications using best practices and Test-Driven Development (TDD).

## TDD Workflow

**IMPORTANT**: Every feature implementation MUST follow this TDD workflow:

### 1. Investigate
- Understand the requirement thoroughly
- Review existing code and related modules
- Identify dependencies and potential side effects
- Document acceptance criteria

### 2. Reproduce (for bugs) / Plan (for features)
- For bugs: Create a minimal reproduction case
- For features: Design the interface/API before implementation
- Identify edge cases and error scenarios
- Plan test scenarios

### 3. Test
- Write failing tests FIRST (Red phase)
- Structure tests using AAA pattern (Arrange, Act, Assert)
- Include positive and negative test cases
- Test edge cases and error handling

```javascript
// Test naming: describe WHAT, WHEN, and EXPECTED outcome
describe('UserService', () => {
  describe('createUser', () => {
    it('should create user when valid email provided', async () => {
      // Arrange
      const userData = { email: 'test@example.com', name: 'Test' };
      
      // Act
      const result = await userService.createUser(userData);
      
      // Assert
      expect(result.id).toBeDefined();
      expect(result.email).toBe(userData.email);
    });

    it('should throw ValidationError when email is invalid', async () => {
      // Arrange
      const userData = { email: 'invalid', name: 'Test' };
      
      // Act & Assert
      await expect(userService.createUser(userData))
        .rejects.toThrow(ValidationError);
    });
  });
});
```

### 4. Fix / Implement
- Write minimal code to pass the test (Green phase)
- Follow SOLID principles
- Keep functions small and focused
- Use async/await for asynchronous code

### 5. Validate
- Run all tests to ensure no regressions
- Check code coverage (aim for >80%)
- Run linter (ESLint) to catch issues
- Review error handling completeness

### 6. Finalize
- Refactor for clarity and maintainability
- Remove dead code and console.logs
- Update documentation if needed
- Commit with descriptive message

## Project Structure

Use component-based architecture with clear separation of concerns:

```
project-root/
├── src/
│   ├── components/           # Business domain modules
│   │   ├── users/
│   │   │   ├── user.controller.js
│   │   │   ├── user.service.js
│   │   │   ├── user.repository.js
│   │   │   ├── user.model.js
│   │   │   ├── user.routes.js
│   │   │   ├── user.validation.js
│   │   │   └── __tests__/
│   │   │       ├── user.service.test.js
│   │   │       └── user.controller.test.js
│   │   ├── orders/
│   │   └── payments/
│   ├── middleware/           # Express/Fastify middleware
│   ├── config/               # Configuration management
│   │   └── index.js
│   ├── utils/                # Shared utilities
│   ├── errors/               # Custom error classes
│   └── app.js                # Application setup
├── tests/
│   ├── integration/          # API/Integration tests
│   ├── e2e/                  # End-to-end tests
│   └── fixtures/             # Test data factories
├── .env.example
├── .nvmrc                    # Node version specification
├── package.json
├── package-lock.json
└── jest.config.js
```

## ES Modules

Use ES Modules (ESM) as the default module system:

```json
// package.json
{
  "type": "module",
  "engines": {
    "node": ">=20.0.0"
  }
}
```

```javascript
// Use import/export syntax
import { createServer } from 'node:http';
import express from 'express';
import { UserService } from './user.service.js';

export const userService = new UserService();
```

Import built-in modules with `node:` protocol:
```javascript
import { readFile } from 'node:fs/promises';
import { join } from 'node:path';
import { EventEmitter } from 'node:events';
```

## Async Patterns

### Always use async/await
```javascript
// ✅ Good
async function getUser(id) {
  const user = await userRepository.findById(id);
  if (!user) {
    throw new NotFoundError(`User ${id} not found`);
  }
  return user;
}

// ❌ Avoid callbacks
function getUser(id, callback) {
  userRepository.findById(id, (err, user) => {
    if (err) return callback(err);
    callback(null, user);
  });
}
```

### Always await before returning promises
```javascript
// ✅ Good - full stack trace preserved
async function processOrder(orderId) {
  return await orderService.process(orderId);
}

// ❌ Avoid - partial stack trace
async function processOrder(orderId) {
  return orderService.process(orderId);
}
```

### Handle Promise rejections
```javascript
process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection:', { reason, promise });
  // Graceful shutdown
  process.exit(1);
});
```

## Error Handling

### Extend built-in Error
```javascript
// src/errors/app-error.js
export class AppError extends Error {
  constructor(message, statusCode = 500, isOperational = true) {
    super(message);
    this.name = this.constructor.name;
    this.statusCode = statusCode;
    this.isOperational = isOperational;
    Error.captureStackTrace(this, this.constructor);
  }
}

export class NotFoundError extends AppError {
  constructor(message = 'Resource not found') {
    super(message, 404);
  }
}

export class ValidationError extends AppError {
  constructor(message, errors = []) {
    super(message, 400);
    this.errors = errors;
  }
}
```

### Centralized error handler
```javascript
// src/middleware/error-handler.js
export function errorHandler(err, req, res, next) {
  logger.error({
    message: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method,
  });

  if (err.isOperational) {
    return res.status(err.statusCode).json({
      error: err.message,
      ...(err.errors && { details: err.errors }),
    });
  }

  // Programmer error - don't leak details
  res.status(500).json({ error: 'Internal server error' });
}
```

### Subscribe to EventEmitter errors
```javascript
const emitter = new EventEmitter({ captureRejections: true });
emitter.on('error', (err) => {
  logger.error('EventEmitter error:', err);
});
```

## Configuration

Use environment-aware, hierarchical configuration:

```javascript
// src/config/index.js
import { z } from 'zod';

const configSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().default(3000),
  DATABASE_URL: z.string().url(),
  JWT_SECRET: z.string().min(32),
  LOG_LEVEL: z.enum(['debug', 'info', 'warn', 'error']).default('info'),
});

const config = configSchema.parse(process.env);
export default config;
```

## Testing Best Practices

### Testing setup
```javascript
// jest.config.js
export default {
  testEnvironment: 'node',
  transform: {},
  coverageThreshold: {
    global: { branches: 80, functions: 80, lines: 80, statements: 80 },
  },
  setupFilesAfterEnv: ['./tests/setup.js'],
};
```

### Test file naming
- Unit tests: `*.test.js` (co-located with source)
- Integration tests: `*.integration.test.js`
- E2E tests: `*.e2e.test.js`

### Test data isolation
```javascript
// Each test manages its own data
beforeEach(async () => {
  await db.truncate(['users', 'orders']);
});

it('should find user by email', async () => {
  // Arrange - test creates its own data
  const user = await createTestUser({ email: 'test@example.com' });
  
  // Act
  const found = await userService.findByEmail('test@example.com');
  
  // Assert
  expect(found.id).toBe(user.id);
});
```

### Mock external services
```javascript
import nock from 'nock';

beforeEach(() => {
  nock('https://api.external.com')
    .get('/users/123')
    .reply(200, { id: '123', name: 'Test User' });
});

afterEach(() => {
  nock.cleanAll();
});
```

### Randomize test port
```javascript
// Start server with random port for parallel tests
const server = app.listen(0);
const { port } = server.address();
```

## Code Style

### Use ESLint with security plugins
```json
// .eslintrc.json
{
  "extends": [
    "eslint:recommended",
    "plugin:security/recommended",
    "plugin:node/recommended"
  ],
  "plugins": ["security"],
  "rules": {
    "no-throw-literal": "error",
    "prefer-const": "error",
    "no-var": "error"
  }
}
```

### Naming conventions
- `lowerCamelCase` for variables and functions
- `UpperCamelCase` for classes
- `UPPER_SNAKE_CASE` for constants
- Name all functions (no anonymous functions)

### Icons and symbols
- Use Nerd Fonts instead of emojis for console output, CLI tools, and logging
- Nerd Fonts provide consistent rendering across terminals and editors
- Examples: ``, ``, ``, ``, ``, ``, ``
- Install: https://www.nerdfonts.com/

```javascript
// ✅ Good - Nerd Font icons
console.log(' Server started on port 3000');
console.log(' User created successfully');
console.log(' Connection failed');
console.log(' Running tests...');

// ❌ Avoid - Emojis (inconsistent rendering)
console.log('🚀 Server started on port 3000');
console.log('✅ User created successfully');
```

### Function structure
```javascript
// ✅ Small, focused functions with descriptive names
async function validateUserEmail(email) {
  const existing = await userRepository.findByEmail(email);
  if (existing) {
    throw new ValidationError('Email already registered');
  }
  return true;
}

// ✅ Avoid effects outside functions
// Bad: runs on import
const db = connectToDatabase();

// Good: explicit initialization
export function initializeDatabase() {
  return connectToDatabase();
}
```

## Security

### Input validation
```javascript
import { z } from 'zod';

const createUserSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8).max(100),
  name: z.string().min(1).max(255),
});

export function validateCreateUser(data) {
  return createUserSchema.parse(data);
}
```

### Rate limiting
```javascript
import rateLimit from 'express-rate-limit';

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,
  standardHeaders: true,
});

app.use('/api/', limiter);
```

### Password hashing
```javascript
import bcrypt from 'bcrypt';

const SALT_ROUNDS = 12;

export async function hashPassword(password) {
  return bcrypt.hash(password, SALT_ROUNDS);
}

export async function verifyPassword(password, hash) {
  return bcrypt.compare(password, hash);
}
```

### Helmet for HTTP headers
```javascript
import helmet from 'helmet';
app.use(helmet());
```

## Logging

Use structured logging with Pino:

```javascript
import pino from 'pino';

export const logger = pino({
  level: config.LOG_LEVEL,
  formatters: {
    level: (label) => ({ level: label }),
  },
  // Production: JSON to stdout
  // Development: pretty print
  transport: config.NODE_ENV === 'development'
    ? { target: 'pino-pretty' }
    : undefined,
});
```

### Add transaction IDs
```javascript
import { AsyncLocalStorage } from 'node:async_hooks';
import { randomUUID } from 'node:crypto';

const asyncLocalStorage = new AsyncLocalStorage();

export function requestIdMiddleware(req, res, next) {
  const requestId = req.headers['x-request-id'] || randomUUID();
  asyncLocalStorage.run({ requestId }, () => {
    req.requestId = requestId;
    res.setHeader('x-request-id', requestId);
    next();
  });
}

export function getRequestId() {
  return asyncLocalStorage.getStore()?.requestId;
}
```

## Graceful Shutdown

```javascript
async function shutdown(signal) {
  logger.info(`Received ${signal}, starting graceful shutdown`);
  
  // Stop accepting new requests
  server.close();
  
  // Wait for existing requests to complete
  await new Promise((resolve) => {
    server.on('close', resolve);
  });
  
  // Close database connections
  await db.end();
  
  logger.info('Graceful shutdown complete');
  process.exit(0);
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
```

## Dependencies

### Lock versions
Always commit `package-lock.json` and use `npm ci` in CI/CD.

### Audit regularly
```bash
npm audit
npm outdated
```

### Node version management
Create `.nvmrc` file:
```
20.11.0
```

## Quick Reference

| Category | Do | Don't |
|----------|----|----|
| Modules | ES Modules with `node:` prefix | CommonJS `require()` |
| Async | `async/await` | Callbacks |
| Variables | `const`, then `let` | `var` |
| Errors | Custom Error classes | Throwing strings |
| Config | Environment variables + validation | Hardcoded values |
| Tests | TDD with AAA pattern | No tests / tests after |
| Security | Validate all inputs | Trust user input |

## Additional Resources

- For testing patterns: See `references/testing-patterns.md`
- For API design: See `references/api-design.md`
