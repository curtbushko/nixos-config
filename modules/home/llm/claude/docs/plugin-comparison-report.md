# Claude Code Configuration Comparison Report

**Generated:** 2025-02-01
**Compared Plugins:** compound-engineering-plugin, superpowers
**Reference Locations:** `/home/curtbushko/workspace/github.com/curtbushko/tmp/`

## Executive Summary

This report compares three Claude Code configurations:
1. **compound-engineering-plugin** - A marketplace-style plugin system focused on "compounding engineering" philosophy
2. **superpowers** - A TDD-focused workflow system with systematic debugging and subagent patterns
3. **Your current setup** - A language-specific skills system with quality gates and TDD enforcement

### Quick Stats

| Metric | compound-engineering | superpowers | Your Setup |
|--------|---------------------|-------------|------------|
| Skills | 15 | 14 | 11 |
| Agents | 28 | 1 | 0 |
| Commands | 24 | 3 | 3 |
| Hooks | 0 | 1 (session-start) | 1 (post-edit) |
| MCP Integration | Yes (Context7) | No | No |
| Multi-platform | No | Yes (Codex, OpenCode) | No |

---

## 1. Philosophy & Approach

### compound-engineering-plugin
**Core Philosophy:** "Each engineering work should make subsequent work easier"

- Marketplace model for distributing plugins
- Heavy emphasis on **agents** for automation (28 agents!)
- Ruby/Rails focus with DHH-style conventions
- Agent-native architecture patterns
- Strong documentation requirements (YAML frontmatter, proper links)

### superpowers
**Core Philosophy:** "Discipline through enforced workflows"

- Skills-based injection system (hooks inject guidance on session start)
- TDD as non-negotiable requirement
- Systematic debugging (investigate before fixing)
- Subagent-driven development with staged reviews
- Extensive anti-patterns documentation (45k+ lines on testing anti-patterns)

### Your Current Setup
**Core Philosophy:** "Quality gates and language-specific best practices"

- Home-manager deployed configuration (Nix-native)
- TDD workflow enforcement
- Language-specific skills (Go, Node, Nix, Bash, Godot)
- Post-edit validation hooks
- No-emoji rule (Nerd Fonts only)

---

## 2. Skills Comparison

### Unique to compound-engineering (not in your setup)
| Skill | Description | Potential Value |
|-------|-------------|-----------------|
| agent-browser | Browser automation and testing | High - missing automation capability |
| agent-native-architecture | Agent design patterns | High - foundational for building agents |
| brainstorming | Collaborative ideation methodology | Medium - structured thinking |
| compound-docs | Documentation as compounds | Low - specific to their system |
| create-agent-skills | How to create skills/agents | High - meta-skill for extending Claude |
| dhh-rails-style | Rails conventions | Low - unless you do Rails |
| dspy-ruby | DSPy integration | Low - Ruby-specific |
| every-style-editor | Content style guide | Low - company-specific |
| file-todos | Todo management | Low - you use TodoWrite |
| frontend-design | Frontend patterns | Medium - if doing frontend |
| gemini-imagegen | AI image generation | Medium - creative tasks |
| git-worktree | Worktree management | Medium - parallel development |
| rclone | File sync | Low - utility |
| skill-creator | Skill automation | High - automation |

### Unique to superpowers (not in your setup)
| Skill | Description | Potential Value |
|-------|-------------|-----------------|
| dispatching-parallel-agents | Parallel agent orchestration | High - missing capability |
| executing-plans | Plan execution patterns | Medium - you have TDD workflow |
| finishing-a-development-branch | Branch finalization | Medium - git workflow |
| receiving-code-review | Handle review feedback | High - collaboration |
| requesting-code-review | Request reviews | High - collaboration |
| subagent-driven-development | Staged subagent reviews | High - advanced pattern |
| systematic-debugging | Root cause investigation | High - debugging methodology |
| using-git-worktrees | Isolated workspaces | Medium - parallel development |
| verification-before-completion | Final validation | Medium - quality assurance |
| writing-plans | Plan creation | Medium - planning methodology |
| writing-skills | Skill authorship | High - meta-skill |

