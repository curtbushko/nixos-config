---
name: prd
description: Comprehensive PRD (Product Requirements Document) writing skill based on HashiCorp's template. Use this skill when creating, reviewing, or improving product requirements documents. Covers problem statements, user research, requirements phases, acceptance criteria, and stakeholder sign-off.
---

# PRD (Product Requirements Document) Writing Skill

This skill provides guidance for creating high-quality PRDs that clearly define problems and requirements.

## What is a PRD?

A **Problem Requirements Document (PRD)** helps team members fully understand a problem and define what's needed to address it. Unlike solution-focused documents, a PRD grounds decisions in real, researched user problems.

**Key principle**: Start with the problem, not the solution. Teams that begin with a UI idea or solution tend to bias engineering design and miss the actual user needs.

## PRD Template Structure (HashiCorp Format)

### 1. Introduction

**Purpose**: Provide a brief executive summary of the PRD.

**Important**: Write this section LAST. Writing the introduction after completing the rest allows you to accurately summarize the final content rather than guessing at an unknown result.

Include:
- One-paragraph summary of the problem
- Who is affected
- Why this matters now
- Link to related documents (RFCs, previous PRDs)

```markdown
## Introduction

This PRD addresses [problem] affecting [personas]. Based on research with
[N] users, we identified [key insight]. This work supports [strategic goal]
and is targeted for [timeframe].

**Related Documents**:
- RFC: [link]
- User Research: [link]
```

### 2. Background

**Purpose**: Provide context so readers can understand the problem domain before diving into specifics.

Include:
- Current state of the system/product
- Historical context and previous attempts
- Technical constraints or dependencies
- Market/competitive context (if relevant)
- Glossary of domain-specific terms

```markdown
## Background

### Current State
[Describe how things work today]

### Historical Context
[Previous attempts to solve this, why they succeeded/failed]

### Technical Landscape
[Relevant systems, dependencies, constraints]

### Glossary
- **Term**: Definition
```

### 3. Problem Statement / User Research

**Purpose**: This is the HEART of the PRD. Simplify user research into clear problem statements.

**Quality of this section determines PRD quality**. The better the research, the easier it is to identify patterns and create clear problem statements.

#### Conducting User Research

1. **Gather qualitative data**: User interviews, support tickets, feedback
2. **Identify patterns**: Common complaints, workflows, pain points
3. **Define personas**: Who experiences these problems?
4. **Prioritize**: Which problems are most impactful?

#### Writing Problem Statements

Each problem statement should:
- Clearly describe WHAT the problem is
- Identify WHO it affects (persona)
- Explain WHY it's important to solve
- Be supported by research data

```markdown
## Problem Statement

### User Research Summary

We conducted [N] interviews with [personas] between [dates].

| Persona | # Interviewed | Key Pain Points |
|---------|---------------|-----------------|
| DevOps Engineer | 8 | Manual config, no visibility |
| Platform Admin | 5 | Scaling issues, alert fatigue |

### Problem 1: [Descriptive Title]

**Affected Persona**: [Who]

**Problem**: [Clear description of the problem from user's perspective]

**Evidence**:
- "Quote from user interview" - User A
- Support ticket volume: X tickets/month
- [Metric showing impact]

**Impact**: [Business/user impact if not solved]

### Problem 2: [Descriptive Title]
[Same structure]
```

### 4. Phases and Requirements

**Purpose**: Define objectives for solving the problem, organized into phases.

#### Phase Structure

Each phase:
- Focuses on a single problem from the user's perspective
- May contain multiple requirements to address specific components
- Should reference the persona in the title

#### Requirement Format

```markdown
## Phases and Requirements

### Phase 1: [Objective referencing persona]

Example: "Make it easier for policy writers to create Terraform mock data"

#### Requirement 1.1: [Specific Component/Feature]

**Description**: [What needs to be built/changed]

**User Story**: As a [persona], I want [goal] so that [benefit].

**Acceptance Criteria**:
- [ ] [Testable criterion 1]
- [ ] [Testable criterion 2]
- [ ] [Testable criterion 3]

**Out of Scope**: [Explicitly list what this does NOT include]

#### Requirement 1.2: [Next Component]
[Same structure]

### Phase 2: [Next Objective]
[Same structure]
```

### 5. Acceptance Criteria

**Purpose**: Define testable conditions that must be met for requirements to be considered complete.

**Key principle**: Write acceptance criteria like test cases.

#### SMART Criteria

Acceptance criteria must be:
- **S**pecific: Clear and unambiguous
- **M**easurable: Can be verified objectively
- **A**chievable: Technically feasible
- **R**elevant: Directly addresses the requirement
- **T**ime-bound: Has a clear completion state

#### Given/When/Then Format

