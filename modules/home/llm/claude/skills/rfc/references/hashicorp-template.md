# HashiCorp RFC Template

This is a ready-to-use RFC template based on HashiCorp's "How HashiCorp Works" methodology.

## Template

Copy and fill in the sections below:

---

# [RFC] Title: Brief Description of Proposal

| Field | Value |
|-------|-------|
| **Created** | [Date] |
| **Last Updated** | [Date] |
| **Current Version** | [Version, e.g., 1.0] |
| **Target Version** | [Target release version] |
| **PRD** | [Link to PRD if applicable] |
| **Status** | WIP / In-Review / Approved / Implemented / Obsolete / Abandoned |
| **Owner** | [Name] |
| **Contributors** | [Names] |
| **Reviewers** | [Names] |

---

## 1. Overview

> One to two paragraphs explaining the goal of this RFC. Anyone reading this section should understand the RFC's intent without diving into details.

[What does this RFC propose? What is the expected outcome? Keep it high-level.]

---

## 2. Background

> This section should provide enough context that a newcomer to the project can fully understand why this RFC is necessary. Link to prior RFCs, discussions, and documentation as needed.

### Current State

[Describe how the system works today. What exists? What is the status quo?]

### Problem Context

[Why is the current state insufficient? What problem does this RFC address?]

**PRD Reference**: [Link to PRD if one exists]

### Prior Work

[Previous attempts, related RFCs, or discussions. What was learned?]

| Document | Summary | Outcome |
|----------|---------|---------|
| [RFC-XXX](link) | [Brief description] | [Approved/Abandoned/etc.] |
| [Discussion](link) | [Brief description] | [Key takeaway] |

### Constraints

[Technical, organizational, timeline, or resource constraints affecting this solution]

- **Technical**: [Constraint]
- **Timeline**: [Constraint]
- **Resources**: [Constraint]

---

## 3. Proposal

### Goal

[What are we trying to achieve with this solution? What does success look like?]

### Proposed Solution

[Overview of the approach. Explain the "how" at a high level. Details come in the Implementation section.]

### Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| [Decision area 1] | [What we chose] | [Why] |
| [Decision area 2] | [What we chose] | [Why] |
| [Decision area 3] | [What we chose] | [Why] |

### Scope

**In Scope:**
- [Item 1]
- [Item 2]
- [Item 3]

**Out of Scope:**
- [Item 1] - [Reason/where it will be addressed]
- [Item 2] - [Reason]

---

## 4. Implementation

### Architecture Overview

[High-level architecture diagram or description]

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Component  │────▶│  Component  │────▶│  Component  │
│      A      │     │      B      │     │      C      │
└─────────────┘     └─────────────┘     └─────────────┘
```

### Component Changes

#### [Component Name]

**Current Behavior:**
[How it works today]

**Proposed Behavior:**
[How it will work after this RFC]

**Required Changes:**
1. [Change 1]
2. [Change 2]
3. [Change 3]

**Files Affected:**
- `path/to/file1.go`
- `path/to/file2.go`

#### [Another Component]

[Same structure as above]

### API Changes

#### New APIs

```go
// NewWidget creates a widget with the given configuration
func NewWidget(ctx context.Context, config WidgetConfig) (*Widget, error)

type WidgetConfig struct {
    Name        string            `json:"name"`
    Options     map[string]string `json:"options,omitempty"`
    MaxRetries  int               `json:"max_retries"`
}
```

#### Modified APIs

```go
// Before
func CreateWidget(name string) *Widget

// After - added config parameter
func CreateWidget(name string, config *WidgetConfig) (*Widget, error)
```

#### Deprecated APIs

| API | Deprecation Version | Removal Version | Migration Path |
|-----|---------------------|-----------------|----------------|
| `OldFunction()` | v1.5 | v2.0 | Use `NewFunction()` |

### Data Model Changes

#### New Tables/Collections

```sql
CREATE TABLE widgets (
    id          UUID PRIMARY KEY,
    name        VARCHAR(255) NOT NULL,
    config      JSONB,
    created_at  TIMESTAMP DEFAULT NOW(),
    updated_at  TIMESTAMP DEFAULT NOW()
);
```

#### Schema Migrations

[Migration strategy and backwards compatibility considerations]

### Dependencies

| Dependency | Version | Purpose |
|------------|---------|---------|
| [Library 1] | [Version] | [Why needed] |
| [Service 1] | [Version] | [Why needed] |

---

## 5. UI/UX

> Document all user-facing changes including CLI, configuration, error messages, and documentation.

### CLI Changes

**New Commands:**

```bash
# Create a new widget
$ tool widget create --name mywidget --config config.yaml

# List all widgets
$ tool widget list --format json
```

**Modified Commands:**

```bash
# Before
$ tool config get

# After (new --validate flag)
$ tool config get --validate
```

### Configuration Changes

**New Configuration Options:**

```yaml
# config.yaml
widgets:
  enabled: true
  max_count: 100
  default_timeout: 30s