### Common Themes Across All Three
- **TDD/Testing** - All emphasize test-driven development
- **Brainstorming/Planning** - All have some form of planning skill
- **Git Workflows** - All include git-related guidance

### Your Unique Skills
| Skill | Not Found Elsewhere |
|-------|---------------------|
| nix | Nix/NixOS configuration - unique to your setup |
| godot | GDScript game development |
| godot-csharp | C# game development with BDD |
| minecraft-mods | Minecraft modding |
| go-code-review | Go-specific review patterns |

---

## 3. Agents Comparison

### compound-engineering Agents (28 total)

**Review Agents (14):**
- code-quality-reviewer
- security-reviewer
- performance-reviewer
- accessibility-reviewer
- test-coverage-reviewer
- documentation-reviewer
- architecture-reviewer
- dependency-reviewer
- api-design-reviewer
- error-handling-reviewer
- logging-reviewer
- configuration-reviewer
- database-reviewer
- frontend-reviewer

**Research Agents (4):**
- documentation-researcher
- framework-analyzer
- git-history-researcher
- codebase-explorer

**Design Agents (3):**
- ui-implementation
- ux-reviewer
- design-sync

**Workflow Agents (5):**
- bug-validator
- linter
- pr-resolver
- changelog-generator
- release-manager

**Docs Agents (1):**
- readme-generator

### superpowers Agents (1)
- **code-reviewer** - Senior code reviewer for plan alignment and quality

### Your Agents (0)
**Gap Identified:** No agent definitions

### Analysis
The lack of agents is the biggest gap in your setup. Agents automate repetitive tasks and provide specialized review capabilities. The compound-engineering approach of having 14 specialized review agents is particularly powerful for code quality.

---

## 4. Commands Comparison

### compound-engineering Commands (24)
**Workflow Commands:**
- workflows:plan
- workflows:review
- workflows:work
- workflows:compound
- workflows:brainstorm

**Utility Commands:**
- changelog
- generate_command
- heal-skill
- report-bug
- reproduce-bug
- ... and 14 more

### superpowers Commands (3)
- brainstorm
- write-plan
- execute-plan

### Your Commands (3)
- pr-review
- cleanup-code
- docs-review

### Analysis
Your commands focus on review/cleanup. Missing:
- **Planning commands** (write-plan, execute-plan)
- **Brainstorming** (structured ideation)
- **Workflow orchestration** (compound workflows)

---

## 5. Hooks Comparison

### compound-engineering Hooks
None defined in the plugin itself.

### superpowers Hooks
**session-start.sh** - Triggers on: startup, resume, clear, compact
- Injects "using-superpowers" skill content into every session
- Warns about legacy configurations
- Ensures skills guidance is always available

### Your Hooks
**post-edit-check.sh** - PostToolUse trigger
- Validates bash scripts for convention compliance
- Detects emoji usage in code files
- File extension-based validation

### Analysis
The superpowers approach of injecting context on session start is powerful. Your post-edit validation is good for enforcement but doesn't provide proactive guidance.

**Recommendation:** Add a session-start hook that reminds about TDD workflow and available skills.

---

## 6. Gap Analysis: What You're Missing

### High Priority Gaps

1. **No Agents**
   - Missing automated review capabilities
   - No specialized task executors
   - No research/exploration agents
   - **Impact:** Manual work that could be automated

2. **No Session-Start Hook**
   - Skills aren't automatically surfaced
   - No proactive guidance injection
   - **Impact:** May forget to use skills

3. **No Systematic Debugging Skill**
   - superpowers has 7 supporting files for debugging methodology
   - Root cause tracing, condition-based waiting, test pressure examples
   - **Impact:** May fix symptoms instead of causes

4. **No Parallel Agent Orchestration**
   - superpowers has dispatching-parallel-agents skill
   - **Impact:** Limited scalability for complex tasks

