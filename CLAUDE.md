# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

IconKit is a Swift library and CLI tool (Swift Package) for working with Apple's `.icon` bundle format (introduced with Icon Composer). Key use cases:

1. Add environment ribbons (UAT/QA/etc) to existing icon files
2. Generate `.icon` files from SF Symbols or other font symbols
3. Generate `.icon` files from SVG/PDF sources with color settings

## Build & Test Commands

```bash
# Build the library and CLI
swift build

# Build release
swift build -c release

# Run tests
swift test

# Run a single test
swift test --filter <TestClassName>/<testMethodName>

# Run the CLI during development
swift run iconkit <subcommand> [options]
```

## Architecture

This is a Swift Package with two targets:

- **IconKit** — the core library containing icon generation, manipulation, and `.icon` bundle I/O logic
- **iconkit** (lowercase) — the CLI executable that exposes the library's capabilities as command-line subcommands

The `.icon` bundle is Apple's structured icon format that contains multiple image layers (front, middle, back) at various sizes, enabling dynamic rendering effects like parallax and lighting.
