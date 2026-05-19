# PRD Best Practices

Industry best practices for writing effective Product Requirements Documents.

## The SMART Principle

All requirements and acceptance criteria should follow SMART:

| Principle | Description | Bad Example | Good Example |
|-----------|-------------|-------------|--------------|
| **S**pecific | Clear and unambiguous | "Fast loading" | "Page loads in < 2 seconds" |
| **M**easurable | Can verify completion | "Good UX" | "Task completion rate > 90%" |
| **A**chievable | Technically feasible | "100% uptime" | "99.9% uptime SLA" |
| **R**elevant | Addresses real need | "Add animations" | "Visual feedback on actions" |
| **T**ime-bound | Clear completion state | "Eventually" | "By end of Q2" |

## Problem-First Thinking

### Why It Matters

Teams that start with solutions often:
- Build features users don't need
- Miss the actual underlying problem
- Create biased engineering designs
- Waste resources on wrong priorities

### Problem Discovery Process

```
1. OBSERVE
   - Watch users work
   - Read support tickets
   - Analyze usage data

2. INTERVIEW
   - Ask "why" 5 times
   - Listen more than talk
   - Avoid leading questions

3. SYNTHESIZE
   - Identify patterns
   - Group by persona
   - Prioritize by impact

4. VALIDATE
   - Share findings with users
   - Test assumptions
   - Refine understanding
```

### Good vs Bad Problem Statements

**Bad** (Solution-disguised-as-problem):
> "Users need a dashboard to see their metrics"

**Good** (Actual problem):
> "Users spend 30+ minutes daily gathering metrics from 5 different tools, leading to delayed decisions and inconsistent data"

**Bad** (Vague):
> "The onboarding experience is confusing"

**Good** (Specific and researched):
> "68% of new users abandon setup at the API key configuration step. User interviews reveal they don't understand where to find their API key or why it's required."

## User Research Methods

### Qualitative Methods

| Method | Best For | Sample Size |
|--------|----------|-------------|
| User interviews | Deep understanding | 5-15 users |
| Contextual inquiry | Workflow observation | 3-8 users |
| Usability testing | Identifying friction | 5-10 users |
| Focus groups | Exploring concepts | 6-10 per group |

### Quantitative Methods

| Method | Best For | Sample Size |
|--------|----------|-------------|
| Surveys | Validation at scale | 100+ users |
| Analytics | Behavior patterns | All users |
| A/B testing | Comparing solutions | Statistically significant |
| Support ticket analysis | Common issues | 50+ tickets |

### Interview Tips

**Do:**
- Ask open-ended questions
- Follow up with "tell me more"
- Ask about specific recent experiences
- Listen for emotion and frustration

**Don't:**
- Ask "would you use feature X?"
- Lead with your assumptions
- Interrupt or finish their sentences
- Only talk to power users

## Writing Acceptance Criteria

### Given/When/Then Format

This format creates testable, unambiguous criteria:

```gherkin
Given [precondition/context]
When [action/trigger]
Then [expected outcome]
```

**Examples:**

```gherkin
# User authentication
Given a user with valid credentials
When they submit the login form
Then they are redirected to the dashboard
And a session cookie is set with 24-hour expiry

# Error handling
Given a user with an expired password
When they attempt to login
Then they see error message "Password expired"
And they are prompted to reset their password

# Edge case
Given a user who has exceeded rate limits
When they make another API request
Then they receive a 429 status code
And the response includes retry-after header
```

### Acceptance Criteria Checklist

For each requirement, verify:

- [ ] **Happy path**: Normal successful scenario
- [ ] **Error cases**: What happens when things go wrong
- [ ] **Edge cases**: Boundary conditions, empty states
- [ ] **Permissions**: Who can/cannot perform this action
- [ ] **Performance**: Response time, throughput requirements
- [ ] **Accessibility**: Screen readers, keyboard navigation

## Stakeholder Management

### RACI Matrix

