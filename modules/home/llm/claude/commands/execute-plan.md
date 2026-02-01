---
description: Execute an implementation plan with batch processing and checkpoints
---

Execute the implementation plan at: $1

**Use the executing-plans skill from ~/.claude/skills/executing-plans/SKILL.md**

**Execution process:**

1. **Load and review the plan**
   - Read the plan file completely
   - Review critically for unclear instructions or gaps
   - Raise concerns BEFORE starting

2. **Execute in batches (default: 3 tasks)**
   - Mark task as in_progress
   - Follow each step EXACTLY as written
   - Run verifications as specified
   - Mark task as completed

3. **Report after each batch:**
   ```
   ## Batch Complete

   ### Implemented:
   - Task N: [Brief description]

   ### Verification Output:
   [Test results, build output]

   ### Issues Found:
   [Any problems]

   Ready for feedback.
   ```

4. **Wait for feedback before continuing**

5. **If blocked:**
   - Stop immediately
   - Report the blocker
   - Do NOT guess or work around

**IMPORTANT:**
- Never start on main/master without explicit consent
- Follow TDD steps exactly (test first)
- Run quality gates (tests, lint) between batches
