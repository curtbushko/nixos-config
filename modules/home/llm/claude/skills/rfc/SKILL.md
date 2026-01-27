---
name: rfc
description: Comprehensive RFC (Request for Comments) writing skill based on HashiCorp's template. Use this skill when proposing technical solutions, seeking feedback on designs, or documenting engineering decisions. Covers overview, background, proposal, implementation, UI/UX considerations, and abandoned ideas.
---

# RFC (Request for Comments) Writing Skill

This skill provides guidance for creating effective RFCs that propose solutions and drive consensus through collaborative feedback.

## What is an RFC?

A **Request for Comments (RFC)** is a formal written document that proposes a solution to a problem and seeks feedback on that proposal. Unlike a PRD which focuses on the problem, an RFC focuses on the solution.

**Key principle**: An RFC facilitates feedback and drives consensus. It is not a tool for approving or committing to ideas, but a collaborative practice to shape an idea and find serious flaws early.

## When to Use an RFC

**Use an RFC when:**
- A change will affect many stakeholders
- Proposing a significant technical solution
- Seeking thoughtful feedback across distributed teams
- Making important cross-functional decisions
- The implementation approach needs validation

**Skip an RFC when:**
- The change is trivial or well-understood
- You're the sole decider without needing input
- A quick discussion would suffice

## RFC vs PRD

| Document | Focus | When to Write |
|----------|-------|---------------|
| PRD | The **problem** and requirements | Before solution design |
| RFC | The **solution** and implementation | After problem is understood |

A PRD answers: "What problem are we solving and why?"
An RFC answers: "How will we solve it?"

## RFC Template Structure (HashiCorp Format)

### 1. Metadata

```markdown
# [RFC] Title: Brief Description of Proposal

| Field | Value |
|-------|-------|
| **Created** | [Date] |
| **Current Version** | [Version] |
| **Target Version** | [Version] |
| **PRD** | [Link if applicable] |
| **Status** | WIP / In-Review / Approved / Obsolete |
| **Owner** | [Name] |
| **Contributors** | [Names] |
```

### Status Labels

| Status | Meaning |
|--------|---------|
| **WIP** | Still drafting; not ready for review |
| **In-Review** | Ready for feedback from stakeholders |
| **Approved** | Decision finalized, ready for implementation |
| **Implemented** | Proposal executed |
| **Obsolete** | Superseded by another RFC |
| **Abandoned** | Decision made not to proceed |

### 2. Overview

**Purpose**: Provide a brief executive summary (1-2 paragraphs).

**Important**: Anyone opening the document should form a clear understanding of the RFC's intent from reading this section alone.

Include:
- What this RFC proposes (high-level)
- The goal or outcome expected
- NOT the detailed "why", "why now", or "how"

```markdown
## Overview

This RFC proposes [solution] to address [problem summary]. The expected
outcome is [benefit/goal]. This change will affect [scope/systems].
```

### 3. Background

**Purpose**: Provide full context so any reader can understand why this RFC is necessary.

**Key test**: If you can't show a random engineer the background section and have them acquire nearly full context on the necessity for the RFC, the background is not complete enough.

Include:
- Current state of the system
- Why this change is needed now
- Links to prior RFCs, discussions, PRDs
- Historical context and previous attempts
- Technical constraints

```markdown
## Background

### Current State
[How things work today. What exists. The status quo.]

### Problem Context
[Why the current state is insufficient. Link to PRD if available.]

### Prior Work
[Previous RFCs, discussions, or attempts. What was learned.]

### Constraints
[Technical, organizational, or time constraints affecting the solution.]

**Related Documents**:
- PRD: [link]
- Previous RFC: [link]
- Discussion: [link]
```

### 4. Proposal / Goal

**Purpose**: Given the background, propose the solution.

This section provides an overview of the "how" without diving into implementation details (those come in the next section).

```markdown
## Proposal

### Goal
[What we're trying to achieve with this solution]

### Proposed Solution
[Overview of the approach. High-level description of how it works.]

### Key Design Decisions
1. **[Decision 1]**: [Rationale]
2. **[Decision 2]**: [Rationale]
3. **[Decision 3]**: [Rationale]

### Scope
- **In Scope**: [What this RFC covers]
- **Out of Scope**: [What this RFC does NOT cover]
```

### 5. Implementation

**Purpose**: Detail how the implementation will work.

Include:
- API changes (internal and external)
- Package/module changes
- Data model changes
- Subsystems affected
- Surface area of changes

```markdown
## Implementation

### Architecture Overview
[High-level architecture diagram or description]

### Component Changes

#### [Component 1]
**Current**: [How it works now]
**Proposed**: [How it will work]
**Changes Required**:
- [Change 1]
- [Change 2]

#### [Component 2]
[Same structure]

### API Changes

#### New Endpoints/Methods
```
POST /api/v1/widgets
Request: { "name": string, "config": object }
Response: { "id": string, "status": string }
```

#### Modified Endpoints/Methods
[Existing API changes]

#### Deprecated Endpoints/Methods
[What will be deprecated and timeline]

### Data Model Changes
[Database schema changes, new tables, migrations]

### Dependencies
[External dependencies, services, libraries]
```

### 6. UI/UX (If Applicable)

**Purpose**: Document user-impacting changes.

