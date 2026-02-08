# Global Claude Code Instructions

## MANDATORY: Check Skills Before Coding

**CRITICAL**: Before writing ANY code, you MUST:

1. **List available skills**: Check `~/.claude/skills/` for relevant skills
2. **Read applicable skill files**: If skills exist for the language/framework being used, READ THEM COMPLETELY
3. **Follow skill guidelines**: All instructions in skill files are MANDATORY, not suggestions

### Skill Priority Order
1. Language-specific skills (e.g., `golang/`, `node-team/`)
2. Framework-specific skills
3. General development skills (e.g., `bash/`)

## TDD (Test-Driven Development) - MANDATORY

**You MUST follow TDD for ALL code changes. No exceptions.**

**If you write implementation code before writing a test, STOP and correct yourself.**

### The 6-Step TDD Workflow

**Use TodoWrite to track these steps for EVERY feature/bugfix:**

#### 1. INVESTIGATE
- Understand the requirement thoroughly
- Review existing code and related modules
- Identify dependencies and potential side effects
- Document acceptance criteria

#### 2. REPRODUCE (bugs) / PLAN (features)
- For bugs: Create a minimal reproduction case
- For features: Design the interface/API BEFORE implementation
- Identify edge cases and error scenarios
- Plan test scenarios

#### 3. TEST (RED)
- Write failing tests FIRST
- Structure tests using AAA pattern (Arrange, Act, Assert)
- Include positive and negative test cases
- Test edge cases and error handling
- **RUN TESTS - confirm they FAIL**

#### 4. FIX / IMPLEMENT (GREEN)
- Write MINIMAL code to pass the test
- Follow SOLID principles
- Keep functions small and focused
- **RUN TESTS - confirm they PASS**

#### 5. VALIDATE
- Run ALL tests to ensure no regressions
- Check code coverage
- Run linter
- Review error handling

#### 6. FINALIZE (REFACTOR)
- Refactor for clarity and maintainability
- Remove dead code and console.logs
- **RUN TESTS - ensure still green**

### TodoWrite Template

```
1. [ ] INVESTIGATE: Understand [feature/bug] requirements
2. [ ] PLAN: Design interface and identify test cases
3. [ ] TEST: Write failing test for [specific behavior]
4. [ ] RUN: Confirm test fails (RED)
5. [ ] IMPLEMENT: Write minimum code for [specific behavior]
6. [ ] RUN: Confirm test passes (GREEN)
7. [ ] VALIDATE: Run all tests, check coverage
8. [ ] REFACTOR: Clean up if needed
```

### Before Writing Code, Ask Yourself

- "What test would prove this works?"
- "How would I know if this breaks in the future?"
- "What are the edge cases I should test?"

## Project Startup Checklist

Before starting ANY implementation task:

- [ ] Listed skills in `~/.claude/skills/`
- [ ] Read ALL relevant skill files for the language/framework
- [ ] Identified testing requirements from skills
- [ ] Confirmed TDD approach will be followed
- [ ] Asked user about any project-specific requirements

**If you skip this checklist, you are violating your core responsibilities.**

## Quality Gates

Before considering any task complete:

1. **Tests pass**: All tests must pass (`npm test`, `go test`, etc.)
2. **Build succeeds**: Project must build without errors
3. **Lint clean**: No linting errors or warnings
4. **Coverage maintained**: Test coverage should not decrease

## Code Style

- Follow language-specific conventions from skills
- Use Nerd Fonts icons instead of emojis for CLI output
- Keep functions small and focused
- Prefer explicit over implicit

## When Skills Conflict

If multiple skills apply and have conflicting guidance:
1. Project-specific skills take precedence
2. Language-specific skills come second
3. General skills are fallback

## Acknowledgment

When starting a new coding task, explicitly state:
"I will follow the [language] skill guidelines including [key requirements from the skill]"

This confirms you have read and understood the applicable skills.