5. **No Code Review Collaboration Skills**
   - Missing receiving-code-review and requesting-code-review
   - **Impact:** Collaboration patterns not codified

### Medium Priority Gaps

6. **No Testing Anti-Patterns Documentation**
   - superpowers has 45k+ lines of testing anti-patterns
   - **Impact:** May repeat common testing mistakes

7. **No Git Worktree Skill**
   - Both other plugins have this
   - **Impact:** Limited parallel development capability

8. **No Plan Execution Workflow**
   - superpowers separates planning from execution
   - **Impact:** Planning and execution mixed

9. **No Skill Creation Meta-Skill**
   - Both other plugins document how to create skills
   - **Impact:** Harder to extend your system

10. **No MCP Integration**
    - compound-engineering uses Context7 MCP server
    - **Impact:** Missing enhanced code understanding

### Low Priority / Optional

11. Frontend design patterns (if not doing frontend)
12. Browser automation (unless needed)
13. AI image generation (creative tasks)
14. Rails-specific patterns (unless doing Ruby)

---

## 7. Strengths of Your Current Setup

1. **Nix Integration** - Deployed via home-manager, reproducible
2. **Language Diversity** - Go, Node, Nix, Bash, Godot, Minecraft
3. **Quality Gates** - Build, test, lint enforcement
4. **No-Emoji Rule** - Consistent Nerd Fonts usage
5. **Post-Edit Validation** - Catches issues in real-time
6. **Hexagonal Architecture** - Go skill enforces clean architecture
7. **BDD Support** - godot-csharp has Gherkin/Reqnroll

---

## 8. Recommendations

### Immediate Wins (Low Effort, High Impact)

1. **Add Session-Start Hook**
   ```bash
   # Inject skill awareness on every session
   # Remind about TDD workflow
   # Surface available skills
   ```

2. **Add Systematic Debugging Skill**
   - Adapt superpowers' methodology
   - Include root cause tracing
   - Add condition-based waiting patterns

3. **Add Code Review Collaboration Skills**
   - requesting-code-review
   - receiving-code-review

### Medium-Term Improvements

4. **Create Basic Review Agents**
   - Start with: code-quality-reviewer, security-reviewer
   - Add language-specific: go-reviewer, nix-reviewer

5. **Add Plan Execution Workflow**
   - Separate planning from implementation
   - Add write-plan and execute-plan commands

6. **Port Testing Anti-Patterns**
   - Extract relevant patterns from superpowers
   - Adapt to your languages (Go, Node, GDScript)

### Long-Term Enhancements

7. **Build Agent Library**
   - Research agents for codebase exploration
   - Workflow agents for automation
   - Consider MCP integration

8. **Add Parallel Agent Orchestration**
   - Enable complex multi-agent workflows
   - Subagent-driven development patterns

---

## 9. Feature Adoption Matrix

| Feature | Source | Effort | Value | Priority |
|---------|--------|--------|-------|----------|
| Session-start hook | superpowers | Low | High | P0 |
| Systematic debugging | superpowers | Low | High | P0 |
| Code review skills | superpowers | Low | Medium | P1 |
| Basic review agents | compound | Medium | High | P1 |
| Testing anti-patterns | superpowers | Medium | Medium | P2 |
| Git worktree skill | Both | Low | Medium | P2 |
| Plan execution workflow | superpowers | Medium | Medium | P2 |
| Skill creation guide | Both | Low | Medium | P2 |
| Parallel agents | superpowers | High | Medium | P3 |
| MCP integration | compound | High | Medium | P3 |
| Full agent library | compound | High | High | P3 |

---

## 10. Conclusion

Your current setup has strong foundations with language-specific skills, TDD enforcement, and quality gates. The main gaps are:

1. **Agents** - The biggest missing piece
2. **Session-start guidance** - Proactive skill surfacing
3. **Debugging methodology** - Systematic approach
4. **Collaboration patterns** - Code review workflows

The superpowers plugin offers better workflow patterns and debugging methodology. The compound-engineering plugin offers a richer agent ecosystem and automation capabilities.

