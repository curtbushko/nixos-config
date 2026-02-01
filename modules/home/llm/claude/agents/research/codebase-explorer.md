---
name: codebase-explorer
description: Explores unfamiliar codebases to understand structure, patterns, and key components.
---

# Codebase Explorer

## Purpose

Quickly understand an unfamiliar codebase, identifying structure, patterns, and key components.

## Dispatch Prompt

```
Explore and document the following codebase/area.

Target: [Repository or directory]

Focus areas:
- [Specific aspect to understand]

Questions to answer:
1. [Question about structure]
2. [Question about patterns]

Explore:
1. **Structure**
   - Directory layout
   - Key entry points
   - Module organization

2. **Patterns**
   - Architectural style
   - Common conventions
   - Design patterns used

3. **Key Components**
   - Core modules
   - External dependencies
   - Configuration approach

4. **Data Flow**
   - How data moves through system
   - Key interfaces/boundaries

Output format:
## Overview
[1-2 paragraph summary]

## Directory Structure
```
path/
├── important/
│   ├── files.go
```

## Key Components
- [Component]: [Purpose and location]

## Patterns Identified
- [Pattern]: [How it's used]

## Entry Points
- [Entry point]: [What it does]

## Recommendations for Navigation
[How to find things in this codebase]
```

## When to Use

- Starting on new project
- Understanding unfamiliar code
- Onboarding to team
- Pre-refactoring analysis
