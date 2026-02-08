# Node Builder Context Injection

This context is injected into every Node Builder agent dispatch.

## TDD Workflow (NON-NEGOTIABLE)

```
1. RED: Write failing test FIRST, confirm it FAILS
2. GREEN: Write MINIMAL code to pass
3. REFACTOR: Clean up while green
```

## Build Quality Gates

Before completing, ALL must pass:
```bash
npm test
npm run lint
```

---

## Project Structure

### Component-Based Layout

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
├── package.json
├── package-lock.json
└── jest.config.js            # or vitest.config.js
```

### Layer Responsibilities

| Layer | Path | Contains |
|-------|------|----------|
| Routes | `src/components/[name]/[name].routes.js` | Route definitions, middleware wiring |
| Controller | `src/components/[name]/[name].controller.js` | HTTP request/response handling |
| Service | `src/components/[name]/[name].service.js` | Business logic, orchestration |
| Repository | `src/components/[name]/[name].repository.js` | Data access, queries |
| Validation | `src/components/[name]/[name].validation.js` | Input validation schemas (Zod) |
| Errors | `src/errors/` | Custom error classes |

---

## ES Modules

Use ES Modules as the default module system:

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
import { randomUUID } from 'node:crypto';
```

---

## Code Patterns

### Async/Await

```javascript
// Always use async/await
async function getUser(id) {
  const user = await userRepository.findById(id);
  if (!user) {
    throw new NotFoundError(`User ${id} not found`);
  }
  return user;
}

// Always await before returning promises (preserves stack trace)
async function processOrder(orderId) {
  return await orderService.process(orderId);
}
```

### Error Handling

```javascript
// Custom error classes extending Error
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

### Centralized Error Handler

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

### Controller Pattern

```javascript
export class UserController {
  constructor(userService = new UserService()) {
    this.userService = userService;
  }