A hybrid approach taking:
- **From superpowers:** Session hooks, debugging skill, code review collaboration, testing anti-patterns
- **From compound:** Review agents, workflow automation, skill creation patterns

...would significantly enhance your current setup while maintaining its Nix-native, language-diverse character.

---

## 11. Implementation Decisions

**Decision Date:** 2025-02-01

The following decisions were made for each feature category:

### Hooks

| Feature | Source | Decision | Notes |
|---------|--------|----------|-------|
| Session-start hook | superpowers | **ADD** | Create new hook to surface skills and TDD workflow on session startup |

### Agents

| Feature | Source | Decision | Notes |
|---------|--------|----------|-------|
| Review Agents (14) | compound | **ADD ALL** | Customize for existing patterns: TDD enforcement, hexagonal architecture |
| Research Agents (4) | compound | **ADD ALL** | documentation-researcher, framework-analyzer, git-history-researcher, codebase-explorer |
| Workflow Agents (5) | compound | **ADD ALL** | bug-validator, linter, pr-resolver, changelog-generator, release-manager |
| Design Agents (3) | compound | **ADD ALL** | ui-implementation, ux-reviewer, design-sync |
| Docs Agents (1) | compound | **ADD ALL** | readme-generator |
| Code Reviewer | superpowers | **MERGE** | Merge approach with compound review agents |

**Agent Customization Requirements:**
- code-quality-reviewer: Must enforce TDD workflow
- architecture-reviewer: Must enforce hexagonal architecture patterns
- All agents should align with existing quality gates

### Skills

| Feature | Source | Decision | Notes |
|---------|--------|----------|-------|
| Systematic Debugging | superpowers | **ADD (Simplified)** | Focus on root cause tracing methodology |
| Code Review Collaboration | superpowers | **SKIP** | - |
| Subagent-Driven Development | superpowers | **ADD** | Full skill with implementer/reviewer prompts |
| Git Worktree | Both | **SKIP** | - |
| Testing Anti-Patterns | superpowers | **EXTRACT** | Extract patterns for Go, Node, and Zig specifically |
| Brainstorming | Both | **SKIP** | - |
| Skill/Agent Creation | Both | **ADD** | Meta-skills for extending the system |
| Writing Plans | superpowers | **ADD** | Plan creation methodology |
| Executing Plans | superpowers | **ADD** | Plan execution workflow |

### Commands

| Feature | Source | Decision | Notes |
|---------|--------|----------|-------|
| /write-plan | superpowers | **ADD** | Planning command |
| /execute-plan | superpowers | **ADD** | Execution command |
| /changelog | compound | **ADD** | Changelog generator only |
| /report-bug | compound | **SKIP** | - |
| /reproduce-bug | compound | **SKIP** | - |

### Integrations

| Feature | Source | Decision | Notes |
|---------|--------|----------|-------|
| MCP (Context7) | compound | **SKIP** | - |

---

## 12. Implementation Checklist

**Implementation Date:** 2025-02-01
**Status:** COMPLETE

### Phase 1: Hooks
- [x] Create `session-start.sh` hook
- [x] Configure hook to trigger on: startup, resume, clear, compact
- [x] Inject available skills list
- [x] Remind about TDD workflow
- [x] Update `claude.nix` configuration (hooks defined in Nix, not JSON)

### Phase 2: Skills (New)
- [x] Create `systematic-debugging/SKILL.md` (simplified version)
- [x] Create `subagent-driven-development/SKILL.md` with supporting prompts
- [x] Create `skill-creation/SKILL.md` meta-skill
- [x] Create `agent-creation/SKILL.md` meta-skill
- [x] Create `writing-plans/SKILL.md`
- [x] Create `executing-plans/SKILL.md`
- [x] Extract testing anti-patterns for Go, Node, Zig into `testing-anti-patterns/`