```

**Changed Configuration:**

| Option | Old Default | New Default | Migration |
|--------|-------------|-------------|-----------|
| `timeout` | 60s | 30s | Explicit value if 60s needed |

### Error Messages

**New Error Messages:**

| Code | Message | User Action |
|------|---------|-------------|
| `WIDGET_001` | "Widget limit exceeded" | Increase limit or remove widgets |
| `WIDGET_002` | "Invalid widget config" | Check configuration syntax |

### Migration Guide

For users upgrading from [previous version]:

1. [Step 1]
2. [Step 2]
3. [Step 3]

### Documentation Updates

- [ ] User Guide: [link]
- [ ] API Reference: [link]
- [ ] CLI Reference: [link]
- [ ] Tutorials: [link]

---

## 6. Rollout Plan

### Phases

#### Phase 1: Internal Testing
- **Timeline**: [Dates]
- **Scope**: [What's included]
- **Audience**: [Who has access]
- **Success Criteria**: [How we know it's ready for next phase]

#### Phase 2: Limited Availability
- **Timeline**: [Dates]
- **Scope**: [What's included]
- **Audience**: [Beta users, specific customers]
- **Success Criteria**: [Metrics, feedback thresholds]

#### Phase 3: General Availability
- **Timeline**: [Dates]
- **Scope**: [Full feature set]
- **Announcement**: [How we communicate to users]

### Feature Flags

| Flag | Purpose | Default | Removal Timeline |
|------|---------|---------|------------------|
| `enable_widgets` | Gate widget feature | `false` | After GA |

### Rollback Plan

If issues are discovered:

1. [Immediate action]
2. [Communication plan]
3. [Technical rollback steps]
4. [Post-mortem process]

---

## 7. Testing Strategy

### Unit Tests

| Component | Test Coverage | Key Scenarios |
|-----------|---------------|---------------|
| [Component 1] | [Target %] | [Scenarios to cover] |
| [Component 2] | [Target %] | [Scenarios to cover] |

### Integration Tests

[Integration test approach and scenarios]

### Performance Tests

| Metric | Current | Target | Test Method |
|--------|---------|--------|-------------|
| Latency (p99) | [Value] | [Target] | [Method] |
| Throughput | [Value] | [Target] | [Method] |

### Manual Testing

- [ ] [Scenario 1]
- [ ] [Scenario 2]
- [ ] [Scenario 3]

### Acceptance Criteria

- [ ] All unit tests pass
- [ ] Integration tests pass
- [ ] Performance meets targets
- [ ] Documentation is complete
- [ ] No critical bugs in beta period

---

## 8. Security Considerations

### Threat Model

| Threat | Risk Level | Mitigation |
|--------|------------|------------|
| [Threat 1] | High/Med/Low | [Mitigation] |
| [Threat 2] | High/Med/Low | [Mitigation] |

### Authentication/Authorization

[Changes to auth model, new permissions, etc.]

### Data Handling

| Data Type | Classification | Handling |
|-----------|----------------|----------|
| [Data 1] | PII/Sensitive/Public | [How it's protected] |

### Audit Trail

[Audit logging requirements and implementation]

### Compliance

[Relevant compliance requirements: SOC2, GDPR, HIPAA, etc.]

---

## 9. Abandoned Ideas

> Document ideas that were considered but rejected. This preserves reasoning for future readers.

### [Abandoned Idea 1]

**Description:**
[What was proposed]

**Why Abandoned:**
[Reason it was rejected - technical, business, timing, etc.]

**Discussion:**
[Link to relevant discussion thread]

### [Abandoned Idea 2]

[Same structure]

---

## 10. Open Questions

| # | Question | Context | Options | Owner | Status |
|---|----------|---------|---------|-------|--------|
| 1 | [Question] | [Why it matters] | [A, B, C] | [Name] | Open/Resolved |
| 2 | [Question] | [Why it matters] | [A, B, C] | [Name] | Open/Resolved |

---

## 11. References

- [PRD: Problem Requirements Document](link)
- [Related RFC](link)
- [External Documentation](link)
- [Research/Papers](link)

---

## Appendix

### A. Detailed Technical Specifications

[Deep technical details that would clutter the main document]

### B. Benchmarks and Performance Data

[Raw performance data, graphs, comparison tables]

### C. Glossary

| Term | Definition |
|------|------------|
| [Term 1] | [Definition] |
| [Term 2] | [Definition] |

---

## Change History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1 | [Date] | [Name] | Initial draft |
| 0.2 | [Date] | [Name] | Incorporated feedback from [reviewer] |
| 1.0 | [Date] | [Name] | Approved version |

---

## Approval

| Role | Name | Status | Date | Comments |
|------|------|--------|------|----------|
| Owner | [Name] | [ ] Approved | | |
| Tech Lead | [Name] | [ ] Approved | | |
| Security | [Name] | [ ] Approved | | |
| [Stakeholder] | [Name] | [ ] Approved | | |

---

## Source

Based on HashiCorp's RFC template from [How HashiCorp Works](https://works.hashicorp.com/articles/rfc-template).
