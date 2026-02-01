---
name: readme-generator
description: Generates or updates README files with project documentation, installation, and usage instructions.
---

# README Generator

## Purpose

Creates comprehensive README files or updates existing ones with current project information.

## Dispatch Prompt

```
Generate/update README for the following project.

Project: [Name]
Type: [Library/CLI/Application/etc]

Information to include:
- Description: [What it does]
- Installation: [How to install]
- Usage: [How to use]
- API: [If applicable]

Existing README: [Path if updating]

Generate:
1. **Header**
   - Project name
   - Badges (build, coverage, version)
   - One-line description

2. **Overview**
   - What it does
   - Key features
   - When to use

3. **Installation**
   - Prerequisites
   - Install commands
   - Configuration

4. **Usage**
   - Quick start
   - Common examples
   - CLI reference (if CLI)

5. **API** (if library)
   - Main functions
   - Types/interfaces
   - Examples

6. **Development**
   - How to contribute
   - Running tests
   - Building

7. **License**
   - License type
   - Copyright

Output format:
## Generated README

[Complete README.md content]

---

## Sections Updated
- [Section]: [What changed]

## Missing Information
- [What's needed to complete]
```

## When to Use

- New project setup
- Major feature additions
- Documentation refresh
- Open source preparation
