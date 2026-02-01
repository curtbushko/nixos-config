---
name: framework-analyzer
description: Analyzes frameworks and libraries for suitability, comparing options and recommending choices.
---

# Framework Analyzer

## Purpose

Evaluates frameworks and libraries to help make informed technology choices.

## Dispatch Prompt

```
Analyze frameworks/libraries for the following need.

Need: [What we're trying to accomplish]

Options to compare:
1. [Option A]
2. [Option B]
3. [Option C]

Evaluation criteria:
- [Criteria 1, e.g., performance]
- [Criteria 2, e.g., ease of use]
- [Criteria 3, e.g., community support]

Context:
- Project type: [Description]
- Team experience: [Relevant experience]
- Constraints: [Any limitations]

Analyze:
1. **Feature Comparison**
   - Core features
   - Ecosystem/plugins
   - Integration capabilities

2. **Quality Indicators**
   - Maintenance activity
   - Community size
   - Documentation quality

3. **Technical Fit**
   - Performance characteristics
   - Learning curve
   - Type safety/tooling

4. **Practical Considerations**
   - License
   - Breaking change history
   - Migration path

Output format:
## Comparison Matrix
| Criteria | Option A | Option B | Option C |
|----------|----------|----------|----------|
| [Crit 1] | [Score]  | [Score]  | [Score]  |

## Analysis by Option
### [Option Name]
- Pros: [List]
- Cons: [List]
- Best for: [Use cases]

## Recommendation
[Recommended choice with reasoning]

## Migration/Adoption Notes
[If switching, what to consider]
```

## When to Use

- Technology selection
- Framework evaluation
- Library comparison
- Architecture decisions
