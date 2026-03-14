---
name: go-project-planning
description: Go project architecture planning with hexagonal architecture, BDD/Gherkin specifications, and TDD workflow. Use this skill when starting a new Go project, planning features, or reviewing architectural decisions.
---

# Go Project Planning Skill

This skill provides architectural patterns and planning guidance for Go projects. Use it when:
- Starting a new Go project
- Planning feature implementations
- Reviewing architectural decisions
- Writing BDD specifications

**NOTE**: This skill references the shared Go patterns in `~/.claude/skills/golang/references/`. All detailed patterns, code examples, and guidelines are maintained there as the single source of truth.

## Quick Reference

| Pattern | Reference |
|---------|-----------|
| Hexagonal Architecture | [golang/references/architecture.md](../golang/references/architecture.md) |
| BDD/Gherkin Specifications | [golang/references/bdd-gherkin.md](../golang/references/bdd-gherkin.md) |
| TDD Workflow | [golang/references/tdd-workflow.md](../golang/references/tdd-workflow.md) |
| Protobuf Guidelines | [golang/references/protobuf.md](../golang/references/protobuf.md) |
| Go Code Patterns | [golang/references/code-patterns.md](../golang/references/code-patterns.md) |
| Go Cloud SDK | [golang/references/go-cloud-sdk.md](../golang/references/go-cloud-sdk.md) |
| AI Code Problems | [golang/references/ai-code-problems.md](../golang/references/ai-code-problems.md) |

---

## Non-Negotiable Requirements

### CLI Framework
**All service CLI entry points MUST use Cobra and Viper:**
- [spf13/cobra](https://github.com/spf13/cobra) for command-line interface
- [spf13/viper](https://github.com/spf13/viper) for configuration management

### Testing Framework
**All tests MUST use [testify](https://github.com/stretchr/testify):**
- `require` for fatal assertions
- `assert` for non-fatal assertions
- **Exception**: Kubernetes e2e tests may use k8s e2e framework

### Architecture
**All Go projects MUST follow Hexagonal Architecture:**
- Dependencies flow INWARD: adapters -> application -> ports -> domain
- Domain layer has NO external dependencies
- See [architecture.md](../golang/references/architecture.md) for details

---

## Project Structure

```
project/
├── cmd/                          # Composition root
│   └── myapp/
│       ├── main.go               # Entry point
│       └── root.go               # Cobra root command
├── internal/
│   ├── domain/                   # INNER: Pure business logic
│   ├── ports/                    # INNER: Interface contracts
│   ├── application/              # APPLICATION: Use cases
│   └── adapters/                 # OUTER: Infrastructure
├── api/                          # API definitions (proto, OpenAPI)
├── .go-arch-lint.yml             # Architecture enforcement
├── .golangci.yml                 # Linting rules
├── Taskfile.yml                  # Build targets (required)
└── go.mod
```

---

## Planning Workflow

### 1. Define Features with BDD/Gherkin

Write specifications in Gherkin format. See [bdd-gherkin.md](../golang/references/bdd-gherkin.md).

```gherkin
Feature: User Registration
  As a new user
  I want to create an account
  So that I can access the platform

  Scenario: Successful registration with valid email
    Given I have a valid email "user@example.com"
    And I have a strong password "SecureP@ss123"
    When I submit the registration form
    Then my account should be created
    And I should receive a confirmation email
```

### 2. Identify Architectural Layers

For each feature, identify which layers need changes:

| Layer | Location | Changes |
|-------|----------|---------|
| Domain | `internal/domain/` | New entities, value objects, domain errors |
| Ports | `internal/ports/` | New interface definitions |
| Application | `internal/application/` | Use case implementations |
| Adapters | `internal/adapters/` | HTTP handlers, database repos |

### 3. Break Down into Tasks

Each task should be:
- **Focused**: Single layer, single concern
- **Testable**: Clear acceptance criteria
- **Small**: 2-5 minutes implementation time
- **Ordered**: Respect dependencies (domain first, adapters last)

### 4. Follow TDD for Implementation

See [tdd-workflow.md](../golang/references/tdd-workflow.md) for the complete workflow.

```
1. RED: Write failing test FIRST
2. GREEN: Write minimal code to pass
3. REFACTOR: Clean up while green
```

---

## Quality Gates (NON-NEGOTIABLE)

Before completing any task:

```bash
task build           # REQUIRED - must pass
task test            # REQUIRED - must pass
task lint            # REQUIRED - must pass
go-arch-lint check   # if .go-arch-lint.yml exists
```

**IMPORTANT**:
- Always use Taskfile targets
- NEVER modify linting configuration files
- Fix the code, not the rules

---

## Protobuf Requirements

Every protobuf message MUST include `trace_id`. See [protobuf.md](../golang/references/protobuf.md).

```protobuf
message CreateUserRequest {
    string trace_id = 1;  // REQUIRED - Always field number 1
    string email = 2;
    string name = 3;
}
```

---

## Go Cloud SDK (Portable Components)

Follow [Go Cloud SDK](https://gocloud.dev/) patterns for cloud-agnostic components. See [go-cloud-sdk.md](../golang/references/go-cloud-sdk.md).

```go
// URL-based construction - provider determined by configuration
bucket, _ := blob.OpenBucket(ctx, os.Getenv("BUCKET_URL"))
// "s3://my-bucket"      -> AWS S3
// "gs://my-bucket"      -> Google Cloud Storage
// "file:///tmp/bucket"  -> Local filesystem
```
