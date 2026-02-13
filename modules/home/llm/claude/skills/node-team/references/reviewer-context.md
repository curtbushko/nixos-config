# Node Reviewer Context Injection

This context is injected into every Node Reviewer agent dispatch.

---

## Lint Verification

Before approving, confirm lint passes. Run whichever applies:
```bash
make lint            # if Makefile exists
task lint            # if Taskfile exists (fallback if no Makefile)
```

---

## Review Priority Order

```
CRITICAL (must fix before merge):
├── Unhandled promise rejections
├── Security vulnerabilities (injection, XSS)
├── Resource leaks (unclosed connections, streams)
└── Missing error handling in async code

MAJOR (should fix):
├── Architecture violations
├── Async/await anti-patterns
├── Testing quality
└── Input validation gaps

MINOR (consider):
├── Naming conventions
├── Performance optimization
└── Code organization
```

---

## AI-Generated Code Problems (MUST CHECK)

AI code generators consistently make these mistakes. Check explicitly:

### 1. Error Handling Issues (Critical)

```javascript
// AI MISTAKE: Swallowing errors
try {
  await doWork();
} catch (err) {
  console.log(err);  // Logged but not handled!
}

// AI MISTAKE: Empty catch block
try {
  await riskyOperation();
} catch {}  // Completely swallowed!

// AI MISTAKE: Throwing strings
throw 'something went wrong';  // No stack trace!

// AI MISTAKE: Not propagating errors in middleware
app.get('/users', async (req, res) => {
  const users = await userService.list();  // Unhandled rejection!
  res.json(users);
});
```

**Check for:**
- Empty `catch` blocks
- `catch` that only logs but doesn't rethrow or handle
- Missing `try/catch` in Express route handlers
- Throwing strings or plain objects instead of Error instances
- Missing `next(error)` in middleware

### 2. Async/Await Pitfalls (Critical)

```javascript
// AI MISTAKE: Forgetting await
async function getUser(id) {
  const user = userRepository.findById(id);  // Missing await!
  return user;  // Returns Promise, not User
}

// AI MISTAKE: Sequential when parallel possible
const users = await getUsers();
const orders = await getOrders();
// Should be: const [users, orders] = await Promise.all([getUsers(), getOrders()])

// AI MISTAKE: await in loop (sequential instead of parallel)
for (const id of ids) {
  const user = await getUser(id);  // N sequential queries!
  results.push(user);
}
// Should be: const results = await Promise.all(ids.map(getUser))

// AI MISTAKE: Missing return await (loses stack trace)
async function processOrder(id) {
  return orderService.process(id);  // Missing await!
}
```

**Check for:**
- Missing `await` on async calls
- Sequential `await` that could be `Promise.all`
- `await` inside loops
- Missing `return await` (stack trace preservation)
- Floating promises (async call without await or .catch)

### 3. Security Vulnerabilities (Critical)

```javascript
// AI MISTAKE: SQL injection
const query = `SELECT * FROM users WHERE id = '${userId}'`;  // INJECTION!

// AI MISTAKE: XSS through template literals
res.send(`<h1>Hello ${req.query.name}</h1>`);  // XSS!

// AI MISTAKE: Exposing stack traces in production
app.use((err, req, res, next) => {
  res.status(500).json({ error: err.message, stack: err.stack });  // LEAK!
});

// AI MISTAKE: Hardcoded secrets
const JWT_SECRET = 'my-secret-key';  // NEVER HARDCODE!

// AI MISTAKE: No rate limiting on auth
app.post('/login', loginHandler);  // No rate limit = brute force!

// AI MISTAKE: Using eval or Function constructor
const result = eval(userInput);  // REMOTE CODE EXECUTION!
```

**Check for:**
- String concatenation in queries (SQL injection)
- Unsanitized user input in HTML responses (XSS)
- Stack traces exposed in production error responses
- Hardcoded secrets, API keys, passwords
- Missing rate limiting on authentication endpoints
- `eval()`, `Function()`, `vm.runInNewContext()` with user input
- Missing CORS configuration
- Missing security headers (use helmet)

### 4. Resource Leaks (Critical)

```javascript
// AI MISTAKE: Database connection not released
const client = await pool.connect();
const result = await client.query('SELECT...');
// Missing: client.release() in finally block!

// AI MISTAKE: Stream not properly closed on error
const readStream = fs.createReadStream(file);
readStream.pipe(writeStream);
// Missing: error handler for readStream!

// AI MISTAKE: Event listeners not cleaned up
function setup() {
  process.on('message', handler);
  // Never removed - memory leak if called multiple times!
}

// AI MISTAKE: Timers not cleared
const interval = setInterval(poll, 1000);
// Missing: clearInterval on shutdown
```

**Check for:**
- Database connections not released in `finally` blocks
- Streams without error handlers
- Event listeners not removed on cleanup
- `setInterval`/`setTimeout` not cleared
- HTTP responses not ended

### 5. Unhandled Promise Rejections (Critical)

```javascript
// AI MISTAKE: Fire-and-forget async
app.listen(3000, () => {
  initializeDatabase();  // Unhandled if it rejects!
});

// AI MISTAKE: Missing error event on streams
const stream = fs.createReadStream(path);
stream.pipe(res);  // Error crashes process!

// AI MISTAKE: Promise.all without error handling
const results = await Promise.all(urls.map(fetch));
// One failure rejects everything with no info about which!
```

**Check for:**
- Async functions called without `await` or `.catch()`
- Missing `'error'` event handlers on streams and emitters
- `Promise.all` without considering `Promise.allSettled`
- Missing `process.on('unhandledRejection')` handler

### 6. Type Coercion Issues (High)

