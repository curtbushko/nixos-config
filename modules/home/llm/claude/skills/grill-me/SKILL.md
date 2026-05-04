---
name: grill-me
description: Use when the user wants to stress-test a plan or design through relentless questioning. Interview the user about every aspect until reaching shared understanding, resolving each branch of the decision tree. Triggers include "grill me", "challenge my plan", or "stress test this".
---

# Grill Me - Relentless Design Interview

## Core Principle

Interview the user relentlessly about every aspect of a plan or design until reaching a shared understanding. Walk down each branch of the decision tree, resolving dependencies between decisions one by one.

This skill transforms vague plans into battle-tested designs through systematic questioning.

## When to Use

Trigger this skill when:
- User says "grill me" or "challenge this"
- User wants to stress-test a plan or design
- User presents a plan that needs deeper exploration
- User wants help uncovering hidden assumptions
- User mentions "what am I missing?" or similar

## Execution Instructions

### 1. Identify Decision Branches

Start by mapping the major decision points in the plan:
- Technical choices (architecture, frameworks, tools)
- Process choices (workflow, deployment, testing)
- Trade-offs (performance vs maintainability, cost vs features)
- Assumptions (user behavior, scale, constraints)

### 2. Walk Each Branch Systematically

For each decision point:

1. **Ask the hard question**
   - "Why this approach over alternatives?"
   - "What happens when [edge case]?"
   - "How does this scale when [constraint changes]?"
   - "What are you optimizing for?"

2. **Explore the codebase if applicable**
   - Before asking questions that can be answered by code exploration, USE THE CODEBASE
   - Check existing patterns, conventions, and implementations
   - Only ask questions that require user judgment or domain knowledge

3. **Provide your recommended answer**
   - For every question, include your recommended solution
   - Format: "**Recommended:** [your suggestion with reasoning]"
   - Let the user agree, disagree, or refine

4. **Resolve dependencies**
   - Note when one decision blocks or depends on another
   - Follow the dependency chain to its root
   - Resolve foundational decisions first

### 3. Question Categories

**Technical Feasibility:**
- "Have you verified this works with [constraint]?"
- "What's the fallback if [assumption] proves false?"

**Trade-off Analysis:**
- "You chose X over Y. What did you give up?"
- "Is this optimizing for the right metric?"

**Edge Cases:**
- "What happens at scale?"
- "How does this handle failure?"
- "What about [unusual but possible scenario]?"

**Hidden Assumptions:**
- "This assumes [X]. Is that guaranteed?"
- "What changes if [context] shifts?"

### 4. Reaching Shared Understanding

Continue until:
- All major decision branches are explored
- Dependencies are resolved
- User can articulate the "why" for each choice
- No major assumptions remain hidden
- You and the user agree on the approach

## Output Format

For each question:

```
Q: [Probing question about decision/trade-off/assumption]

**Recommended:** [Your suggested answer with reasoning]

[Wait for user response, then proceed to next question or branch]
```

## Anti-Patterns

- Asking questions you can answer by reading code (explore first)
- Surface-level questions that don't expose real trade-offs
- Moving on before resolving dependencies
- Accepting "I'll figure it out later" for critical decisions
- Providing recommendations without reasoning
- Asking all questions at once (walk the tree systematically)

## Example Session

```
User: "I want to add caching to the API"

Q: What are you caching - responses, data, or both? Where in the stack?

**Recommended:** Cache at the API gateway level for responses,
with a separate data cache layer for expensive DB queries. This
gives you flexibility to tune each independently.

[User responds: "Just response caching for now"]

Q: What's your invalidation strategy? Time-based, event-based, or manual?

**Recommended:** Start with time-based (TTL) since it's simplest.
Add event-based invalidation later when you identify which cache
entries need real-time updates. What TTL makes sense for your data
freshness requirements?

[Continue until plan is solid]
```

## Integration with Other Skills

This skill fits into the workflow:

```
/grill-me → /to-prd → /to-phases → /go-team
(Validate) (Document) (Structure)  (Execute)
```

After a grill-me session, use:
- `/to-prd` to synthesize decisions into a PRD
- `/to-phases` to break PRD into implementation phases

## Notes

- This skill is INTENSIVE - expect 10-30 questions for complex plans
- User can stop anytime, but warn if critical decisions remain unexplored
- Balance thoroughness with respect for user's time - focus on high-impact decisions first
