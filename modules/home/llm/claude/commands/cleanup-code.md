---
description: Cleanup before commiting
---

Review my code changes compared to main/master branch and help me clean them up:

**Language-specific standards (apply based on code language):**
- **Go**: Follow best practices from Effective Go (https://go.dev/doc/effective_go)
  - Doc comments MUST start with the name being documented: `// FunctionName does...` not `// Does...`
  - For struct fields: `// FieldName is the...` not `// The field is...`
  - Error handling MUST be immediately after error is returned - no statements between error return and check
- **Python**: Follow PEP 8 style guide and Pythonic idioms
- **Rust**: Follow Rust API Guidelines and idiomatic Rust patterns
- **TypeScript**: Follow TypeScript best practices and JavaScript Standard Style
- **Terraform**: Follow HashiCorp's Terraform style conventions and best practices
- **Bash**: Follow Google's Shell Style Guide principles and best practices
- **GitHub Actions**: Follow GitHub Actions security and best practices

1. **Remove unused items:**
   - Unused imports/dependencies
   - Unused variables, functions, or methods
   - Dead code paths
   - Commented-out code that should be removed
   - Debugging logs (console.log, print statements, etc.) that were added for troubleshooting

2. **Simplify code:**
   - Reduce complexity where possible
   - Eliminate redundant logic or duplicate code
   - Replace verbose patterns with simpler alternatives
   - Combine related operations

3. **Improve structure:**
   - Suggest better variable/function names if current ones are unclear
   - Split bigger functions into smaller helper functions
   - Avoid nested ifs - use early returns, guard clauses, or extract to separate functions
   - Identify opportunities to extract reusable functions
   - Point out inconsistent patterns

4. **Maintain functionality:**
   - Don't suggest changes that alter behavior
   - Preserve intentional logging (errors, warnings, important info)
   - Keep all necessary error handling
   - Keep important comments

Provide your suggestions as a list with specific line references, and show the cleaned-up code for each issue.