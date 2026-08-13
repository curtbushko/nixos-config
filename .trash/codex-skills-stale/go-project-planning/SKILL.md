---
name: go-project-planning
description: Go Project Planning Skill
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
- NEVER modify linting configuration files (`.golangci.yml`, `.go-arch-lint.yml`, `.go-ai-lint.yml`)
- NEVER use `//nolint:` directives - there are no exceptions
- Fix the code, not the rules


## Go Cloud SDK (Portable Components)

Follow [Go Cloud SDK](https://gocloud.dev/) patterns for cloud-agnostic components. See [go-cloud-sdk.md](../golang/references/go-cloud-sdk.md).

```go
// URL-based construction - provider determined by configuration
bucket, _ := blob.OpenBucket(ctx, os.Getenv("BUCKET_URL"))
// "s3://my-bucket"      -> AWS S3
// "gs://my-bucket"      -> Google Cloud Storage
// "file:///tmp/bucket"  -> Local filesystem
```
