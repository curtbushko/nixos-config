# Node Team Examples

Concrete examples of using the Node Team skill with BDD-style plan files.

## Example 1: JWT Authentication Middleware

### Step 1: Create PLAN.md (BDD/Gherkin Format)

```gherkin
Feature: JWT Authentication
  As an API consumer
  I want requests to be authenticated via JWT
  So that only authorized users can access protected endpoints

  Background:
    Given the JWT secret is configured
    And the authentication middleware is enabled

  Scenario: Valid token grants access
    Given I have a valid JWT token for user "alice"
    When I make a request to a protected endpoint
    Then the request should succeed
    And the user context should contain user ID "alice"

  Scenario: Expired token is rejected
    Given I have an expired JWT token
    When I make a request to a protected endpoint
    Then I should receive a 401 Unauthorized response
    And the response body should contain error "token expired"

  Scenario: Malformed token is rejected
    Given I have a malformed JWT token "not-a-valid-jwt"
    When I make a request to a protected endpoint
    Then I should receive a 401 Unauthorized response
    And the response body should contain error "invalid token"

  Scenario: Missing token is rejected
    Given I make a request without an Authorization header
    When I access a protected endpoint
    Then I should receive a 401 Unauthorized response
    And the response body should contain error "missing token"

  Scenario: Health check bypasses authentication
    Given I make a request without an Authorization header
    When I access the "/health" endpoint
    Then the request should succeed

  # Note: Use existing user model from src/components/users/
  # Note: Token secret should come from config, not hardcoded
```

### Step 2: Invoke node-team

```bash
/node-team
```

### Expected Task Manager Output

```yaml
feature: jwt-auth
description: Add JWT authentication middleware...
architecture_analysis:
  components_affected:
    - component: middleware
      reason: Authentication middleware
    - component: errors
      reason: UnauthorizedError class
    - component: config
      reason: JWT secret configuration

tasks:
  - id: 1
    name: "Define auth error classes"
    component: errors
    files:
      create:
        - path: src/errors/unauthorized-error.js
          purpose: Auth-related error classes
        - path: src/errors/__tests__/unauthorized-error.test.js
          purpose: test file
    acceptance_criteria:
      - "Define UnauthorizedError extending AppError with 401 status"
    dependencies: []

  - id: 2
    name: "Add JWT config"
    component: config
    files:
      modify:
        - path: src/config/index.js
          changes: Add JWT_SECRET to config schema
    acceptance_criteria:
      - "JWT_SECRET is validated at startup"
    dependencies: []

  - id: 3
    name: "Implement auth middleware"
    component: middleware
    files:
      create:
        - path: src/middleware/auth.js
          purpose: JWT auth middleware
        - path: src/middleware/__tests__/auth.test.js
          purpose: test file
    acceptance_criteria:
      - "validate JWT signature"
      - "reject expired tokens with 401"
      - "reject malformed tokens with 401"
      - "reject missing tokens with 401"
      - "extract user ID from claims"
      - "attach user to request context"
      - "skip auth for health endpoints"
    dependencies: [1, 2]

execution_order: [1, 2, 3]
```

---

## Example 2: User Registration with Email

### PLAN.md

```gherkin
Feature: User Registration
  As a new user
  I want to create an account
  So that I can access the application

  Background:
    Given the application is running
    And the database is available

  Scenario: Successful registration
    Given I provide valid registration data
    When I POST to "/api/users" with email "alice@example.com" and password "secure123"
    Then I should receive a 201 Created response
    And the response should contain the user without the password
    And a welcome email should be queued

  Scenario: Duplicate email rejected
    Given a user with email "alice@example.com" already exists
    When I POST to "/api/users" with email "alice@example.com"
    Then I should receive a 409 Conflict response
    And the response should contain error "Email already registered"

  Scenario: Invalid email format rejected
    When I POST to "/api/users" with email "not-an-email"
    Then I should receive a 400 Bad Request response
    And the response should contain validation error for "email"

  Scenario: Password too short rejected
    When I POST to "/api/users" with password "short"
    Then I should receive a 400 Bad Request response
    And the response should contain validation error for "password"

  # Note: Hash passwords with bcrypt (cost factor 12)
  # Note: Use Zod for input validation
  # Note: Don't return password hash in response
```

### Invocation

```bash
/node-team
```

---

## Example 3: Specific Plan File Location

### docs/features/password-reset.md

