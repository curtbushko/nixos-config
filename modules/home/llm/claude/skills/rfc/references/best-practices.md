# RFC Best Practices

Industry best practices for writing effective RFCs and design documents.

## The RFC Mindset

### Purpose of an RFC

An RFC is NOT:
- An approval gate
- A rubber stamp process
- A way to assign blame

An RFC IS:
- A collaborative tool to shape ideas
- A way to find serious flaws early
- A mechanism for building consensus
- Documentation of decision-making rationale

### When to Write an RFC

| Situation | RFC? | Alternative |
|-----------|------|-------------|
| Major architectural change | Yes | - |
| New feature affecting multiple teams | Yes | - |
| Significant technical risk | Yes | - |
| Minor feature, single team | Maybe | Mini RFC |
| Bug fix with clear solution | No | Ticket/PR |
| Config change | No | Change request |
| Already decided, need to document | No | ADR |

## Writing Effective Background Sections

### The Newcomer Test

> "If you can't show a random engineer the background section and have them acquire nearly full context on the necessity for the RFC, then the background section is not complete enough."

### Elements of Good Background

1. **Current state**: How things work today
2. **Problem statement**: Why the current state is insufficient
3. **Historical context**: What was tried before
4. **Constraints**: What limits our options
5. **Links**: References to all relevant documents

### Bad vs Good Background

**Bad:**
> "We need to improve widget performance."

**Good:**
> "Widget creation currently takes 5-10 seconds (see [metrics dashboard](link)). User research (see [PRD-123](link)) identified this as the #1 complaint. Previous attempts to optimize the database queries ([RFC-45](link)) reduced latency by 30%, but we're still 3x slower than competitors. Our SLA requires sub-2-second response times by Q3."

## Proposal Writing

### Structure Your Proposal Clearly

```markdown
## Proposal

### Goal
[One sentence: what success looks like]

### Approach
[2-3 paragraphs: how we'll achieve the goal]

### Key Decisions
[Table or list of important choices and rationale]

### Scope
[What's in, what's out]
```

### Justify Key Decisions

For each significant decision, answer:
- What alternatives exist?
- Why was this option chosen?
- What are the tradeoffs?

### Be Specific, Not Vague

| Vague | Specific |
|-------|----------|
| "Improve performance" | "Reduce p99 latency from 500ms to 100ms" |
| "Better error handling" | "Return structured errors with error codes" |
| "Scale better" | "Support 10x current throughput (1M req/s)" |
| "Use caching" | "Add Redis cache with 5-minute TTL for user data" |

## Implementation Details

### Level of Detail

**Include:**
- API signatures and contracts
- Data structures and schemas
- Component interactions
- Files/modules affected

**Exclude:**
- Line-by-line code changes
- Exact variable names
- Implementation details that may change
- Boilerplate code

### Example: API Change Documentation

```markdown
### API Changes

#### Before
```go
func GetUser(id string) *User
```

#### After
```go
func GetUser(ctx context.Context, id string) (*User, error)
```

#### Migration
- All callers must update to handle error return
- Context timeout of 30s recommended
- Old signature deprecated in v1.5, removed in v2.0
```

## Documenting Abandoned Ideas

### Why Document Abandoned Ideas

1. **Prevents re-discovery**: Others won't waste time on rejected approaches
2. **Shows thoroughness**: Demonstrates alternatives were considered
3. **Provides context**: Future readers understand the decision space
4. **Enables revisiting**: Circumstances may change

### How to Document

```markdown
## Abandoned Ideas

### Use Redis Instead of Memcached

**Proposed**: Use Redis for caching layer due to richer data structures.

**Why Abandoned**:
- Our use case only needs simple key-value storage
- Team has more Memcached expertise
- Redis would require new infrastructure

**Revisit When**: If we need sorted sets or pub/sub functionality.
```

## RFC Process

### Lifecycle

```
┌─────────┐    ┌───────────┐    ┌──────────┐    ┌─────────────┐
│   WIP   │───▶│ In-Review │───▶│ Approved │───▶│ Implemented │
└─────────┘    └───────────┘    └──────────┘    └─────────────┘
     │              │                                   │
     │              │                                   │
     ▼              ▼                                   ▼
┌─────────┐    ┌───────────┐                    ┌───────────┐
│Abandoned│    │  Obsolete │                    │  Obsolete │
└─────────┘    └───────────┘                    └───────────┘
```

### Review Process

