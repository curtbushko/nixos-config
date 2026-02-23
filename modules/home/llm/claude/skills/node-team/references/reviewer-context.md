# Node Reviewer Context

The reviewer performs BOTH spec compliance AND code quality review in a single pass.

---

## Review Procedure

1. **Read task acceptance criteria** from `.tasks/task-{id}.yaml`
2. **Read build results** from `.tasks/result-{id}-build.yaml`
3. **Stage 1: Spec Compliance** - Check requirements, under/over-building
4. **Stage 2: Code Quality** - Only if Stage 1 passes. Check patterns below.
5. **Write results** to `.tasks/result-{id}-review.yaml`
6. **Return only verdict** to orchestrator (2 lines max)

### Spec Compliance Checks
- Each acceptance criterion fully implemented and tested?
- Under-building: missing or partial implementations? TODOs?
- Over-building: code beyond spec? Extra features? Premature optimization?
- Test coverage: each requirement has tests? Edge cases? Error paths?

---

## Lint Verification

Before approving, confirm lint passes:
```bash
make lint            # if Makefile exists
task lint            # if Taskfile exists (fallback if no Makefile)
```

---

## Review Priority Order

- **CRITICAL** (must fix): Unhandled promise rejections, security vulnerabilities, resource leaks, missing error handling in async
- **MAJOR** (should fix): Architecture violations, async/await anti-patterns, testing quality, input validation gaps
- **MINOR** (consider): Naming conventions, performance optimization, code organization

---

## Critical Issues (MUST CHECK)

### Error Handling
- **Empty catch**: `catch {}` or `catch (err) { console.log(err) }` - must handle or rethrow
- **Throwing strings**: `throw 'error'` - no stack trace! Use `new Error()`
- **Missing try/catch**: Async route handlers without error handling
- **Missing next(error)**: Express middleware not propagating errors

```javascript
// BAD: Swallowed, logged-only, string throw
try { await doWork(); } catch {}  // swallowed!
catch (err) { console.log(err); }  // logged but not handled!
throw 'something went wrong';      // no stack trace!
```

### Async/Await Pitfalls
- **Missing await**: `const user = userRepo.findById(id)` - returns Promise, not User
- **Sequential when parallel**: Two independent awaits should be `Promise.all()`
- **Await in loops**: `for (id of ids) { await getUser(id) }` - use `Promise.all(ids.map(...))`
- **Floating promises**: Async call without await or .catch()
- **Missing return await**: Loses stack trace context

```javascript
// BAD: Missing await, sequential when parallel, await in loop
const user = userRepo.findById(id);  // missing await!
const users = await getUsers();
const orders = await getOrders();    // should be Promise.all!
for (const id of ids) { await getUser(id); }  // N sequential queries!
```

### Security Vulnerabilities
- **SQL injection**: String concatenation in queries
- **XSS**: Unsanitized user input in HTML
- **Hardcoded secrets**: API keys, passwords in code
- **eval/Function**: With user input = RCE
- **Missing rate limiting**: On auth endpoints
- **Stack trace exposure**: In production error responses

```javascript
// BAD: SQL injection, XSS, hardcoded secret
const query = `SELECT * FROM users WHERE id = '${userId}'`;  // INJECTION!
res.send(`<h1>Hello ${req.query.name}</h1>`);                // XSS!
const JWT_SECRET = 'my-secret-key';                          // NEVER!
```

### Resource Leaks
- DB connections not released in `finally` blocks
- Streams without error handlers
- Event listeners not removed on cleanup
- `setInterval`/`setTimeout` not cleared
- HTTP responses not ended

```javascript
// BAD: Connection not released on error
const client = await pool.connect();
const result = await client.query('SELECT...');
// Missing: finally { client.release() }
```

### Unhandled Promise Rejections
- Async functions called without await or .catch()
- Missing 'error' event handlers on streams/emitters
- `Promise.all` without considering `Promise.allSettled`

---

## Major Issues

### Architecture Violations
- Business logic in controllers (validation, hashing should be in services)
- Controllers querying DB directly (should go through service+repo)
- Circular dependencies (A imports B, B imports A)

```javascript
// BAD: Logic in controller
create = async (req, res) => {
  if (!isValidEmail(req.body.email)) {}     // should be in service!
  const hash = await bcrypt.hash(pass, 12); // should be in service!
};
```

### Type Coercion Issues
- `==` instead of `===`
- Truthy/falsy checks on numbers (0 is falsy)
- `parseInt` without radix parameter

### Module Issues
- Side effects on import (code that runs when imported)
- Missing `.js` extensions in ESM imports
- Mixing `require()` and `import`

### Configuration Issues
- Scattered `process.env` access (should be centralized)
- Missing environment variable validation
- Using dotenv in production

---

## Testing Issues

- Testing mock call counts instead of actual behavior
- Shared mutable state between tests
- Missing `async`/`await` in test functions
- Hardcoded ports (`listen(3000)` - use `listen(0)`)
- Missing cleanup in `afterEach`/`afterAll`
- Tests depending on execution order

---

## Quick Reference

| Category | Check | Pattern |
|----------|-------|---------|
| Error | No empty catch | `catch (err) { /* handle */ }` |
| Error | Throw Error instances | `throw new Error()` not strings |
| Error | Async errors caught | try/catch in handlers, next(error) |
| Security | No SQL injection | Parameterized queries only |
| Security | No XSS | Sanitize user input |
| Security | No hardcoded secrets | Use env vars |
| Async | No missing await | All async calls awaited |
| Async | No floating promises | Every Promise handled |
| Async | Parallel when possible | `Promise.all()` |
| Async | No await in loops | Use `Promise.all(items.map())` |
| Resource | DB released | `finally { client.release() }` |
| Resource | Streams handled | `stream.on('error', handler)` |
| Resource | Timers cleared | clearInterval on shutdown |
| Arch | Logic in services | Not in controllers |
| Arch | No circular deps | One-way dependency flow |
| Test | Test isolation | No shared mutable state |
| Test | Async tests correct | async/await in test fns |
| Test | Random ports | `listen(0)` not hardcoded |

---

## Output Format

### File Output (write to `.tasks/result-{task.id}-review.yaml`)

```yaml
task_id: {task.id}

spec_compliance:
  criteria_assessment: [{criterion, status: met|partial|missing, evidence}]
  under_building: {found, issues}
  over_building: {found, issues}

code_quality:
  findings:
    critical: [{issue, location, category, fix}]
    major: [{issue, location, fix}]
    minor: [{issue, suggestion}]
  security: {issues_found, details}

verdict: APPROVED|CHANGES_NEEDED
changes_required: [{priority, description, location}]
```

### Return to Orchestrator (2 lines max)

Write full results to the file above. Return ONLY this to the orchestrator:
```
verdict: APPROVED|CHANGES_NEEDED
issues: [count of changes_required]
```
