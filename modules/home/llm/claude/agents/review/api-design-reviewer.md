---
name: api-design-reviewer
description: Reviews API design for consistency, usability, and adherence to REST/RPC best practices.
---

# API Design Reviewer

## Purpose

Ensures API endpoints follow design best practices, are consistent, and provide good developer experience.

## Dispatch Prompt

```
Review API design for the following endpoints.

Endpoints to review:
[List endpoints with methods]

Context:
- API style: [REST/GraphQL/gRPC]
- Existing patterns: [Brief description of current API style]

Check:
1. **Naming & URLs**
   - RESTful resource naming?
   - Consistent pluralization?
   - Proper HTTP methods?
   - Meaningful path segments?

2. **Request/Response Design**
   - Consistent structure?
   - Proper status codes?
   - Clear error responses?
   - Pagination for lists?

3. **Versioning**
   - Version strategy clear?
   - Breaking changes handled?

4. **Documentation**
   - OpenAPI/Swagger spec?
   - Examples provided?
   - Error codes documented?

5. **Consistency**
   - Matches existing API patterns?
   - Field naming consistent?
   - Date/time formats standard?

Output format:
## Design Issues
- [Endpoint]: [Issue]
  - Current: [What it is]
  - Suggested: [What it should be]

## Breaking Changes
- [Change]: [Impact]

## Verdict
PASS / NEEDS_CHANGES / BLOCKED
```

## When to Use

- New API endpoints
- API modifications
- Before API publication
- API versioning decisions
