# Go Team Examples

Concrete examples of using the Go Team skill with plan files.

## Example 1: JWT Authentication Middleware

### Step 1: Create PLAN.md

```markdown
# Feature: JWT Authentication

## Description

Add JWT authentication middleware for API endpoints. The middleware should
validate tokens, extract user claims, and attach user context to requests.
Should integrate with existing HTTP handler chain.

## Acceptance Criteria

- [ ] Validate JWT signature using configured secret
- [ ] Reject expired tokens with 401 response
- [ ] Reject malformed tokens with 401 response
- [ ] Extract user ID from token claims
- [ ] Attach user to request context
- [ ] Return JSON error body for unauthorized requests
- [ ] Skip auth for health check endpoints

## Notes

- Use existing `internal/core/domain/user.go` for User type
- Token secret should come from config, not hardcoded
- Consider using `github.com/golang-jwt/jwt/v5`
```

### Step 2: Invoke go-team

```bash
# Uses PLAN.md in current directory
/go-team
```

### Expected Task Manager Output

```yaml
feature: jwt-auth
description: Add JWT authentication middleware...
architecture_analysis:
  layers_affected:
    - layer: domain
      reason: Auth errors and token claims types
    - layer: ports
      reason: TokenValidator interface
    - layer: services
      reason: Auth service for validation logic
    - layer: adapters
      reason: HTTP middleware implementation

tasks:
  - id: 1
    name: "Define auth domain types"
    layer: domain
    files:
      create:
        - path: internal/core/domain/auth.go
          purpose: Auth-related types and errors
        - path: internal/core/domain/auth_test.go
          purpose: test file
    acceptance_criteria:
      - "Define TokenClaims type with UserID"
      - "Define ErrInvalidToken, ErrExpiredToken errors"
    dependencies: []

  - id: 2
    name: "Define TokenValidator port"
    layer: ports
    files:
      create:
        - path: internal/core/ports/auth.go
          purpose: TokenValidator interface
    acceptance_criteria:
      - "Define TokenValidator interface with Validate method"
    dependencies: [1]

  - id: 3
    name: "Implement auth service"
    layer: services
    files:
      create:
        - path: internal/core/services/auth.go
          purpose: Auth service implementation
        - path: internal/core/services/auth_test.go
          purpose: test file
    acceptance_criteria:
      - "validate JWT signature"
      - "reject expired tokens"
      - "reject malformed tokens"
      - "extract user ID from claims"
    dependencies: [1, 2]

  - id: 4
    name: "Implement HTTP auth middleware"
    layer: adapters
    files:
      create:
        - path: internal/adapters/handlers/http/middleware/auth.go
          purpose: HTTP middleware
        - path: internal/adapters/handlers/http/middleware/auth_test.go
          purpose: test file
    acceptance_criteria:
      - "attach user to request context"
      - "return 401 with error body for unauthorized"
      - "skip auth for health endpoints"
    dependencies: [3]

execution_order: [1, 2, 3, 4]
```

---

## Example 2: User Repository with Caching

### PLAN.md

```markdown
# Feature: Cached User Repository

## Description

Add Redis caching layer to the user repository. Cache user lookups by ID
with configurable TTL. Invalidate cache on updates.

## Acceptance Criteria

- [ ] Cache user by ID on successful read
- [ ] Return cached user if present (cache hit)
- [ ] Fetch from database on cache miss
- [ ] Invalidate cache when user is updated
- [ ] Support configurable cache TTL
- [ ] Graceful degradation if cache unavailable

## Notes

- Use decorator pattern to wrap existing UserRepository
- Don't modify existing repository implementation
- Cache key format: `user:{id}`
```

### Invocation

```bash
/go-team
```

---

## Example 3: Specific Plan File Location

### docs/features/password-reset.md

```markdown
# Feature: Password Reset

## Description

Implement password reset flow with secure token generation, email delivery,
and token validation.

## Acceptance Criteria

- [ ] Generate cryptographically secure reset token
- [ ] Store token with expiration (24 hours)
- [ ] Send reset email with token link
- [ ] Validate token on reset attempt
- [ ] Expire token after successful use
- [ ] Rate limit reset requests per email
```

### Invocation

```bash
/go-team plan="docs/features/password-reset.md"
```

---

## Example 4: Implement Specific Task

After the Task Manager has broken down the feature, you can implement a specific task:

```bash
# Implement only task 3 (e.g., after tasks 1-2 are done)
/go-team task=3
```

This skips the Task Manager phase and goes directly to Builder → Reviewer for the specified task.

---

## Example 5: Simple Health Endpoint

### PLAN.md

```markdown
# Feature: Health Endpoint

## Description

Add /health endpoint that returns service status and dependency checks.

## Acceptance Criteria

- [ ] Return 200 when all dependencies healthy
- [ ] Return 503 when any dependency unhealthy
- [ ] Include database connectivity check
- [ ] Include cache connectivity check
- [ ] Return JSON with component statuses
```

### Invocation and Flow

```bash
/go-team
```

Results in 3 tasks:
1. Define health types (domain)
2. Implement health service (services)
3. Implement health HTTP handler (adapters)

---

## Builder-Reviewer Cycle Example

### Builder Output

Builder writes full results to `.tasks/result-3-build.yaml` and returns to orchestrator:
```
status: complete
summary: Implemented health endpoint with HTTP codes and JSON body
```

### Reviewer Output

Reviewer reads `.tasks/result-3-build.yaml`, reviews source files, writes full
findings to `.tasks/result-3-review.yaml`, and returns to orchestrator:
```
verdict: CHANGES_NEEDED
issues: 1
```

### Builder Fix Cycle

Builder reads feedback from `.tasks/result-3-review.yaml`, fixes each issue,
writes results to `.tasks/result-3-fix-1.yaml`, and returns:
```
status: complete
fixes: 1
```

Reviewer runs again -> APPROVED -> Task complete.

### Key Point: File-Based Communication

All detailed results live in `.tasks/result-*.yaml` files. The orchestrator
only sees 2-line status summaries, preserving its context window for
coordinating across multiple tasks.