```markdown
## Acceptance Criteria

### Requirement 1.1 Criteria

**Criterion 1**: User can create mock data from existing policy
- **Given**: A user has an existing Sentinel policy
- **When**: They click "Generate Mock Data"
- **Then**: The system creates valid mock data matching the policy schema

**Criterion 2**: Error handling for invalid policies
- **Given**: A user has a malformed policy
- **When**: They attempt to generate mock data
- **Then**: The system displays a specific error message indicating the issue
```

### 6. Success Metrics

**Purpose**: Define how we'll measure if the solution actually solves the problem.

Include:
- Quantitative metrics (adoption, performance, reduction in X)
- Qualitative metrics (user satisfaction, NPS)
- Baseline measurements
- Target values
- Measurement method

```markdown
## Success Metrics

| Metric | Baseline | Target | Measurement Method |
|--------|----------|--------|-------------------|
| Time to create mock data | 45 min | < 5 min | User testing |
| Support tickets (mock data) | 50/month | < 10/month | Zendesk |
| User satisfaction | 3.2/5 | > 4.0/5 | In-app survey |
```

### 7. Non-Goals (Out of Scope)

**Purpose**: Explicitly state what this PRD does NOT address to prevent scope creep.

```markdown
## Non-Goals

The following are explicitly OUT OF SCOPE for this PRD:

1. **[Item]**: [Brief reason why it's excluded]
2. **[Item]**: [Will be addressed in future phase/separate PRD]
3. **[Item]**: [Not aligned with current objectives]
```

### 8. Stakeholder Sign-off

**Purpose**: Ensure alignment before proceeding to implementation.

**Requirements for sign-off**:
1. Release summary defines which acceptance criteria are in scope
2. Engineering and Product Management agree on target release
3. All representative stakeholders have reviewed

```markdown
## Stakeholder Sign-off

| Role | Name | Status | Date | Notes |
|------|------|--------|------|-------|
| Product Manager | | [ ] Approved | | |
| Engineering Lead | | [ ] Approved | | |
| Design Lead | | [ ] Approved | | |
| [Other Stakeholder] | | [ ] Approved | | |

### Sign-off Checklist

- [ ] All stakeholders have reviewed the PRD
- [ ] Acceptance criteria are agreed upon
- [ ] Target release/timeline is confirmed
- [ ] Resources are allocated
- [ ] Dependencies are identified and communicated
```

## PRD Best Practices

### Do

- Start with user research, not solutions
- Write the introduction last
- Make acceptance criteria testable
- Include explicit non-goals
- Get stakeholder sign-off before implementation
- Keep the document living and updated
- Use clear, specific language with quantities where possible

### Don't

- Begin with a UI mockup or solution idea
- Write acceptance criteria that can't be objectively verified
- Skip user research or rely on assumptions
- Leave scope ambiguous
- Proceed without stakeholder alignment
- Create overly rigid specifications that can't adapt

### Common Mistakes

1. **Solution-first thinking**: Jumping to "we need a button that..." before understanding the problem
2. **Vague criteria**: "System should be fast" instead of "Response time < 200ms"
3. **Missing personas**: Not identifying who experiences the problem
4. **No evidence**: Problem statements without research backing
5. **Scope creep**: Not explicitly defining what's out of scope

## PRD Review Checklist

Before finalizing a PRD, verify:

- [ ] Introduction accurately summarizes the document
- [ ] Background provides sufficient context for any reader
- [ ] Problem statements are backed by user research
- [ ] Each problem maps to a specific persona
- [ ] Requirements clearly address the stated problems
- [ ] Acceptance criteria are SMART and testable
- [ ] Success metrics have baselines and targets
- [ ] Non-goals are explicitly stated
- [ ] All stakeholders are identified
- [ ] Document is clear enough for someone unfamiliar to understand

## Agile PRD Considerations

For Agile teams, the PRD becomes a living document:

- **User Stories**: Requirements can be expressed as user stories
- **Epics**: Large requirements become epics broken into stories
- **Iteration**: PRD evolves as understanding deepens
- **Acceptance Criteria**: Map directly to definition of done

```markdown
### User Story Format

**Epic**: [High-level capability]

**Story**: As a [persona], I want [goal] so that [benefit]

**Acceptance Criteria**:
- [ ] Given [context], when [action], then [result]
- [ ] Given [context], when [action], then [result]

**Story Points**: [Estimate]
```

## Additional Resources

- For detailed template examples: See `references/hashicorp-template.md`
- For best practices from industry: See `references/best-practices.md`

## References

- [HashiCorp PRD Template](https://works.hashicorp.com/articles/prd-template)
- [Product School PRD Guide](https://productschool.com/blog/product-strategy/product-template-requirements-document-prd)
- [Atlassian Agile Requirements](https://www.atlassian.com/agile/product-management/requirements)
- [Aha.io PRD Templates](https://www.aha.io/roadmapping/guide/requirements-management/what-is-a-good-product-requirements-document-template)
- [Perforce PRD Guide](https://www.perforce.com/blog/alm/how-write-product-requirements-document-prd)
