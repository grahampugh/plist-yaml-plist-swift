# plist-yaml-plist (Swift)

A Swift implementation of the plist-yaml-plist conversion tool. Converts between Apple plist, YAML, and JSON formats with special optimizations for AutoPkg recipes.

## Features

- **Bidirectional conversion**: plist ↔ YAML, JSON → plist
- **AutoPkg recipe optimization**: Automatic formatting and key ordering for AutoPkg recipes
- **Batch processing**: Convert entire directories with glob patterns
- **Smart path handling**: Recognizes YAML/_YAML and JSON/_JSON folder conventions
- **Native performance**: Leverages Swift and Foundation for fast, native macOS performance

## Requirements

- macOS 15.0 or later
- Swift 6.0 or later (for building from source)

## Installation

### Building from Source

```bash
git clone https://github.com/grahampugh/plist-yaml-plist-swift.git
cd plist-yaml-plist-swift
swift build -c release
cp .build/release/plistyamlplist /usr/local/bin/
```

## Usage

### Basic Conversion

```bash
# Convert plist to YAML
plistyamlplist file.plist [output.yaml]

# Convert YAML to plist
plistyamlplist file.yaml [output.plist]

# Convert JSON to plist
plistyamlplist file.json [output.plist]
```

If the output file is omitted:
- `.plist` files → adds `.yaml` extension
- `.yaml` files → removes `.yaml` extension
- `.json` files → removes `.json` extension

### AutoPkg Recipe Formatting

```bash
# Tidy a YAML recipe in-place
plistyamlplist recipe.yaml --tidy

# Tidy all recipes in a folder
plistyamlplist /path/to/YAML/ --tidy
```

### Batch Conversion

```bash
# Convert all YAML files in a directory
plistyamlplist '/path/to/*.yaml'

# Convert entire folder structure
plistyamlplist /path/to/YAML/ /path/to/output/
```

### YAML/JSON Folder Convention

If your path contains `YAML` or `_YAML` (or `JSON`/`_JSON`), the tool automatically determines output paths:

- Input: `/project/YAML/subfolder/file.yaml`
- Output: `/project/subfolder/file.plist` (if `/project/subfolder` exists)

## AutoPkg Recipe Optimization

When converting AutoPkg recipes (files ending in `.recipe`, `.recipe.plist`, or `.recipe.yaml`), the tool automatically:

1. **Orders top-level keys**: Comment → Description → Identifier → ParentRecipe → MinimumVersion → Input → Process → ParentRecipeTrustInfo
2. **Orders Process entries**: Processor key first, then Comment, then Arguments
3. **Orders Input dictionary**: NAME key always first
4. **Adds blank lines**: Before Input, Process, each Processor, and ParentRecipeTrustInfo for readability

## Comparison with Python Version

This Swift implementation provides:
- ✅ Full CLI compatibility with the Python version
- ✅ All AutoPkg recipe optimizations
- ✅ Native binary plist support (no `plutil` command needed)
- ✅ Faster performance for batch operations
- ✅ Same folder convention handling
- ⚠️ Requires macOS 15+ (Python version supports older macOS)

## Credits

Swift port by Graham Pugh, based on the original Python implementation:
- [grahampugh/plist-yaml-plist](https://github.com/grahampugh/plist-yaml-plist)

## License

Apache License 2.0 - See LICENSE file for details
