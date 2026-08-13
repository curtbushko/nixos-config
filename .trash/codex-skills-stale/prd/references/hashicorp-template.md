# HashiCorp PRD Template

This is a ready-to-use PRD template based on HashiCorp's "How HashiCorp Works" methodology.

## Template

Copy and fill in the sections below:

---

# PRD: [Product/Feature Name]

| Field | Value |
|-------|-------|
| **Created** | [Date] |
| **Last Updated** | [Date] |
| **Author** | [Name] |
| **Status** | Draft / In Review / Approved |
| **Target Release** | [Version/Quarter] |

## 1. Introduction

> Write this section LAST after completing all other sections.

[One paragraph executive summary: What problem are we solving? Who is affected? Why does it matter? What's the scope?]

**Related Documents**:
- RFC: [link if applicable]
- User Research: [link]
- Design Specs: [link if applicable]

---

## 2. Background

### Current State

[Describe how the system/product works today. What exists? How do users currently accomplish the task?]

### Historical Context

[Any previous attempts to solve this problem? What worked or didn't work? Why are we revisiting this now?]

### Technical Landscape

[Relevant systems, APIs, dependencies, or constraints that readers need to understand]

### Glossary

| Term | Definition |
|------|------------|
| [Term 1] | [Definition] |
| [Term 2] | [Definition] |

---

## 3. Problem Statement

### User Research Summary

[Describe the research conducted: number of interviews, personas involved, methodology, timeframe]

| Persona | Interviewed | Key Pain Points |
|---------|-------------|-----------------|
| [Persona 1] | [N] | [Summary] |
| [Persona 2] | [N] | [Summary] |

### Problem 1: [Descriptive Title]

**Affected Persona**: [Who experiences this problem]

**Problem Statement**:
[Clear description of the problem from the user's perspective. What are they trying to do? What's preventing them?]

**Evidence**:
- "[Direct quote from user research]" - Participant X
- [Quantitative data point: metrics, ticket counts, etc.]
- [Additional supporting evidence]

**Impact**:
[What happens if we don't solve this? Business impact, user impact, competitive risk]

### Problem 2: [Descriptive Title]

**Affected Persona**: [Who]

**Problem Statement**:
[Description]

**Evidence**:
- [Evidence items]

**Impact**:
[Impact description]

---

## 4. Phases and Requirements

### Phase 1: [Objective - Include Persona Reference]

> Example: "Enable DevOps engineers to configure policies without manual YAML editing"

#### Requirement 1.1: [Component/Feature Name]

**Description**:
[What needs to be built or changed]

**User Story**:
As a [persona], I want [goal/action] so that [benefit/outcome].

**Functional Requirements**:
1. [Specific functional requirement]
2. [Specific functional requirement]
3. [Specific functional requirement]

**Non-Functional Requirements**:
- Performance: [Requirement]
- Security: [Requirement]
- Accessibility: [Requirement]

**Acceptance Criteria**:
- [ ] Given [precondition], when [action], then [expected result]
- [ ] Given [precondition], when [action], then [expected result]
- [ ] [Additional testable criterion]

**Out of Scope for This Requirement**:
- [Explicitly excluded item]

#### Requirement 1.2: [Next Component]

[Same structure as above]

### Phase 2: [Next Objective]

[Same structure with requirements]

---

## 5. Success Metrics

| Metric | Current Baseline | Target | How Measured | Timeline |
|--------|------------------|--------|--------------|----------|
| [Metric 1] | [Value] | [Target] | [Method] | [When] |
| [Metric 2] | [Value] | [Target] | [Method] | [When] |
| [Metric 3] | [Value] | [Target] | [Method] | [When] |

### Qualitative Success Indicators

- [User satisfaction indicator]
- [Adoption indicator]
- [Quality indicator]

---

## 6. Non-Goals (Out of Scope)

The following are explicitly **NOT** addressed in this PRD:

1. **[Item]**: [Reason for exclusion or where it will be addressed]
2. **[Item]**: [Reason]
3. **[Item]**: [Reason]

---

## 7. Dependencies and Risks

### Dependencies

| Dependency | Owner | Status | Impact if Delayed |
|------------|-------|--------|-------------------|
| [Dependency 1] | [Team/Person] | [Status] | [Impact] |
| [Dependency 2] | [Team/Person] | [Status] | [Impact] |

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk 1] | High/Med/Low | High/Med/Low | [Mitigation strategy] |
| [Risk 2] | High/Med/Low | High/Med/Low | [Mitigation strategy] |

---

## 8. Stakeholder Sign-off

### Stakeholders

| Role | Name | Review Status | Date | Comments |
|------|------|---------------|------|----------|
| Product Manager | [Name] | [ ] Pending / [ ] Approved | | |
| Engineering Lead | [Name] | [ ] Pending / [ ] Approved | | |
| Design Lead | [Name] | [ ] Pending / [ ] Approved | | |
| QA Lead | [Name] | [ ] Pending / [ ] Approved | | |
| [Other] | [Name] | [ ] Pending / [ ] Approved | | |

### Sign-off Checklist

Before approving, stakeholders confirm:

- [ ] Problem statements are clear and well-researched
- [ ] Requirements address the stated problems
- [ ] Acceptance criteria are testable
- [ ] Success metrics are measurable
- [ ] Scope (and non-goals) are clearly defined
- [ ] Dependencies are identified and owners notified
- [ ] Target release is realistic given resources

---

## Appendix

### A. Raw User Research Data

[Link to or summary of interview notes, survey results, etc.]

### B. Competitive Analysis

[If relevant, comparison with how competitors solve this problem]

### C. Technical Notes

[Any technical deep-dives or architecture considerations]

---

## Change History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1 | [Date] | [Name] | Initial draft |
| 0.2 | [Date] | [Name] | [Summary of changes] |

---

## Source

Based on HashiCorp's PRD template from [How HashiCorp Works](https://works.hashicorp.com/articles/prd-template).
