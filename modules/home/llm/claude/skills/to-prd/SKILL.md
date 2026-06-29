---
name: to-prd
description: Use when the user wants to create a PRD from the current conversation context. Synthesizes conversation and codebase understanding into a Product Requirements Document saved as .phases/prd-{name}.md. Triggers include "create a PRD", "write a PRD", or "turn this into a PRD".
---

# To PRD - Conversation to Product Requirements Document

## Core Principle

Transform the current conversation context and codebase understanding into a comprehensive PRD without interviewing the user. Synthesize what is already known, explore the codebase to fill gaps, and produce a structured requirements document saved in `.phases/prd-{name}.md` for reference by planning and implementation phases.

## When to Use

Trigger this skill when:
- User says "create a PRD" or "write a PRD"
- User wants to turn the conversation into a formal document
- User says "turn this into a PRD"
- After a grill-me session when decisions are solidified
- When moving from exploration to formal planning phase

## Process

### Step 1: Explore the Codebase

**Before writing anything**, explore the repository to understand:

1. **Current state**
   - Read relevant existing code
   - Understand current architecture and patterns
   - Identify files/modules that will be affected

2. **Domain vocabulary**
   - Check for domain glossary or ubiquitous language documentation
   - Use project-specific terminology throughout the PRD
   - Respect naming conventions and abstractions

3. **Architectural Decision Records (ADRs)**
   - Look for ADRs in the area being touched
   - Respect existing architectural decisions
   - Note any new ADRs that may be needed

4. **Prior art**
   - Find similar features or patterns in the codebase
   - Identify testing approaches used for similar features
   - Learn from existing module structure

**Use the Task tool with subagent_type=Explore for this codebase exploration.**

### Step 2: Identify Modules

Sketch out the major modules you will need to **build or modify**.

**Deep Modules (Preferred):**
- Simple, stable interface that rarely changes
- Encapsulates complex functionality internally
- Easy to test in isolation
- High functionality-to-interface-complexity ratio

**Shallow Modules (Avoid):**
- Complex interface with little encapsulated functionality
- Leaks implementation details
- Hard to test without extensive mocking
- Interface changes frequently

**Actively look for opportunities to extract deep modules.**

Example:
```
Good (Deep):    cache.Get(key) → complex TTL, eviction, serialization hidden
Bad (Shallow):  cache.GetWithTTL(key, ttl, evictionPolicy, serializer) → leaks details
```

**Check with user:**
1. Present the list of modules to be built/modified
2. Confirm these match user expectations
3. Ask which modules need tests (use AskUserQuestion tool)

### Step 3: Write the PRD

Using the template below, write a comprehensive PRD that includes:

- Problem statement from user's perspective
- Solution from user's perspective
- Extensive list of user stories (numbered)
- Implementation decisions (modules, interfaces, technical choices)
- Testing decisions (what to test, how to test, prior art)
- Out of scope items
- Further notes

**CRITICAL: Do NOT include specific file paths or code snippets in the PRD.**
These become outdated quickly. Focus on concepts and modules.

### Step 4: Write PRD to .phases/ Directory

1. Create `.phases/` directory if it doesn't exist: `mkdir -p .phases`
2. Generate filename from feature name: `prd-{kebab-case-name}.md`
3. Write the PRD to `.phases/prd-{name}.md`
4. Return the file path to the user

**File naming examples:**
- "Add Authentication" → `.phases/prd-add-authentication.md`
- "API Caching Layer" → `.phases/prd-api-caching-layer.md`

## PRD Template

```markdown
# [Feature Name]

## Problem Statement

The problem that the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

A LONG, numbered list of user stories. Each user story should be in the format:

1. As an <actor>, I want a <feature>, so that <benefit>

Example:
1. As a mobile bank customer, I want to see balance on my accounts, so that I can make better informed decisions about my spending

This list should be extremely extensive and cover all aspects of the feature.

## Implementation Decisions

A list of implementation decisions that were made. This can include:

- The modules that will be built/modified
- The interfaces of those modules that will be modified
- Technical clarifications from the developer
- Architectural decisions
- Schema changes
- API contracts
- Specific interactions

Do NOT include specific file paths or code snippets. They may end up being outdated very quickly.

## Testing Decisions

A list of testing decisions that were made. Include:

- A description of what makes a good test (only test external behavior, not implementation details)
- Which modules will be tested
- Prior art for the tests (i.e. similar types of tests in the codebase)

## Out of Scope

A description of the things that are out of scope for this PRD.

## Further Notes

Any further notes about the feature.
```

## Anti-Patterns

- Interviewing the user (that's grill-me's job - synthesize what you know)
- Writing PRD without exploring the codebase first
- Ignoring domain vocabulary or ADRs
- Including specific file paths or code snippets
- Creating shallow modules when deep modules are possible
- Not checking module expectations with user
- Writing vague user stories ("As a user, I want it to work")
- Publishing to issue tracker instead of `.phases/` directory

## Integration with Other Skills

This skill fits into the workflow:

```
[Conversation/grill-me] → /to-prd → /to-phases → /go-team
     (Explore)           (Document)  (Structure)  (Execute)
```

**Before to-prd:**
- Use `grill-me` to validate approach through questioning
- Have substantive conversation about what to build

**After to-prd:**
- Use `to-phases` to break PRD into implementation phases
- Use `go-team`/`node-team`/`zig-team` to execute tasks

**File structure created:**
```
.phases/
└── prd-{feature-name}.md    # Created by to-prd
```

## Example Output

When complete, provide:

```
Created PRD: [Feature Name]

File: .phases/prd-{feature-name}.md

Next steps:
- Review the PRD for completeness
- Use /to-phases to break into implementation phases
- Use /[language]-team to execute

Modules identified:
1. [Module name] - [brief description] - [Deep/Shallow]
2. [Module name] - [brief description] - [Deep/Shallow]

Modules to test: [list based on user response]
```

## Notes

- This is a synthesis skill - use what you already know from conversation
- The PRD should be comprehensive but not prescriptive about implementation
- Focus on WHAT and WHY, not specific HOW (file paths, line numbers)
- Deep modules are testable, maintainable, and hide complexity
- The PRD becomes the source of truth for planning and implementation
