# Go Package Design

Follow the project's approved design and existing package organization. There is
no required layering scheme, directory layout, or architecture linter for Go
projects in this skill.

## Package Boundaries

- Keep packages focused on a coherent responsibility.
- Use `internal/` for implementation details that external projects should not import.
- Choose short, descriptive package names and avoid circular imports.
- Add packages when they clarify ownership or behavior, not to fill a template.
- Follow actual dependencies when ordering implementation work.

## Interfaces and Testing

- Define small interfaces at the consumer when substitution or testing needs them.
- Accept interfaces and usually return concrete types.
- Avoid creating an interface for every type or service by default.
- Test behavior with TDD and testify; use contract tests for dependency interfaces.
- Test infrastructure integrations against real dependencies where practical.

## Verification

Use the project's supported build/lint/test commands and environment. Taskfile,
Cobra/Viper and a particular test framework are not requirements. Honor checks
required by the project without imposing new architecture tooling or changing
existing lint rules to make failures disappear.
