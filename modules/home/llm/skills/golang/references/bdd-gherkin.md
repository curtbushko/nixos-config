# BDD/Gherkin Specifications for Go Projects

Behavior-Driven Development (BDD) uses Gherkin syntax to write executable specifications that map directly to tests.

## Gherkin Syntax

### Feature File Structure

```gherkin
Feature: [Short descriptive name]
  As a [role/persona]
  I want [capability]
  So that [benefit]

  Background:
    Given [common precondition for all scenarios]

  Scenario: [Specific behavior being tested]
    Given [initial context/state]
    And [additional context]
    When [action taken]
    And [additional action]
    Then [expected outcome]
    And [additional outcome]

  Scenario: [Another behavior]
    Given [context]
    When [action]
    Then [outcome]

  # Optional: Notes section for implementation hints
  # Note: Token secret should come from config
```

### Keywords

| Keyword | Purpose | Example |
|---------|---------|---------|
| `Feature:` | High-level description | `Feature: User Registration` |
| `As a / I want / So that` | User story (optional) | `As a new user, I want to register` |
| `Background:` | Steps run before each scenario | `Given the database is empty` |
| `Scenario:` | Specific testable behavior | `Scenario: Valid email registration` |
| `Given` | Precondition/initial state | `Given I have a valid email` |
| `When` | Action being performed | `When I submit the form` |
| `Then` | Expected outcome | `Then my account is created` |
| `And` / `But` | Additional steps | `And I receive a confirmation` |

---

## Writing Effective Scenarios

### Good Scenarios Are:

1. **Independent**: Each scenario runs in isolation
2. **Declarative**: Describe WHAT, not HOW
3. **Business-focused**: Use the terminology of the feature
4. **Testable**: Clear pass/fail criteria

### Example: User Authentication

```gherkin
Feature: User Authentication
  As a registered user
  I want to authenticate with my credentials
  So that I can access protected resources

  Background:
    Given the authentication service is running
    And the rate limiter allows requests

  Scenario: Successful login with valid credentials
    Given a user exists with email "user@example.com"
    And the user has password "SecurePass123!"
    When I submit login with email "user@example.com" and password "SecurePass123!"
    Then I should receive an access token
    And the token should be valid for 24 hours
    And the response status should be 200

  Scenario: Login fails with wrong password
    Given a user exists with email "user@example.com"
    When I submit login with email "user@example.com" and password "WrongPassword"
    Then I should receive an error "invalid credentials"
    And the response status should be 401
    And no token should be issued

  Scenario: Login fails with non-existent user
    Given no user exists with email "ghost@example.com"
    When I submit login with email "ghost@example.com" and password "AnyPassword"
    Then I should receive an error "invalid credentials"
    And the response status should be 401

  Scenario: Account locked after failed attempts
    Given a user exists with email "user@example.com"
    And the user has 4 failed login attempts
    When I submit login with an incorrect password
    Then the account should be locked
    And I should receive an error "account locked"
    And the response status should be 423

  Scenario: Rate limiting prevents brute force
    Given the rate limiter has recorded 100 requests from IP "1.2.3.4"
    When I submit login from IP "1.2.3.4"
    Then I should receive an error "rate limit exceeded"
    And the response status should be 429
```

### Example: API CRUD Operations

```gherkin
Feature: Product Management API
  As a store administrator
  I want to manage products through an API
  So that I can maintain the product catalog

  Background:
    Given I am authenticated as an admin
    And the product database is empty

  Scenario: Create a new product
    When I POST to "/products" with:
      | name        | Widget Pro  |
      | price       | 29.99       |
      | sku         | WGT-001     |
      | stock       | 100         |
    Then the response status should be 201
    And the response should contain a product ID
    And the product should exist in the database

  Scenario: Create product fails with duplicate SKU
    Given a product exists with SKU "WGT-001"
    When I POST to "/products" with SKU "WGT-001"
    Then the response status should be 409
    And the error message should be "SKU already exists"

  Scenario: Retrieve a product by ID
    Given a product exists with ID "prod-123"
    When I GET "/products/prod-123"
    Then the response status should be 200
    And the response should contain the product details

  Scenario: Update product price
    Given a product exists with ID "prod-123" and price 29.99
    When I PATCH "/products/prod-123" with price 24.99
    Then the response status should be 200
    And the product price should be 24.99

  Scenario: Delete a product
    Given a product exists with ID "prod-123"
    When I DELETE "/products/prod-123"
    Then the response status should be 204
    And the product should not exist in the database

  Scenario: List products with pagination
    Given 50 products exist in the database
    When I GET "/products?page=2&limit=10"
    Then the response status should be 200
    And I should receive 10 products
    And the response should include pagination metadata
```

---

## Mapping Scenarios to Implementation Tasks

For each feature, identify affected packages, public behavior, and actual
prerequisites. Follow the project's approved design rather than requiring a fixed
set of layers.

For JWT authentication, reviewable tasks might cover:

1. Token validation behavior: valid tokens, expired tokens, invalid signatures,
   and malformed claims.
2. HTTP middleware behavior: attach the authenticated user to request context,
   return 401 for invalid tokens, and preserve documented health-endpoint access.

Each task includes affected files, independently verifiable acceptance criteria,
test scenarios, and its own TDD cycle. Add interfaces or separate packages only
when justified by actual consumers or testing needs. Record dependencies only
where one task genuinely requires another.

---

## Scenario Outlines (Parameterized Tests)

Use Scenario Outline for testing multiple inputs:

```gherkin
Feature: Email Validation

  Scenario Outline: Validate email format
    When I validate email "<email>"
    Then the result should be <valid>

    Examples:
      | email              | valid |
      | user@example.com   | true  |
      | admin@company.org  | true  |
      | invalid            | false |
      | @nodomain.com      | false |
      | user@              | false |
      | user@.com          | false |
```

Maps to Go table-driven test:

```go
func TestValidateEmail(t *testing.T) {
    tests := []struct {
        email string
        valid bool
    }{
        {"user@example.com", true},
        {"admin@company.org", true},
        {"invalid", false},
        {"@nodomain.com", false},
        {"user@", false},
        {"user@.com", false},
    }

    for _, tt := range tests {
        t.Run(tt.email, func(t *testing.T) {
            got := ValidateEmail(tt.email)
            if got != tt.valid {
                t.Errorf("ValidateEmail(%q) = %v, want %v", tt.email, got, tt.valid)
            }
        })
    }
}
```

---

## Best Practices

### DO:

- Use the terminology of the feature
- Keep scenarios focused on one behavior
- Write scenarios before implementation
- Include both happy path and error cases
- Add notes for implementation hints

### DON'T:

- Include technical implementation details
- Write overly long scenarios
- Mix multiple behaviors in one scenario
- Use vague outcomes like "it should work"
- Skip error scenarios

### Good vs Bad Scenarios

```gherkin
# BAD: Too technical, implementation-focused
Scenario: User creation
    Given I call POST /api/v1/users with JSON body
    When the database INSERT succeeds
    Then return HTTP 201 with user JSON

# GOOD: Business-focused, declarative
Scenario: New user registers successfully
    Given I have a valid email "new@example.com"
    And I have chosen password "SecurePass123"
    When I complete the registration
    Then my account should be created
    And I should receive a welcome email
```
