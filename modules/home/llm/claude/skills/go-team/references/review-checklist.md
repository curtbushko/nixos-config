# Go Team Review Checklist Reference

This checklist is injected into the Go Reviewer agent templates.

## Critical Issues (Must Fix)

### Error Handling
| Check | Mistake # | Pattern |
|-------|-----------|---------|
| Errors not ignored | #53 | `if err != nil { return err }` |
| Errors wrapped with context | #49 | `fmt.Errorf("op failed: %w", err)` |
| errors.Is for sentinel comparison | #51 | `errors.Is(err, ErrNotFound)` |
| errors.As for type comparison | #50 | `errors.As(err, &customErr)` |
| Handle once (log OR return) | #52 | Don't log then return |

### Concurrency
| Check | Mistake # | Pattern |
|-------|-----------|---------|
| No data races | #58 | Use `-race` flag |
| Mutex scope covers operation | #70 | Lock check+modify together |
| No sync type copying | #74 | Pass pointers to mutexes |
| Goroutines have stop mechanism | #62 | Context cancel or stop channel |
| Loop vars captured correctly | #63 | Pass as param: `go func(i int) {}(i)` |

### Resource Management
| Check | Mistake # | Pattern |
|-------|-----------|---------|
| Resources closed with defer | #79 | `defer file.Close()` |
| No defer in loops | #35 | Extract to helper function |
| time.After not leaking | #76 | Use NewTimer + defer Stop() |
| Slice capacity managed | #26 | Nil excluded elements |

## Major Issues (Should Fix)

### Architecture
| Check | Pattern |
|-------|---------|
| Code in correct layer | domain/ports/services/adapters |
| Domain has no external imports | Only stdlib allowed |
| Dependencies flow inward | handlers -> services -> domain |
| Interfaces defined at consumer | Not at implementation |

### Interface Design
| Check | Mistake # | Pattern |
|-------|-----------|---------|
| Interfaces small | #5 | 1-3 methods ideal |
| Consumer-side interfaces | #6 | Define where used |
| Return concrete types | #7 | Not interfaces |
| No premature interfaces | #5 | Discover, don't create |

### Testing
| Check | Mistake # | Pattern |
|-------|-----------|---------|
| TDD followed | - | Test written before code |
| Table-driven tests | #85 | `[]struct{name, input, want}` |
| No sleep in tests | #86 | Use channels/sync primitives |
| Race flag compatible | #83 | `go test -race` passes |
| Meaningful test names | - | Describe behavior |

## Minor Issues (Consider)

### Naming & Style
| Check | Pattern |
|-------|---------|
| No Get prefix | Use `Owner()` not `GetOwner()` |
| Package names short | Single lowercase word |
| Function names simple | No edge cases in name |
| No utility packages | No `common`, `util`, `shared` |

### Performance
| Check | Mistake # | Pattern |
|-------|-----------|---------|
| Slices preallocated | #21 | `make([]T, 0, size)` |
| Maps preallocated | #27 | `make(map[K]V, size)` |
| strings.Builder in loops | #39 | Not `+=` |
| Minimal allocations | #97 | Consider sync.Pool |

## Quick Decision Tree

```
Error found?
├── Is it a data race or resource leak?
│   └── CRITICAL - must fix before merge
├── Is it architecture violation?
│   └── MAJOR - fix unless justified
├── Is it missing test or wrong pattern?
│   └── MAJOR - fix to prevent regression
└── Is it style or minor optimization?
    └── MINOR - suggest, don't block
```

## Review Output Templates

### Critical Finding
```yaml
- issue: "Error ignored on Close()"
  location: "internal/adapters/repo.go:45"
  mistake_ref: "#53"
  severity: critical
  fix: "Capture error: `if err := f.Close(); err != nil { return fmt.Errorf(...) }`"
```

### Major Finding
```yaml
- issue: "Interface defined at implementation"
  location: "internal/adapters/postgres/user.go:12"
  mistake_ref: "#6"
  severity: major
  fix: "Move interface to internal/core/ports/repositories.go"
```

### Minor Finding
```yaml
- issue: "Slice could be preallocated"
  location: "internal/core/services/user.go:78"
  mistake_ref: "#21"
  severity: minor
  suggestion: "Use make([]User, 0, len(ids)) to reduce allocations"
```
