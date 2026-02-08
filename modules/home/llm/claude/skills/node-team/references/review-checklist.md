# Node Team Review Checklist Reference

Quick reference checklist for Node.js code review.

## Critical Issues (Must Fix)

### Error Handling
| Check | Pattern |
|-------|---------|
| No empty catch blocks | `catch (err) { /* handle */ }` |
| Errors not swallowed | Rethrow, return error response, or handle meaningfully |
| Throw Error instances | `throw new Error()` not `throw 'string'` |
| Async errors caught | `try/catch` in route handlers, `next(error)` in middleware |
| Promise rejections handled | No floating promises, unhandled rejection handler exists |

### Security
| Check | Pattern |
|-------|---------|
| No SQL injection | Parameterized queries, never string concat |
| No XSS | Sanitize user input in HTML responses |
| No hardcoded secrets | Use environment variables |
| Input validation | Zod schemas on all user input |
| Rate limiting | Auth endpoints have rate limits |
| Security headers | Using helmet |
| No eval/Function | Never use with user input |

### Async/Await
| Check | Pattern |
|-------|---------|
| No missing await | All async calls awaited or `.catch()`ed |
| No floating promises | Every Promise has handling |
| Return await preserved | `return await fn()` for stack traces |
| Parallel when possible | `Promise.all()` for independent operations |
| No await in loops | Use `Promise.all(items.map(...))` |

### Resource Management
| Check | Pattern |
|-------|---------|
| DB connections released | `finally { client.release() }` |
| Streams have error handlers | `stream.on('error', handler)` |
| Event listeners cleaned up | `removeListener` / `off` on cleanup |
| Timers cleared | `clearInterval` / `clearTimeout` on shutdown |
| Graceful shutdown | SIGTERM/SIGINT handlers close connections |

## Major Issues (Should Fix)

### Architecture
| Check | Pattern |
|-------|---------|
| Logic in correct layer | Business logic in services, not controllers |
| No direct DB in controllers | Go through service + repository |
| No circular dependencies | One-way dependency flow |
| Validation in middleware | Not scattered in business logic |

### Testing
| Check | Pattern |
|-------|---------|
| TDD followed | Test written before implementation |
| AAA pattern | Arrange, Act, Assert clearly separated |
| Test isolation | No shared mutable state between tests |
| Async tests correct | `async`/`await` in test functions |
| Random ports | `listen(0)` not hardcoded ports |
| Cleanup in afterEach | State reset between tests |

### Configuration
| Check | Pattern |
|-------|---------|
| Centralized config | Single config module with Zod validation |
| No scattered process.env | Access through config module |
| Required vars validated | Missing required config fails at startup |

## Minor Issues (Consider)

### Naming & Style
| Check | Convention |
|-------|------------|
| Variables/functions | `lowerCamelCase` |
| Classes | `UpperCamelCase` |
| Constants | `UPPER_SNAKE_CASE` |
| Files | `kebab-case` or `name.type.js` |
| Use const | Prefer `const`, then `let`, never `var` |
| Named functions | No anonymous function expressions |

### Performance
| Check | Pattern |
|-------|---------|
| Parallel async | `Promise.all` for independent ops |
| Stream large data | Don't load entire files into memory |
| Pagination | Limit query results |
| Connection pooling | Reuse DB connections |

### Modules
| Check | Pattern |
|-------|---------|
| ESM syntax | `import`/`export`, not `require` |
| `node:` prefix | `import { readFile } from 'node:fs/promises'` |
| `.js` extensions | Required in ESM imports |
| No side effects on import | Explicit initialization functions |

## Quick Decision Tree

```
Error found?
├── Is it a security vulnerability or unhandled async error?
│   └── CRITICAL - must fix before merge
├── Is it architecture violation or missing validation?
│   └── MAJOR - fix unless justified
├── Is it missing test or wrong pattern?
│   └── MAJOR - fix to prevent regression
└── Is it style or minor optimization?
    └── MINOR - suggest, don't block
```

## Review Output Templates

### Critical Finding
```yaml
- issue: "Unhandled promise rejection in route handler"
  location: "src/components/users/user.controller.js:23"
  category: "error_handling"
  severity: critical
  fix: "Wrap async handler in try/catch and call next(error)"
```

### Major Finding
```yaml
- issue: "Business logic in controller"
  location: "src/components/users/user.controller.js:15"
  severity: major
  fix: "Move email validation to user.service.js"
```

### Minor Finding
```yaml
- issue: "Using var instead of const"
  location: "src/utils/helpers.js:42"
  severity: minor
  suggestion: "Use const for variables that aren't reassigned"
```
