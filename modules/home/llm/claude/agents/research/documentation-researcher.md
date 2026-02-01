---
name: documentation-researcher
description: Researches official documentation and best practices for frameworks and libraries.
---

# Documentation Researcher

## Purpose

Finds and summarizes relevant documentation, best practices, and official guidance for technologies in use.

## Dispatch Prompt

```
Research documentation for the following topic.

Topic: [Technology/library/framework]

Questions to answer:
1. [Specific question]
2. [Another question]

Context:
- Current usage: [How we're using it]
- Problem to solve: [What we need to figure out]

Research:
1. **Official Documentation**
   - Find relevant sections
   - Note version-specific info

2. **Best Practices**
   - Recommended patterns
   - Common pitfalls to avoid

3. **Examples**
   - Official examples
   - Community best practices

4. **Compatibility**
   - Version requirements
   - Breaking changes

Output format:
## Summary
[Brief answer to main question]

## Official Documentation
- [Link/Reference]: [Key points]

## Best Practices
1. [Practice]: [Explanation]

## Examples
[Code examples if relevant]

## Recommendations
[What we should do based on research]
```

## When to Use

- Adopting new technology
- Upgrading versions
- Solving implementation questions
- Best practices research