Define roles for PRD decisions:

| Decision | Responsible | Accountable | Consulted | Informed |
|----------|-------------|-------------|-----------|----------|
| Problem definition | PM | PM | Users, Support | Engineering |
| Requirements | PM | PM | Engineering, Design | QA |
| Technical approach | Engineering | Engineering | PM | Design |
| Timeline | PM + Eng | PM | Leadership | All |

### Getting Effective Feedback

**Before review:**
- Share context and goals
- Specify what feedback you need
- Set a deadline for responses

**During review:**
- Ask specific questions
- Focus on problems, not solutions
- Document all feedback

**After review:**
- Summarize decisions made
- Explain what changed (and why)
- Thank contributors

## Common PRD Anti-Patterns

### 1. The Novel

**Problem**: 50+ page document no one reads
**Solution**: Keep PRDs concise. Link to appendices for details.

### 2. The Wishlist

**Problem**: Everything is high priority
**Solution**: Force-rank requirements. Use MoSCoW (Must/Should/Could/Won't).

### 3. The Solution Spec

**Problem**: Dictates implementation details
**Solution**: Focus on WHAT and WHY, let engineering determine HOW.

### 4. The Assumption Document

**Problem**: No user research backing claims
**Solution**: Every problem statement needs evidence.

### 5. The Static Document

**Problem**: Written once, never updated
**Solution**: Treat PRD as living document. Version and track changes.

### 6. The Premature PRD

**Problem**: Writing PRD before understanding problem
**Solution**: Complete discovery phase before PRD writing.

## PRD vs Other Documents

| Document | Purpose | When to Use |
|----------|---------|-------------|
| **PRD** | Define problem and requirements | Before solution design |
| **RFC** | Propose technical solution | After PRD approval |
| **Design Doc** | Detail visual/UX approach | After PRD, parallel to RFC |
| **Tech Spec** | Implementation details | After RFC approval |
| **User Story** | Agile work item | Derived from PRD requirements |

## Metrics That Matter

### Leading Indicators

Predict future success:
- Feature adoption rate
- Time to first value
- User engagement frequency
- Task completion rate

### Lagging Indicators

Confirm past success:
- Customer satisfaction (NPS/CSAT)
- Retention rate
- Support ticket volume
- Revenue impact

### Defining Good Metrics

```markdown
## Metric Definition Template

**Metric Name**: [Name]

**Definition**: [Precise definition of what is measured]

**Formula**: [How to calculate]

**Data Source**: [Where data comes from]

**Baseline**: [Current value]

**Target**: [Goal value]

**Measurement Frequency**: [Daily/Weekly/Monthly]

**Owner**: [Who tracks this]
```

## References

### Templates and Tools

- [Notion PRD Templates](https://www.notion.com/templates/category/product-requirements-doc)
- [Aha! PRD Guide](https://www.aha.io/roadmapping/guide/requirements-management/what-is-a-good-product-requirements-document-template)
- [ClickUp PRD Templates](https://clickup.com/blog/product-requirements-document-templates/)
- [GitHub Opulo PRD Template](https://github.com/opulo-inc/prd-template)

### Guides and Articles

- [Product School PRD Guide](https://productschool.com/blog/product-strategy/product-template-requirements-document-prd)
- [Atlassian Agile Requirements](https://www.atlassian.com/agile/product-management/requirements)
- [Perforce PRD Writing Guide](https://www.perforce.com/blog/alm/how-write-product-requirements-document-prd)
- [Formlabs PRD Best Practices](https://formlabs.com/blog/product-requirements-document-prd-with-template/)
- [AltexSoft PRD Examples](https://www.altexsoft.com/blog/product-requirements-document/)
- [Chisel Labs PRD Templates 2025](https://chisellabs.com/blog/product-requirement-document-prd-templates/)

### Books

- "Inspired" by Marty Cagan
- "Escaping the Build Trap" by Melissa Perri
- "User Story Mapping" by Jeff Patton
