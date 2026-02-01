---
description: Generate changelog entries from recent commits and PRs
---

Generate a changelog entry for version: $1

**Use the changelog-generator agent from ~/.claude/agents/workflow/changelog-generator.md**

**Process:**

1. **Gather information:**
   - Run `git log` to see commits since last tag/release
   - Check for merged PRs if using GitHub
   - Identify breaking changes

2. **Categorize changes:**
   - **Added**: New features
   - **Changed**: Changes to existing functionality
   - **Deprecated**: Features to be removed in future
   - **Removed**: Removed features
   - **Fixed**: Bug fixes
   - **Security**: Security-related fixes

3. **Format each entry:**
   ```
   - [Description of change] ([#PR] by @author)
   ```

4. **Output format:**
   ```markdown
   ## [Version] - YYYY-MM-DD

   ### Added
   - Feature description

   ### Changed
   - Change description

   ### Fixed
   - Bug fix description
   ```

**Include:**
- Brief, user-focused descriptions
- PR/issue references where available
- Breaking change warnings (if any)
- Migration notes for breaking changes