  // Arrow functions preserve 'this' binding
  create = async (req, res, next) => {
    try {
      const user = await this.userService.createUser(req.body);
      res.status(201).json(user);
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
}
```

### Service Pattern

```javascript
export class UserService {
  constructor(userRepository = new UserRepository()) {
    this.userRepository = userRepository;
  }

  async createUser(userData) {
    const existing = await this.userRepository.findByEmail(userData.email);
    if (existing) {
      throw new ValidationError('Email already registered');
    }

    const hashedPassword = await hashPassword(userData.password);
    const user = await this.userRepository.create({
      ...userData,
      password: hashedPassword,
    });

    return this.sanitize(user);
  }

  sanitize(user) {
    const { password, ...safe } = user;
    return safe;
  }
}
```

### Configuration with Zod

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

### Input Validation with Zod

```javascript
import { z } from 'zod';

export const createUserSchema = z.object({
  email: z.string().email('Invalid email format'),
  password: z.string().min(8).max(100),
  name: z.string().min(1).max(255),
});

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
```

---

## Testing Patterns

### AAA Pattern (Arrange, Act, Assert)

```javascript
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

### Test Data Isolation

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

### Factory Functions

```javascript
// tests/fixtures/user.factory.js
import { faker } from '@faker-js/faker';

export function buildUser(overrides = {}) {
  return {
    email: faker.internet.email(),
    password: faker.internet.password({ length: 12 }),
    name: faker.person.fullName(),
    ...overrides,
  };
}

export async function createTestUser(overrides = {}) {
  const userData = buildUser(overrides);
  return db.users.create(userData);
}
```

### Mock External Services

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

### Integration Tests

```javascript
import request from 'supertest';

describe('POST /api/users', () => {
  it('should create user and return 201', async () => {
    const response = await request(app)
      .post('/api/users')
      .send({ email: 'test@example.com', password: 'password123', name: 'Test' });

    expect(response.status).toBe(201);
    expect(response.body.id).toBeDefined();

    // Verify side effect
    const user = await db.users.findById(response.body.id);
    expect(user).toBeDefined();
  });
});
```

---

## Common Lint Fixes

| Error | WRONG Fix | CORRECT Fix |
|-------|-----------|-------------|
| `no-unused-vars` | Comment out | Remove or use the variable |
| `prefer-const` | Use `let` | Use `const` when no reassignment |
| `no-throw-literal` | `throw 'error'` | `throw new Error('error')` |
| `require-await` | Remove async | Return the promise properly |
| `no-return-await` | Remove await | Keep await (preserves stack trace) |
| `unhandled promise` | Add `.catch(() => {})` | Handle error properly |
| `callback hell` | More nesting | Refactor to async/await |

---

## Systematic Debugging (When Stuck)

If tests fail repeatedly:

### Phase 1: Root Cause Investigation
1. Read error messages COMPLETELY
2. Reproduce consistently
3. Check recent changes (git diff)
4. Trace data flow from source to error

### Phase 2: Pattern Analysis
1. Find working examples in codebase
2. Compare against references
3. Identify differences

### Phase 3: Hypothesis Testing
1. Form ONE clear hypothesis
2. Change ONE variable
3. Verify before continuing

### Red Flags - STOP If:
- "Quick fix for now"
- "Just try changing X"
- Already tried 3+ fixes
- Proposing solutions BEFORE tracing data flow

**Gate Function:**
```
BEFORE any fix:
  Ask: "Do I know the ROOT CAUSE?"
  IF no: STOP - Return to Phase 1
  IF yes: Document it, THEN fix
```

---

## Testing Anti-Patterns to Avoid

### Never Test Mock Behavior

```javascript
// BAD - Testing the mock, not the code
it('should call repository', async () => {
  const mockRepo = { findById: jest.fn().mockResolvedValue(user) };
  const service = new UserService(mockRepo);
  await service.getUser('123');
  expect(mockRepo.findById).toHaveBeenCalledWith('123');  // WHO CARES?
});

// GOOD - Test actual behavior
it('should return user data', async () => {
  const service = new UserService(testRepo);
  const result = await service.getUser('123');
  expect(result.email).toBe('test@example.com');
});
```

### Never Add Test-Only Methods to Production

```javascript
// BAD - Test pollution
class Cache {
  reset() {  // Only used in tests!
    this.data = new Map();
  }
}

// GOOD - Create fresh instances in tests
beforeEach(() => {
  cache = new Cache();
});
```

### Mock Gate Function

```
BEFORE mocking any method:
  1. "What side effects does the real method have?"
  2. "Does this test depend on those side effects?"
  3. "Do I fully understand what this test needs?"

IF depends on side effects:
  Mock at LOWER level, not the method test depends on
```

---

## Security Checklist

- [ ] Validate all user input with Zod
- [ ] Use parameterized queries (never string concat for SQL)
- [ ] Hash passwords with bcrypt (cost >= 12)
- [ ] Use helmet for HTTP security headers
- [ ] Implement rate limiting on auth endpoints
- [ ] Never log sensitive data (passwords, tokens)
- [ ] Use `node:` prefix for built-in modules
- [ ] Set CORS properly for production

---

## Graceful Shutdown

```javascript
async function shutdown(signal) {
  logger.info(`Received ${signal}, starting graceful shutdown`);
  server.close();
  await new Promise((resolve) => server.on('close', resolve));
  await db.end();
  logger.info('Graceful shutdown complete');
  process.exit(0);
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
```

---

## Output Format

```yaml
task_id: {task.id}
task_name: "{task.name}"
status: complete|blocked|needs_clarification

files_created:
  - path: [path]
    purpose: [why]
files_modified:
  - path: [path]
    changes: [what changed]
tests_added:
  - name: [test name]
    file: [test file]
    covers: [what it tests]

validation:
  test: pass|fail
  lint: pass|fail

commits:
  - hash: [short hash]
    message: [message]

summary: [1-2 sentences]
```
