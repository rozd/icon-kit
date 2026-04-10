# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

IconKit is a Swift library and CLI tool (Swift Package) for working with Apple's `.icon` bundle format (introduced with Icon Composer). Key use cases:

1. Add environment ribbons (UAT/QA/etc) to existing icon files
2. Generate `.icon` files from SF Symbols or other font symbols
3. Generate `.icon` files from SVG/PDF sources with color settings

## Build & Test Commands

```bash
swift build                  # Build library and CLI
swift build -c release       # Release build
swift test                   # Run all tests
swift test --filter IconKitTests/testName  # Run a single test
swift run iconkit <subcommand> [options]   # Run CLI during development
```

## Architecture

Swift Package with two products and three targets:

| Product | Target | Type | Description |
|---------|--------|------|-------------|
| `IconKit` | `IconKit` | Library | Core library — icon generation, manipulation, `.icon` bundle I/O |
| `iconkit` | `IconKitCLI` | Executable | CLI tool built with swift-argument-parser |

- **Repo/package**: `icon-kit` / `IconKit`
- **SPM dependency usage**: `.product(name: "IconKit", package: "icon-kit")`
- The CLI product name (`iconkit`) differs from its target name (`IconKitCLI`) to avoid case-only collision with the library target on case-insensitive filesystems.

The `.icon` bundle is Apple's structured icon format containing multiple image layers (front, middle, back) at various sizes, enabling dynamic rendering effects like parallax and lighting.
