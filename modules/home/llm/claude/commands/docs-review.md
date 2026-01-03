---
description: Automated documentation pull request review
---

Review $1 documentation pull request and provide a list of potential improvements:

**Review process:**
1. Fetch the PR and examine all changed documentation files
2. Check existing documentation structure and style patterns
3. Verify consistency with project's documentation conventions

**Documentation standards:**
- **General**: Follow Google Developer Documentation Style Guide principles
- **Structure**: Apply Divio Documentation System (tutorials/how-to/reference/explanation)
- **Writing**: Follow Microsoft Writing Style Guide for clarity and accessibility

**What to review:**

**Clarity and accessibility:**
- Unexplained jargon, acronyms, or technical terms (must be defined or linked)
- Assumptions about reader's prior knowledge (document assumes familiarity with concepts)
- Missing context or background information
- Ambiguous pronouns or references (what does "this" or "it" refer to?)
- Sentences that are too long or complex
- Passive voice that obscures meaning

**Completeness:**
- Missing links to related documentation or concepts
- References to other parts of the project without links
- Undefined terms or concepts mentioned but not explained
- Missing prerequisites or requirements
- Incomplete examples or code snippets
- Missing error handling or troubleshooting guidance

**Structure and navigation:**
- Poor document organization or flow
- Missing table of contents for long documents
- Headers that don't clearly describe content
- Missing cross-references between related docs
- Inconsistent heading hierarchy

**Code examples (if present):**
- Examples that don't run or are incomplete
- Missing explanation of what example demonstrates
- No context about when to use this approach
- Missing expected output or results

**Consistency:**
- Terminology inconsistent with rest of documentation
- Formatting that differs from existing docs
- Tone or style that doesn't match project voice
- Inconsistent use of capitalization, punctuation, or formatting

**Conciseness:**
- Redundant explanations or repetitive content
- Unnecessary words that don't add value
- Content that could be simplified without losing meaning
- Multiple ways of saying the same thing

**Output format:**
List each issue with:
- File path and line/section reference
- Category (clarity/completeness/structure/consistency/conciseness)
- Description of the issue
- Suggested improvement