```gherkin
Feature: Password Reset
  As a user who forgot their password
  I want to reset my password via email
  So that I can regain access to my account

  Background:
    Given the email service is configured
    And rate limiting is enabled

  Scenario: Request password reset
    Given user "alice@example.com" exists
    When I POST to "/api/auth/reset-request" with email "alice@example.com"
    Then I should receive a 200 OK response
    And a reset token should be generated with 24-hour expiry
    And a reset email should be sent to "alice@example.com"

  Scenario: Reset password with valid token
    Given I have a valid reset token for "alice@example.com"
    When I POST to "/api/auth/reset" with the token and new password "newSecure456"
    Then I should receive a 200 OK response
    And my password should be updated
    And the reset token should be invalidated

  Scenario: Reset with expired token rejected
    Given I have an expired reset token
    When I POST to "/api/auth/reset" with the token
    Then I should receive a 400 Bad Request response
    And the response should contain error "Token expired"

  Scenario: Rate limit reset requests
    Given I have requested a reset 5 times in the last hour
    When I request another reset
    Then I should receive a 429 Too Many Requests response

  # Note: Use crypto.randomBytes for token generation
  # Note: Store token hash, not plaintext
```

### Invocation

```bash
/node-team plan="docs/features/password-reset.md"
```

---

## Example 4: Implement Specific Task

After the Task Manager has broken down the feature, you can implement a specific task:

```bash
# Implement only task 3 (e.g., after tasks 1-2 are done)
/node-team task=3
```

This skips the Task Manager phase and goes directly to Builder -> Reviewer for the specified task.

---

## Example 5: Simple Health Endpoint

### PLAN.md

```gherkin
Feature: Health Check Endpoint
  As an operations engineer
  I want a health check endpoint
  So that I can monitor service availability

  Background:
    Given the application is running

  Scenario: All dependencies healthy
    Given the database connection is active
    And the cache connection is active
    When I GET "/health"
    Then I should receive a 200 OK response
    And the response should contain status "healthy"
    And the response should list component statuses

  Scenario: Database unhealthy
    Given the database connection is down
    When I GET "/health"
    Then I should receive a 503 Service Unavailable response
    And the response should contain status "unhealthy"
    And the database component should show "down"

  Scenario: Graceful degradation
    Given the cache connection is down
    But the database connection is active
    When I GET "/health"
    Then I should receive a 200 OK response
    And the response should contain status "degraded"
```

### Invocation and Flow

```bash
/node-team
```

Results in 3 tasks:
1. Define health check types and response format
2. Implement health service with dependency checks
3. Implement health HTTP route

---

## Builder-Reviewer Cycle Example

### Builder Output

Builder writes full results to `.tasks/result-3-build.yaml` and returns to orchestrator:
```
status: complete
summary: Implemented JWT auth middleware with token validation and health bypass
```

### Reviewer Output

Reviewer reads `.tasks/result-3-build.yaml`, reviews source files, writes full
findings to `.tasks/result-3-review.yaml`, and returns to orchestrator:
```
verdict: CHANGES_NEEDED
issues: 2
```

### Builder Fix Cycle

Builder reads feedback from `.tasks/result-3-review.yaml`, fixes each issue,
writes results to `.tasks/result-3-fix-1.yaml`, and returns:
```
status: complete
fixes: 2
```

Reviewer runs again -> APPROVED -> Task complete.

### Key Point: File-Based Communication

All detailed results live in `.tasks/result-*.yaml` files. The orchestrator
only sees 2-line status summaries, preserving its context window for
coordinating across multiple tasks.

---

## Example Test Output

When running `/node-team`:

```
Reading PLAN.md...

Task Manager: Breaking down feature into tasks...
  Found 3 tasks in execution order: [1, 2, 3]

Task 1: Define auth error classes
  [Builder] Writing failing test...
  [Builder] Implementing...
  [Builder] npm test: PASS
  [Reviewer/Spec] APPROVED
  [Reviewer/Quality] APPROVED
  Task 1 complete.

Task 2: Add JWT config
  [Builder] Writing failing test...
  [Builder] Implementing...
  [Builder] npm test: PASS
  [Reviewer/Spec] APPROVED
  [Reviewer/Quality] APPROVED
  Task 2 complete.

Task 3: Implement auth middleware
  [Builder] Writing failing test...
  [Builder] Implementing...
  [Builder] npm test: PASS
  [Reviewer/Spec] APPROVED
  [Reviewer/Quality] CHANGES_NEEDED (1 critical, 1 major)
  [Builder] Fixing issues...
  [Builder] npm test: PASS
  [Reviewer/Quality] APPROVED
  Task 3 complete.

## Node Team Complete: jwt-auth

### Summary
- Tasks completed: 3
- Files created: 5
- Tests added: 8

### Validation
- Test: pass
- Lint: pass

### Commits
- a1b2c3d: feat(auth): define UnauthorizedError class
- b2c3d4e: feat(config): add JWT_SECRET to config schema
- c3d4e5f: feat(auth): add JWT authentication middleware
- e4f5g6h: fix(auth): use config module and sanitize error responses
```
