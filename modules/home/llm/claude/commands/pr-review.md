---
description: Automated pull request review
---

Review $1 pull request and provide a list of potential improvements:

**Review process:**
1. Fetch the PR and examine all changed files
2. Search the codebase for similar code patterns to understand the existing style
3. Check consistency with the codebase's conventions and patterns

**Language-specific standards (apply based on code language):**
- **Go**: Follow best practices from Effective Go
- **Python**: Follow PEP 8 style guide and Pythonic idioms
- **Rust**: Follow Rust API Guidelines and idiomatic Rust patterns
- **TypeScript**: Follow TypeScript best practices and JavaScript Standard Style
- **Terraform**: Follow HashiCorp's Terraform style conventions and best practices
- **Bash**: Follow Google's Shell Style Guide principles and best practices
- **GitHub Actions**: Follow GitHub Actions security and best practices

**What to review:**

**Code quality:**
- Unused imports, variables, functions, or methods
- Dead code paths or unreachable code
- Debugging logs that should be removed
- Commented-out code
- Code duplication or redundancy
- Overly complex logic that could be simplified
- Missing error handling
- Potential bugs or edge cases

**Consistency:**
- Naming conventions inconsistent with codebase
- Formatting that differs from existing files
- Patterns that deviate from similar code elsewhere
- Architectural inconsistencies

**Structure:**
- Functions that are too long or do too much
- Unclear variable/function names
- Missing abstractions or reusable components
- Poor separation of concerns

**Output format:**
List each issue with:
- File path and line number(s)
- Category (unused code/simplification/consistency/structure/bug risk)
- Description of the issue
- Suggested fix