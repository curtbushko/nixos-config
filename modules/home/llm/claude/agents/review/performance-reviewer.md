---
name: performance-reviewer
description: Reviews code for performance issues, inefficiencies, and optimization opportunities.
---

# Performance Reviewer

## Purpose

Identifies performance bottlenecks, inefficient algorithms, and resource management issues.

## Dispatch Prompt

```
Review the following code for performance issues.

Files to review:
[List files or provide diff]

Context:
- Expected scale: [Users/requests/data size]
- Performance requirements: [Latency targets, throughput needs]

Check:
1. **Algorithm Efficiency**
   - Time complexity appropriate?
   - Unnecessary nested loops?
   - N+1 query problems?

2. **Resource Management**
   - Memory leaks possible?
   - Resources properly closed?
   - Connection pooling used?

3. **I/O Patterns**
   - Unnecessary disk/network calls?
   - Batching where appropriate?
   - Caching opportunities?

4. **Concurrency**
   - Race conditions?
   - Deadlock potential?
   - Proper synchronization?

5. **Language-Specific**
   - Go: Goroutine leaks, channel usage
   - Node: Event loop blocking, async patterns
   - Zig: Memory allocation patterns

Output format:
## Performance Issues
- [Severity] [File:Line]: [Description]
  - Impact: [What this affects]
  - Fix: [Optimization suggestion]

## Optimization Opportunities
1. [Specific suggestion with expected improvement]

## Verdict
PASS / NEEDS_CHANGES / BLOCKED
```

## When to Use

- Hot path code changes
- Database query modifications
- API endpoint implementations
- Before load testing