```javascript
// AI MISTAKE: Loose equality
if (userId == null) { }     // Matches both null and undefined
if (count == 0) { }          // '0' == 0 is true!

// AI MISTAKE: Truthy/falsy misuse
if (user.age) { }            // 0 is falsy! Age 0 treated as missing
if (user.name) { }           // '' is falsy! Empty string treated as missing

// AI MISTAKE: parseInt without radix
const port = parseInt(process.env.PORT);  // Missing radix!
```

**Check for:**
- `==` instead of `===`
- Truthy/falsy checks on numbers (0 is falsy)
- Truthy/falsy checks on strings ('' is falsy)
- `parseInt` without radix parameter
- Implicit type coercion in comparisons

### 7. Module and Import Issues (High)

```javascript
// AI MISTAKE: Side effects on import
// db.js
const db = connectToDatabase();  // Runs on import!
export default db;

// AI MISTAKE: Missing .js extension in ESM
import { UserService } from './user.service';  // Needs .js!

// AI MISTAKE: Mixing CJS and ESM
const express = require('express');  // CJS in ESM project!
```

**Check for:**
- Code that runs on import (side effects)
- Missing `.js` extensions in ESM imports
- Mixing `require()` and `import`
- Circular dependencies

### 8. Environment and Configuration (High)

```javascript
// AI MISTAKE: Direct process.env access everywhere
function getPort() {
  return process.env.PORT || 3000;  // Scattered env access!
}

// AI MISTAKE: No validation
const dbUrl = process.env.DATABASE_URL;  // Could be undefined!

// AI MISTAKE: .env in production
require('dotenv').config();  // Not for production!
```

**Check for:**
- Scattered `process.env` access (should be centralized)
- Missing environment variable validation
- Using dotenv in production
- Default values hiding missing required config

### 9. Callback and Event Patterns (Medium)

```javascript
// AI MISTAKE: Callback + Promise mixing
function getData(callback) {
  return new Promise((resolve) => {
    const data = fetchData();
    callback(data);    // Also calling callback!
    resolve(data);     // AND resolving promise!
  });
}

// AI MISTAKE: EventEmitter without error handler
const emitter = new EventEmitter();
emitter.emit('data', payload);
// No 'error' event handler - unhandled errors crash process!
```

**Check for:**
- Mixing callbacks and promises
- EventEmitters without `'error'` handlers
- Not using `{ captureRejections: true }` option
- Missing `removeListener` / `off` for cleanup

### 10. Testing Issues (Medium)

```javascript
// AI MISTAKE: Testing implementation details
expect(mockFn).toHaveBeenCalledTimes(3);  // Brittle!

// AI MISTAKE: No test isolation
let sharedState = [];
it('test 1', () => { sharedState.push('a'); });
it('test 2', () => { expect(sharedState).toHaveLength(0); });  // FAILS!

// AI MISTAKE: Testing async without await
it('should create user', () => {  // Missing async!
  expect(userService.createUser(data)).resolves.toBeDefined();  // Missing await!
});

// AI MISTAKE: Hardcoded test ports
const server = app.listen(3000);  // Port conflict in parallel tests!
```

**Check for:**
- Assertions on mock call counts (test implementation, not behavior)
- Shared mutable state between tests
- Missing `async`/`await` in test functions
- Hardcoded ports (use `listen(0)`)
- Missing cleanup in `afterEach`/`afterAll`
- Tests that depend on execution order

---

## Architecture Violations

### Business Logic in Controllers

```javascript
// VIOLATION: Logic in controller
create = async (req, res, next) => {
  if (!isValidEmail(req.body.email)) { }  // Should be in service or validation!
  const hash = await bcrypt.hash(req.body.password, 12);  // Should be in service!
};
```

### Direct Database Access in Controllers

```javascript
// VIOLATION: Controller queries DB directly
create = async (req, res, next) => {
  const user = await db.query('INSERT INTO users...');  // Should go through service+repo!
};
```

### Circular Dependencies

```javascript
// VIOLATION: A imports B, B imports A
// user.service.js
import { OrderService } from '../orders/order.service.js';
// order.service.js
import { UserService } from '../users/user.service.js';  // CIRCULAR!
```

---

## Output Format

### Spec Compliance Review

```yaml
review_type: spec_compliance
task_id: {task.id}
status: APPROVED|CHANGES_NEEDED

criteria_assessment:
  - criterion: "[criterion text]"
    status: met|partial|missing
    evidence: "[file:line or test name]"
    notes: "[if not fully met]"

under_building:
  found: true|false
  issues: [...]

over_building:
  found: true|false
  issues: [...]

verdict: APPROVED|CHANGES_NEEDED
changes_required:
  - priority: 1
    description: "[what to fix]"
```

### Code Quality Review

```yaml
review_type: code_quality
task_id: {task.id}
status: APPROVED|CHANGES_NEEDED

findings:
  critical:
    - issue: "[description]"
      location: "[file:line]"
      category: "[error_handling|security|async|resource_leak]"
      fix: "[how to fix]"
  major:
    - issue: "[description]"
      location: "[file:line]"
      fix: "[how to fix]"
  minor:
    - issue: "[description]"
      suggestion: "[improvement]"

ai_code_problems:
  - pattern: "[which AI mistake pattern]"
    location: "[file:line]"
    fix: "[correct approach]"

testing_issues:
  - anti_pattern: "[which anti-pattern]"
    location: "[test file:line]"
    fix: "[how to improve]"

security:
  issues_found: true|false
  details: [...]

error_handling:
  complete: true|false
  gaps: [...]

verdict: APPROVED|CHANGES_NEEDED
changes_required:
  - priority: 1
    description: "[what to fix]"
    location: "[file:line]"
```
