# Testing Patterns Reference

## TDD Cycle: Investigate → Reproduce → Test → Fix → Validate → Finalize

### Phase 1: Investigate

Before writing any code, gather information:

```javascript
// Questions to answer:
// 1. What is the expected behavior?
// 2. What are the inputs and outputs?
// 3. What are the edge cases?
// 4. What are the error conditions?
// 5. What dependencies are involved?

// Document findings as comments or acceptance criteria
/**
 * Feature: User Registration
 * 
 * Acceptance Criteria:
 * - Email must be unique
 * - Password must be >= 8 characters
 * - Should send welcome email on success
 * - Should return user without password hash
 */
```

### Phase 2: Reproduce / Plan

For bugs, create a minimal reproduction:

```javascript
// Bug reproduction test
it('reproduces the bug: user not found after creation', async () => {
  // This test documents the bug and should fail
  const user = await userService.createUser(validData);
  const found = await userService.findById(user.id);
  expect(found).toBeDefined(); // Currently fails
});
```

For features, plan the interface:

```javascript
// Interface planning - just the signatures
// userService.createUser(userData) => Promise<User>
// userService.findById(id) => Promise<User | null>
// userService.updateUser(id, updates) => Promise<User>
```

### Phase 3: Test (RED)

Write failing tests following the AAA pattern:

```javascript
describe('UserService', () => {
  describe('createUser', () => {
    // Test name includes: Unit, Scenario, Expected Outcome
    it('should return user with id when valid data provided', async () => {
      // Arrange - setup test data and dependencies
      const userData = {
        email: 'new@example.com',
        password: 'securePass123',
        name: 'Test User'
      };
      
      // Act - execute the code under test
      const result = await userService.createUser(userData);
      
      // Assert - verify the outcomes
      expect(result).toMatchObject({
        id: expect.any(String),
        email: userData.email,
        name: userData.name
      });
      expect(result.password).toBeUndefined();
    });

    it('should throw ValidationError when email already exists', async () => {
      // Arrange
      await createTestUser({ email: 'existing@example.com' });
      const userData = { email: 'existing@example.com', password: 'pass123', name: 'Test' };
      
      // Act & Assert
      await expect(userService.createUser(userData))
        .rejects
        .toThrow(ValidationError);
    });

    it('should throw ValidationError when password too short', async () => {
      // Arrange
      const userData = { email: 'test@example.com', password: 'short', name: 'Test' };
      
      // Act & Assert
      await expect(userService.createUser(userData))
        .rejects
        .toThrow(ValidationError);
    });
  });
});
```

### Phase 4: Fix / Implement (GREEN)

Write minimal code to pass the tests:

```javascript
// Start with the simplest implementation
export class UserService {
  async createUser(userData) {
    // Validate
    const { email, password, name } = validateCreateUser(userData);
    
    // Check uniqueness
    const existing = await this.userRepository.findByEmail(email);
    if (existing) {
      throw new ValidationError('Email already exists');
    }
    
    // Create
    const hashedPassword = await hashPassword(password);
    const user = await this.userRepository.create({
      email,
      password: hashedPassword,
      name
    });
    
    // Return without password
    const { password: _, ...userWithoutPassword } = user;
    return userWithoutPassword;
  }
}
```

### Phase 5: Validate

Run full test suite and check coverage:

```bash
# Run all tests
npm test

# Run with coverage
npm test -- --coverage

# Run specific test file
npm test -- user.service.test.js

# Run in watch mode during development
npm test -- --watch
```

Coverage thresholds to enforce:

```javascript
// jest.config.js
module.exports = {
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    }
  }
};
```

### Phase 6: Finalize (REFACTOR)

Refactor for clarity while keeping tests green:

```javascript
// Before refactoring - everything in one method
async createUser(userData) {
  const { email, password, name } = validateCreateUser(userData);
  const existing = await this.userRepository.findByEmail(email);
  if (existing) throw new ValidationError('Email already exists');
  const hashedPassword = await hashPassword(password);
  const user = await this.userRepository.create({ email, password: hashedPassword, name });
  const { password: _, ...userWithoutPassword } = user;
  return userWithoutPassword;
}

// After refactoring - separated concerns
async createUser(userData) {
  const validated = this.validateUserData(userData);
  await this.ensureEmailUnique(validated.email);
  const user = await this.persistUser(validated);
  return this.sanitizeUser(user);
}

validateUserData(userData) {
  return validateCreateUser(userData);
}

async ensureEmailUnique(email) {
  const existing = await this.userRepository.findByEmail(email);
  if (existing) {
    throw new ValidationError('Email already exists');
  }
}

async persistUser({ email, password, name }) {
  const hashedPassword = await hashPassword(password);
  return this.userRepository.create({ email, password: hashedPassword, name });
}

sanitizeUser(user) {
  const { password, ...safe } = user;
  return safe;
}
```

