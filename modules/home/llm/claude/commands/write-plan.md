---
description: Create a comprehensive implementation plan for a feature or task
---

Create a detailed implementation plan for: $1

**Use the writing-plans skill from ~/.claude/skills/writing-plans/SKILL.md**

**Plan requirements:**

1. **Location**: Save plan to `docs/plans/YYYY-MM-DD-<feature-name>.md`

2. **Structure each task with:**
   - Exact file paths (create/modify/test)
   - Complete code (not pseudocode)
   - Exact commands with expected output
   - 2-5 minute granularity

3. **Follow TDD for each task:**
   - Step 1: Write the failing test
   - Step 2: Run test to verify failure
   - Step 3: Implement minimal code
   - Step 4: Run tests to confirm pass
   - Step 5: Commit

4. **Include in header:**
   - Goal (one sentence)
   - Architecture (2-3 sentences)
   - Tech stack

5. **Reference skills:**
   - Mention relevant skills (e.g., "Follow hexagonal architecture per golang skill")
   - Reference testing patterns from skill files

**Output:**
- Create the plan file
- List all tasks with brief descriptions
- Note any questions or assumptions made
