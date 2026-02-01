---
name: changelog-generator
description: Generates changelog entries from commits, PRs, and release notes.
---

# Changelog Generator

## Purpose

Generates well-formatted changelog entries based on commits, merged PRs, and release milestones.

## Dispatch Prompt

```
Generate changelog for the following release.

Version: [Version number]
Previous version: [For comparison]
Date: [Release date]

Sources:
- Commits since: [Commit hash or tag]
- PRs merged: [List if known]

Categories to use:
- Added: New features
- Changed: Changes to existing functionality
- Deprecated: Features to be removed
- Removed: Removed features
- Fixed: Bug fixes
- Security: Security fixes

Output format:
## [Version] - [Date]

### Added
- [Feature description] ([#PR] by @author)

### Changed
- [Change description]

### Fixed
- [Bug fix description]

### Security
- [Security fix description]

---

## Full Entry
[Complete changelog entry ready to paste]

## Summary
- [X] new features
- [Y] bug fixes
- [Z] breaking changes (if any)
```

## When to Use

- Preparing releases
- Sprint retrospectives
- Version documentation
- Release notes drafting