1. **Share early**: Don't wait for perfection
2. **Identify reviewers**: List specific people whose input is needed
3. **Set expectations**: Deadline for feedback, decision-maker(s)
4. **Iterate publicly**: Update the RFC based on feedback
5. **Document decisions**: Record what was decided and why

### Getting Good Feedback

**Before sharing:**
- State what kind of feedback you need
- Highlight areas of uncertainty
- Set a deadline for responses

**Good prompts:**
- "I'm uncertain about the caching strategy in section 4"
- "Please review the security implications"
- "Is this the right level of detail for the API section?"

**Bad prompts:**
- "Let me know what you think"
- "Any feedback welcome"

## Common Pitfalls

### 1. The Infinite WIP

**Problem**: RFC stays in draft forever
**Solution**: Set a deadline. Share early, iterate in public.

### 2. The Approval-Seeking Document

**Problem**: RFC written to justify a decision already made
**Solution**: If decision is made, write an ADR instead. RFCs are for collaboration.

### 3. The Missing Background

**Problem**: Assumes reader knows the context
**Solution**: Apply the newcomer test. Link to everything relevant.

### 4. The Solution Without a Problem

**Problem**: Proposes technology/approach without clear problem statement
**Solution**: Reference the PRD. If no PRD exists, write one first.

### 5. The Orphaned RFC

**Problem**: RFC approved but never implemented or updated
**Solution**: Update status regularly. Mark as obsolete if circumstances change.

### 6. The Bikeshed

**Problem**: Feedback focuses on trivial details, ignores important issues
**Solution**: Direct reviewers to specific sections. Explicitly note what's not up for debate.

## RFC vs Other Documents

| Document | When to Use | Key Difference |
|----------|-------------|----------------|
| **RFC** | Proposing solution, seeking feedback | Collaborative, before decision |
| **PRD** | Defining problem and requirements | Problem-focused, before RFC |
| **ADR** | Recording architectural decision | Documents decision already made |
| **Tech Spec** | Detailed implementation plan | After RFC approval, more detail |
| **Design Doc** | Visual/UX design decisions | Complements RFC, design focus |

### Architecture Decision Records (ADRs)

For decisions that don't need discussion, use an ADR instead:

```markdown
# ADR-001: Use PostgreSQL for User Data

## Status
Accepted

## Context
We need a database for user data. Options considered:
- PostgreSQL: Strong consistency, team expertise
- MongoDB: Schema flexibility
- DynamoDB: Managed, scalable

## Decision
Use PostgreSQL.

## Consequences
- Need to manage schema migrations
- Team can use existing expertise
- Strong ACID guarantees
```

## Mini RFC Template

For smaller changes, use a condensed format:

```markdown
# [Mini RFC] Title

**Owner**: [Name]
**Status**: WIP / In-Review / Approved
**Date**: [Date]

## Problem
[2-3 sentences describing the problem]

## Proposal
[2-3 paragraphs describing the solution]

## Implementation
- [Key change 1]
- [Key change 2]
- [Key change 3]

## Risks
- [Risk 1]: [Mitigation]
- [Risk 2]: [Mitigation]

## Open Questions
- [Question 1]
- [Question 2]
```

## References

### Templates and Examples

- [HashiCorp RFC Template](https://works.hashicorp.com/articles/rfc-template)
- [Sourcegraph RFCs](https://github.com/sourcegraph/handbook/blob/main/content/company-info-and-process/communication/rfcs/index.md)
- [Resend RFC Process](https://resend.com/handbook/engineering/how-we-use-rfcs)
- [Squarespace RFC Template](https://engineering.squarespace.com/blog/2019/the-power-of-yes-if)

### Articles and Guides

- [Pragmatic Engineer: RFCs and Design Docs](https://blog.pragmaticengineer.com/rfcs-and-design-docs/)
- [Writing Technical Specifications](https://www.pointfive.co/engineering/engineering-blog/writing-technical-specifications-the-art-of-tailoring-rfcs)
- [HackMD: Creating Effective RFCs](https://homepage.hackmd.io/blog/2024/04/05/creating-effective-request-for-comments-rfc-document)
- [Casper Tech: Lightweight Technical Designs](https://medium.com/caspertechteam/rfcs-lightweight-technical-designs-a508d93ccd34)

### RFC Keywords (RFC 2119)

When writing requirements, consider using standard keywords:

| Keyword | Meaning |
|---------|---------|
| **MUST** | Absolute requirement |
| **MUST NOT** | Absolute prohibition |
| **SHOULD** | Recommended but not required |
| **SHOULD NOT** | Discouraged but not prohibited |
| **MAY** | Optional |
