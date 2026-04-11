# IconKit
[![macOS](https://img.shields.io/badge/Platform-macOS_13+-blue.svg)](https://developer.apple.com/xcode/)
[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![Release](https://img.shields.io/github/v/release/rozd/icon-kit)](https://github.com/rozd/icon-kit/releases)
[![codecov](https://codecov.io/gh/rozd/icon-kit/branch/main/graph/badge.svg)](https://codecov.io/gh/rozd/icon-kit)
[![License](https://img.shields.io/github/license/rozd/icon-kit)](LICENSE)

**A Swift library and CLI for working with Apple `.icon` bundles.**

IconKit reads and writes the `.icon` bundle format introduced with Icon Composer — Apple's structured icon format containing multiple image layers (front, middle, back) at various sizes, enabling dynamic rendering effects like parallax and lighting. Use it to add environment ribbons to existing icons, manipulate layers programmatically, or validate round-trip fidelity.

---

## ✨ Features

- 🎀 **Ribbon Overlays** — stamp UAT / QA / Staging labels onto any `.icon` bundle in one command. Configurable placement, colors, font, and size.
- 📦 **Round-Trip Safe** — read an `.icon` bundle, inspect or modify it, write it back out without data loss.
- 🧩 **Full Document Model** — typed Swift structs for every part of the `.icon` format: groups, layers, fills, shadows, blend modes, specializations, and platform targeting.
- 🎨 **Appearance & Idiom Variants** — first-class support for light/dark/tinted appearances and per-platform (iOS, macOS, watchOS, visionOS) specializations.
- 🖥️ **CLI + Library** — use the `iconkit` command-line tool directly, or embed the `IconKit` library in your own Swift code.

## 🚀 CLI Usage

### Install

#### Homebrew

```bash
brew tap rozd/tap
brew install iconkit
```

#### Build from source

```bash
swift build -c release
# Binary is at .build/release/iconkit
```

### Add a ribbon

Stamp an environment label onto an existing `.icon` bundle:

```bash
iconkit ribbon top \
  --text "UAT" \
  --input AppIcon.icon \
  --output AppIcon.uat.icon
```

Customize the appearance:

```bash
iconkit ribbon topLeft \
  --text "DEV" \
  --input AppIcon.icon \
  --output AppIcon.dev.icon \
  --background "#4A90D9" \
  --foreground "#FFFFFF" \
  --size 0.3 \
  --font-scale 0.5
```

<details>
<summary>Ribbon options</summary>

| Option | Default | Description |
|--------|---------|-------------|
| `<placement>` | — | `top`, `bottom`, `topLeft`, or `topRight` |
| `--text` | — | Text to render on the ribbon |
| `--size` | `0.24` | Ribbon height as a factor of icon height (0.0–1.0) |
| `--offset` | `0.0` | Offset from edge as a factor of icon height |
| `--background` | `#B92636` | Ribbon background color (hex) |
| `--foreground` | `#FEFAFA` | Text color (hex) |
| `--font` | System | Font family name |
| `--font-scale` | `0.6` | Text size as a factor of ribbon height |

</details>

### Validate round-trip fidelity

Read a bundle and write it back to verify nothing is lost:

```bash
iconkit test --input AppIcon.icon --output AppIcon.copy.icon
```

## 📦 Integration

### Swift Package Manager

Add IconKit as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/rozd/icon-kit", from: "0.1.0")
]
```

Then add the product to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "IconKit", package: "icon-kit")
    ]
)
```

## 🛠️ Library Usage

### Read and inspect a bundle

```swift
import IconKit

let icon = try IconComposerDescriptorFile(contentsOf: bundleURL)
print("Groups: \(icon.document.groups.count)")
print("Assets: \(icon.assets.count)")

// Check for missing referenced assets
let warnings = icon.validateAssets()
```

### Add a ribbon overlay

```swift
var icon = try IconComposerDescriptorFile(contentsOf: bundleURL)

let style = RibbonStyle(
    text: "UAT",
    size: 0.24,
    offset: 0.0,
    background: try parseHexColor("#B92636"),
    foreground: try parseHexColor("#FEFAFA"),
    fontScale: 0.6
)

try icon.applyRibbon(placement: .top, style: style)
try icon.write(to: outputURL)
```

### Work with layers and specializations

```swift
// Access layers
for group in icon.document.groups {
    for layer in group.layers {
        print(layer.name ?? "unnamed", layer.imageName ?? "no image")
    }
}

// Resolve a specialization for dark mode on iOS
let fill = resolveSpecialization(
    base: layer.fill,
    specializations: layer.fillSpecializations ?? [],
    appearance: .dark,
    idiom: .iOS
)
```

## ⚙️ How It Works

An `.icon` bundle is a directory containing:

```
AppIcon.icon/
├── icon.json          # Document descriptor (groups, layers, fills, effects)
└── Assets/
    ├── Background.svg
    ├── Foreground.png
    └── ...
```

IconKit models the full `icon.json` structure as typed Swift structs — `IconDocument`, `IconGroup`, `IconLayer`, and supporting types like `IconFill`, `IconShadow`, `IconBlendMode`, and `Specialization<T>`. Every field round-trips cleanly through `Codable`.

The ribbon feature works by generating a transparent PNG overlay and inserting it as the front-most layer (group index 0), with liquid glass automatically disabled to ensure opaque, true colors.