### Phase 3: Agents (New Directory)
- [x] Create `agents/` directory structure
- [x] Create `agents/review/` with 14 review agents (customized)
  - [x] code-quality-reviewer.md (TDD-focused)
  - [x] security-reviewer.md
  - [x] performance-reviewer.md
  - [x] accessibility-reviewer.md
  - [x] test-coverage-reviewer.md
  - [x] documentation-reviewer.md
  - [x] architecture-reviewer.md (hexagonal-focused)
  - [x] dependency-reviewer.md
  - [x] api-design-reviewer.md
  - [x] error-handling-reviewer.md
  - [x] logging-reviewer.md
  - [x] configuration-reviewer.md
  - [x] database-reviewer.md
  - [x] frontend-reviewer.md
- [x] Create `agents/research/` with 4 research agents
  - [x] documentation-researcher.md
  - [x] framework-analyzer.md
  - [x] git-history-researcher.md
  - [x] codebase-explorer.md
- [x] Create `agents/workflow/` with 5 workflow agents
  - [x] bug-validator.md
  - [x] linter.md
  - [x] pr-resolver.md
  - [x] changelog-generator.md
  - [x] release-manager.md
- [x] Create `agents/design/` with 3 design agents
  - [x] ui-implementation.md
  - [x] ux-reviewer.md
  - [x] design-sync.md
- [x] Create `agents/docs/` with 1 docs agent
  - [x] readme-generator.md

### Phase 4: Commands (New)
- [x] Create `commands/write-plan.md`
- [x] Create `commands/execute-plan.md`
- [x] Create `commands/changelog.md`

### Phase 5: Validation
- [ ] Test session-start hook functionality (requires `home-manager switch`)
- [ ] Verify all skills are discoverable
- [ ] Test each agent individually
- [ ] Verify commands work correctly

---

## 13. Implementation Summary

**Completed:** 2025-02-01

### Files Created

| Category | Count | Location |
|----------|-------|----------|
| Skills | 7 new | `modules/home/llm/claude/skills/` |
| Agents | 27 new | `modules/home/llm/claude/agents/` |
| Commands | 3 new | `modules/home/llm/claude/commands/` |
| Scripts | 1 new | `modules/home/llm/claude/scripts/session-start.sh` |

### New Skills
1. `systematic-debugging` - Root cause investigation methodology
2. `subagent-driven-development` - Two-stage review pattern
3. `skill-creation` - Meta-skill for creating new skills
4. `agent-creation` - Meta-skill for creating new agents
5. `writing-plans` - Comprehensive planning methodology
6. `executing-plans` - Batch execution with checkpoints
7. `testing-anti-patterns` - Go, Node, Zig testing anti-patterns

### New Agents by Category
- **Review (14):** code-quality, security, performance, accessibility, test-coverage, documentation, architecture, dependency, api-design, error-handling, logging, configuration, database, frontend
- **Research (4):** documentation-researcher, framework-analyzer, git-history-researcher, codebase-explorer
- **Workflow (5):** bug-validator, linter, pr-resolver, changelog-generator, release-manager
- **Design (3):** ui-implementation, ux-reviewer, design-sync
- **Docs (1):** readme-generator

### New Commands
1. `/write-plan` - Create implementation plans
2. `/execute-plan` - Execute plans with batch processing
3. `/changelog` - Generate changelog entries

### Configuration Changes
- Updated `claude.nix` to add session-start hook
- Updated `claude.nix` to deploy agents directory

### Final Counts

| Category | Before | After | Change |
|----------|--------|-------|--------|
| Skills | 12 | 19 | +7 |
| Agents | 0 | 27 | +27 |
| Commands | 3 | 6 | +3 |
| Hooks | 1 | 2 | +1 |

### Next Steps

To activate these changes:
```bash
# Rebuild home-manager configuration
home-manager switch

# Or if using NixOS
sudo nixos-rebuild switch
```

After switching, verify by:
1. Starting a new Claude Code session (session-start hook should fire)
2. Running `/write-plan test-feature` to test the command
3. Checking `~/.claude/skills/` to see all skills
4. Checking `~/.claude/agents/` to see all agents
