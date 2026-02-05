# Zig Team Review Checklist Reference

Quick reference checklist for Zig code review.

## Critical Issues (Must Fix)

### Memory Safety
| Check | Pattern | Fix |
|-------|---------|-----|
| Use after free | Using pointer/slice after `free()` | Don't store references across free |
| Double free | Calling `free()` twice | Track ownership, use `defer` |
| Dangling slice | Slice from ArrayList after append | Get fresh slice after mutations |
| Missing defer | Resource acquired without `defer close/deinit` | Add `defer` immediately after acquire |
| Missing errdefer | Allocation without `errdefer free` | Add `errdefer` for error-path cleanup |

### Error Handling
| Check | Pattern | Fix |
|-------|---------|-----|
| Silent swallow | `catch {}` or `catch \|_\| {}` | Handle error or propagate with `try` |
| Wrong return type | `try` in non-error function | Return `!T` instead of `T` |
| Unreachable reached | `unreachable` in reachable code | Add proper error handling |

### Undefined Behavior
| Check | Pattern | Fix |
|-------|---------|-----|
| Integer overflow | Arithmetic without overflow check | Use `@addWithOverflow` etc. |
| Uninitialized read | Read from `= undefined` before write | Initialize or `@memset` first |
| Null unwrap | `optional.?` without check | Use `if (opt) \|val\|` pattern |
| Out of bounds | `slice[i]` without bounds check | Check `i < slice.len` first |

## Major Issues (Should Fix)

### Allocator Usage
| Check | Pattern | Fix |
|-------|---------|-----|
| Wrong allocator free | Free with different allocator | Store and use same allocator |
| Missing allocator field | Can't deinit without allocator | Store allocator in struct |
| Testing allocator | Using page_allocator in tests | Use `std.testing.allocator` |

### API Design
| Check | Pattern | Fix |
|-------|---------|-----|
| Unused parameter | `_ = allocator;` | Remove or use parameter |
| Stack return | Returning pointer to local | Allocate or take buffer parameter |
| Hidden allocation | Allocating without allocator param | Accept allocator parameter |

## Minor Issues (Consider)

### Style
| Check | Convention |
|-------|------------|
| Type names | PascalCase: `MyStruct` |
| Variables/functions | snake_case: `my_var`, `my_func` |
| Comptime constants | SCREAMING_SNAKE: `MY_CONST` |
| Public functions | camelCase OK: `myPublicFn` |

### Documentation
| Check | Pattern |
|-------|---------|
| Public API | `///` doc comment |
| Complex logic | Inline `//` comments |
| Error conditions | Document what errors are returned |

## Testing Checklist

- [ ] Using `std.testing.allocator` (detects leaks)
- [ ] Testing error cases with `expectError`
- [ ] Testing edge cases (empty, max, null)
- [ ] No timing-dependent assertions
- [ ] Tests are deterministic

## Quick Decision Tree

```
Issue found?
├── Is it memory safety or undefined behavior?
│   └── CRITICAL - must fix before merge
├── Is it error handling or allocator misuse?
│   └── MAJOR - fix unless justified
├── Is it missing test or wrong pattern?
│   └── MAJOR - fix to prevent regression
└── Is it style or documentation?
    └── MINOR - suggest, don't block
```

## Review Output Templates

### Critical Finding
```yaml
- issue: "Missing errdefer for allocation"
  location: "src/parser.zig:45"
  category: "resource_leak"
  severity: critical
  fix: "Add `errdefer allocator.free(buffer);` after allocation"
```

### Major Finding
```yaml
- issue: "Error silently swallowed"
  location: "src/parser.zig:78"
  category: "error_handling"
  severity: major
  fix: "Replace `catch {}` with `catch |err| return err`"
```

### Minor Finding
```yaml
- issue: "Missing doc comment on public function"
  location: "src/parser.zig:12"
  severity: minor
  suggestion: "Add `///` doc comment describing function behavior"
```