## Test Types

### Unit Tests
Test individual functions in isolation:

```javascript
describe('hashPassword', () => {
  it('should return hashed string different from input', async () => {
    const password = 'myPassword123';
    const hash = await hashPassword(password);
    
    expect(hash).not.toBe(password);
    expect(hash.length).toBeGreaterThan(0);
  });
});
```

### Integration Tests
Test components working together:

```javascript
describe('POST /api/users', () => {
  it('should create user and return 201', async () => {
    const response = await request(app)
      .post('/api/users')
      .send({ email: 'test@example.com', password: 'password123', name: 'Test' });
    
    expect(response.status).toBe(201);
    expect(response.body.id).toBeDefined();
    
    // Verify side effect - user in database
    const user = await db.users.findById(response.body.id);
    expect(user).toBeDefined();
  });
});
```

### The Five Outcomes to Test

1. **Response** - What is returned
2. **State Change** - Database/memory updates
3. **Outgoing Calls** - External API calls made
4. **Message Queue** - Messages published
5. **Observability** - Logs/metrics emitted

```javascript
describe('OrderService.createOrder', () => {
  // 1. Response
  it('should return order with id', async () => {
    const order = await orderService.createOrder(orderData);
    expect(order.id).toBeDefined();
  });
  
  // 2. State Change
  it('should persist order to database', async () => {
    const order = await orderService.createOrder(orderData);
    const persisted = await db.orders.findById(order.id);
    expect(persisted).toBeDefined();
  });
  
  // 3. Outgoing Calls
  it('should call payment service', async () => {
    const paymentSpy = jest.spyOn(paymentService, 'charge');
    await orderService.createOrder(orderData);
    expect(paymentSpy).toHaveBeenCalledWith(expect.objectContaining({
      amount: orderData.total
    }));
  });
  
  // 4. Message Queue
  it('should publish order.created event', async () => {
    const publishSpy = jest.spyOn(eventBus, 'publish');
    await orderService.createOrder(orderData);
    expect(publishSpy).toHaveBeenCalledWith('order.created', expect.any(Object));
  });
  
  // 5. Observability
  it('should log order creation', async () => {
    const logSpy = jest.spyOn(logger, 'info');
    await orderService.createOrder(orderData);
    expect(logSpy).toHaveBeenCalledWith(expect.stringContaining('Order created'));
  });
});
```

## Test Data Management

### Factory Functions

```javascript
// tests/fixtures/user.factory.js
import { faker } from '@faker-js/faker';

export function buildUser(overrides = {}) {
  return {
    email: faker.internet.email(),
    password: faker.internet.password({ length: 12 }),
    name: faker.person.fullName(),
    ...overrides
  };
}

export async function createTestUser(overrides = {}) {
  const userData = buildUser(overrides);
  return db.users.create(userData);
}
```

### Database Cleanup

```javascript
// tests/setup.js
beforeEach(async () => {
  // Clean specific tables
  await db.query('TRUNCATE users, orders CASCADE');
});

afterAll(async () => {
  await db.end();
});
```

## Mocking Strategies

### Mock External HTTP Services

```javascript
import nock from 'nock';

describe('PaymentService', () => {
  beforeEach(() => {
    nock('https://api.stripe.com')
      .post('/v1/charges')
      .reply(200, { id: 'ch_123', status: 'succeeded' });
  });
  
  afterEach(() => {
    nock.cleanAll();
  });
  
  it('should process payment successfully', async () => {
    const result = await paymentService.charge({ amount: 1000 });
    expect(result.status).toBe('succeeded');
  });
});
```

### Mock Modules

```javascript
// Mock entire module
jest.mock('./email.service.js', () => ({
  sendEmail: jest.fn().mockResolvedValue({ sent: true })
}));

// Spy on method
const sendSpy = jest.spyOn(emailService, 'sendEmail');

// Verify call
expect(sendSpy).toHaveBeenCalledWith({
  to: 'user@example.com',
  subject: 'Welcome',
  body: expect.any(String)
});
```

## Test Tagging

```javascript
// Use describe.skip or it.skip for work in progress
describe.skip('Feature in development', () => {});

// Use describe.only or it.only for focused testing
describe.only('Current focus', () => {});

// Custom tags via naming
describe('[integration] Database operations', () => {});
describe('[e2e] User journey', () => {});
```

Run by pattern:
```bash
npm test -- --testPathPattern="integration"
npm test -- --testNamePattern="UserService"
```