Include any changes to:
- External API surface
- Configuration formats
- CLI output
- User interfaces
- Error messages

```markdown
## UI/UX

### User-Facing Changes

#### CLI Changes
```
# Before
$ tool config --format json

# After
$ tool config --format json --validate
```

#### Configuration Changes
```yaml
# New configuration option
widgets:
  enabled: true
  max_count: 100
```

#### Error Message Changes
[New or modified error messages users will see]

### Migration Guide
[How users migrate from old to new behavior]

### Documentation Updates Required
- [ ] [Doc page 1]
- [ ] [Doc page 2]
```

### 7. Rollout Plan

**Purpose**: Describe how this will be deployed and validated.

```markdown
## Rollout Plan

### Phases

#### Phase 1: [Description]
- **Timeline**: [Dates]
- **Scope**: [What's included]
- **Success Criteria**: [How we know it worked]
- **Rollback Plan**: [How to revert if needed]

#### Phase 2: [Description]
[Same structure]

### Feature Flags
[Any feature flags used for gradual rollout]

### Monitoring
[Metrics and alerts to watch during rollout]
```

### 8. Testing Strategy

**Purpose**: Describe how the solution will be validated.

```markdown
## Testing Strategy

### Unit Tests
[Key unit test scenarios]

### Integration Tests
[Integration test approach]

### Performance Tests
[Load testing, benchmarks]

### Manual Testing
[Manual validation steps]

### Acceptance Criteria
- [ ] [Criterion 1]
- [ ] [Criterion 2]
```

### 9. Security Considerations

**Purpose**: Address security implications.

```markdown
## Security Considerations

### Threat Model
[What threats does this introduce or mitigate?]

### Authentication/Authorization
[Changes to auth model]

### Data Handling
[Sensitive data considerations]

### Audit/Compliance
[Audit trail, compliance requirements]
```

### 10. Abandoned Ideas

**Purpose**: Document ideas that were considered but rejected.

**Important**: Don't delete abandoned ideas from the document. Organize them with explanations of why they were abandoned. This preserves the reasoning for future readers.

```markdown
## Abandoned Ideas

### [Idea 1 Title]

**Description**: [What was proposed]

**Why Abandoned**: [Reason it was rejected]

**Discussion**: [Link to relevant discussion if any]

### [Idea 2 Title]
[Same structure]
```

### 11. Open Questions

**Purpose**: List unresolved questions that need input.

```markdown
## Open Questions

1. **[Question]**
   - Context: [Why this matters]
   - Options: [Possible answers]
   - Owner: [Who will decide]

2. **[Question]**
   [Same structure]
```

### 12. References

```markdown
## References

- [Related RFC 1](link)
- [External documentation](link)
- [Research/papers](link)
```

## RFC Best Practices

### Writing

- **Background is critical**: If a newcomer can't understand why this RFC exists from the background section alone, it's incomplete
- **Link liberally**: Reference prior RFCs, discussions, PRDs, and documentation
- **Be specific**: Include API signatures, data structures, configuration examples
- **Show your work**: Document abandoned ideas so readers understand the decision process

### Process

- **Share early**: Get feedback while still in WIP status
- **Invite the right reviewers**: Identify stakeholders who will be affected
- **Iterate openly**: Update the RFC based on feedback
- **Don't rush approval**: Consensus takes time in async environments

### Common Mistakes

1. **Skipping background**: Assuming readers know the context
2. **Solution without problem**: Proposing a fix without establishing what's broken
3. **Missing abandoned ideas**: Deleting rejected approaches instead of documenting them
4. **Vague implementation**: "We'll figure it out" instead of concrete details
5. **No rollback plan**: Assuming everything will work perfectly

## RFC Review Checklist

Before marking an RFC as ready for review:

- [ ] Overview is clear enough for any reader to understand intent
- [ ] Background provides full context with links to related docs
- [ ] Proposal clearly explains the solution approach
- [ ] Implementation details are specific and actionable
- [ ] UI/UX section covers all user-facing changes
- [ ] Rollout plan includes phases and rollback strategy
- [ ] Testing strategy is comprehensive
- [ ] Security considerations are addressed
- [ ] Abandoned ideas are documented with reasoning
- [ ] Open questions are listed with owners

## RFC Types

### Full RFC

Use for:
- Major architectural changes
- New features affecting multiple teams
- Changes with significant risk or complexity

### Mini RFC

Use for:
- Minor features or enhancements
- Changes limited in scope
- Maintenance tasks

**Mini RFC Sections**:
1. Problem Statement (concise)
2. Proposed Solution (high-level)
3. Implementation Details (brief)
4. Success Metrics
5. Questions/Concerns

## Additional Resources

- For detailed template: See `references/hashicorp-template.md`
- For best practices from industry: See `references/best-practices.md`

## References

- [HashiCorp RFC Template](https://works.hashicorp.com/articles/rfc-template)
- [How HashiCorp Works](https://www.hashicorp.com/en/how-hashicorp-works)
- [Sourcegraph RFCs](https://github.com/sourcegraph/handbook/blob/main/content/company-info-and-process/communication/rfcs/index.md)
- [Resend RFC Process](https://resend.com/handbook/engineering/how-we-use-rfcs)
- [Pragmatic Engineer: RFCs and Design Docs](https://blog.pragmaticengineer.com/rfcs-and-design-docs/)
