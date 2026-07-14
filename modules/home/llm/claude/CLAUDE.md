# Global Claude Code Instructions

## MANDATORY: Check Skills Before Coding

**CRITICAL**: Before writing ANY code, you MUST:

1. **List available skills**: Check `~/.claude/skills/` for relevant skills
2. **Read applicable skill files**: If skills exist for the language/framework being used, READ THEM COMPLETELY
3. **Follow skill guidelines**: All instructions in skill files are MANDATORY, not suggestions

### Skill Priority Order
1. Project-specific skills (e.g., project CLAUDE.md, local skills)
2. Language-specific skills (e.g., `golang/`, `node-team/`)
3. General development skills (e.g., `bash/`)

## TDD (Test-Driven Development) - MANDATORY

**You MUST follow TDD for ALL code changes. No exceptions.**

**If you write implementation code before writing a test, STOP and correct yourself.**

### The 6-Step TDD Workflow

For the complete workflow, see `~/.claude/skills/golang/references/tdd-workflow.md`. The summary:

1. **INVESTIGATE** - Understand requirements, review existing code
2. **PLAN** (features) / **REPRODUCE** (bugs) - Design API, identify test cases
3. **TEST (RED)** - Write failing tests FIRST, confirm they FAIL
4. **IMPLEMENT (GREEN)** - Write MINIMAL code to pass, confirm they PASS
5. **VALIDATE** - Run ALL tests, lint, check coverage
6. **REFACTOR** - Clean up while keeping tests green

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

## Repository Policy

**NEVER use git submodules in any code repository.**

Do not add, initialize, update, or depend on git submodules. If a dependency or external source is needed, use the language/package manager, flake inputs, vendoring, or another explicit non-submodule mechanism appropriate to the project.

## File Handling (CRITICAL)

**NEVER use `rm` to delete files.** Move files to `.trash/` instead:
```bash
mkdir -p .trash
grep -q "^\.trash/$" .gitignore 2>/dev/null || echo ".trash/" >> .gitignore
mv <file> .trash/
```

This applies to ALL files including:
- Task files (`.tasks/*.yaml`)
- Result files (`.tasks/result-*.yaml`)
- Status files (`.tasks/status.yaml`)
- Code files (`.go`, `.ts`, `.js`, `.zig`, etc.)
- Temporary files
- Generated files
- Any other files during cleanup

**NO EXCEPTIONS.** Never use `rm` for any file. Never create `.gitkeep` files.

## Code Style

- Follow language-specific conventions from skills
- Use Nerd Fonts icons instead of emojis for CLI output
- Keep functions small and focused
- Prefer explicit over implicit

## Git Commit Messages (CRITICAL)

**ALWAYS use conventional commits format.** Every commit message MUST have a type prefix:

- `feat`: new feature or capability
- `fix`: bug fix
- `chore`: maintenance, dependencies, config
- `refactor`: code restructuring without behavior change
- `docs`: documentation only
- `test`: adding or updating tests
- `ci`: CI/CD changes
- `perf`: performance improvement
- `style`: formatting, whitespace (no code change)

**Format**: `type(optional-scope): short description`

**ALWAYS use `git commit -F <file>` for commit messages.** Write the message to a temp file first, then pass it with `-F`. Single-quoting `-m` in zsh causes literal quote characters in the message; double quotes cause `unmatched "` errors.

```bash
# CORRECT - write message to temp file, commit with -F
echo 'feat(auth): add OAuth2 login flow' > /tmp/commit-msg.txt
git commit -F /tmp/commit-msg.txt

# WRONG - quotes end up in the commit message
git commit -m 'feat(auth): add OAuth2 login flow'
```

## Scripting Language Policy (CRITICAL)

**NEVER use Python for scripting tools or automation tasks.**

Instead, you MUST:
1. **Use bash/shell scripts** for all automation and scripting tasks
2. **Leverage CLI tools** (awk, sed, jq, curl, etc.) to accomplish what Python libraries would do
3. **Compose Unix tools** with pipes and process substitution

This applies to:
- Build scripts and automation
- Data processing and transformation
- File manipulation
- API interactions
- System administration tasks
- Any other scripting needs

**NO EXCEPTIONS.** If a task seems to require Python, find the appropriate CLI tool or bash solution instead.

## When Skills Conflict

If multiple skills apply and have conflicting guidance:
1. Project-specific skills take precedence
2. Language-specific skills come second
3. General skills are fallback

This is the SAME order as Skill Priority Order above - be consistent.

## Acknowledgment

When starting a new coding task, explicitly state:
"I will follow the [language] skill guidelines including [key requirements from the skill]"

This confirms you have read and understood the applicable skills.
