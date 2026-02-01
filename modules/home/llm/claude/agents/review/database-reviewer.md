---
name: database-reviewer
description: Reviews database operations for performance, safety, and proper patterns.
---

# Database Reviewer

## Purpose

Ensures database operations are efficient, safe from injection, and follow proper data access patterns.

## Dispatch Prompt

```
Review database operations in the following code.

Files to review:
[List files with DB operations]

Context:
- Database: [PostgreSQL/MySQL/SQLite/etc]
- ORM/Driver: [sqlx/gorm/prisma/etc]

Check:
1. **Query Safety**
   - Parameterized queries used?
   - No SQL injection risks?
   - Proper escaping?

2. **Performance**
   - Indexes utilized?
   - N+1 query problems?
   - Unnecessary data fetched?
   - Pagination implemented?

3. **Transaction Safety**
   - Transactions where needed?
   - Proper rollback on error?
   - Deadlock prevention?

4. **Schema Design**
   - Proper normalization?
   - Foreign keys defined?
   - Appropriate data types?

5. **Migrations**
   - Reversible migrations?
   - Data integrity preserved?
   - Safe for production?

Output format:
## Security Issues
- [File:Line]: [SQL injection risk or unsafe operation]

## Performance Issues
- [File:Line]: [Issue]
  - Impact: [What this causes]
  - Fix: [How to optimize]

## Transaction Issues
- [Issue]: [Details]

## Verdict
PASS / NEEDS_CHANGES / BLOCKED
```

## When to Use

- New database queries
- Schema changes
- Performance optimization
- Security audits
