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
sudo cp .build/release/plistyamlplist /usr/local/bin/
```

### Installing via Homebrew (Coming Soon)

```bash
brew install plistyamlplist
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
# Convert all YAML files matching a pattern (note the quotes)
plistyamlplist '/path/to/*.yaml'

# Convert entire folder structure
plistyamlplist /path/to/YAML/ /path/to/output/

# Tidy all recipes in a folder recursively
plistyamlplist /path/to/YAML/ --tidy
```

Note: When using glob patterns from the command line, wrap the pattern in quotes to prevent shell expansion.

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
- ✅ Same folder convention handling (YAML/_YAML, JSON/_JSON)
- ✅ Glob pattern support for batch conversion
- ⚠️ Requires macOS 15+ (Python version supports older macOS)

## Implementation Status

### Complete ✅
- Single file conversion (plist ↔ YAML, JSON → plist)
- Batch conversion with glob patterns
- Directory recursion with structure replication  
- AutoPkg recipe detection and optimization
- YAML/_YAML and JSON/_JSON folder conventions
- --tidy flag for recipe reformatting
- Binary and XML plist support

### In Testing
- Complex AutoPkg recipe formatting edge cases
- Large-scale batch operations
- Cross-platform compatibility (macOS 15+ only)

## Examples

### Basic Usage

```bash
# Simple conversion
$ plistyamlplist com.example.plist
plist-yaml-plist version 1.0.0
Processing plist file...
Wrote to: com.example.plist.yaml

# Reverse conversion
$ plistyamlplist com.example.plist.yaml
plist-yaml-plist version 1.0.0
Processing yaml file...
Written to com.example.plist
```

### YAML Folder Convention

```bash
# Input file in YAML subfolder
$ plistyamlplist /Users/admin/recipes/YAML/Chrome.recipe.yaml
YAML folder exists: /Users/admin/recipes/YAML/Chrome.recipe.yaml
Path exists: /Users/admin/recipes
Wrote to: /Users/admin/recipes/Chrome.recipe

# The tool automatically maps YAML/subfolder → subfolder
```

### Batch Operations

```bash
# Convert all plist files in a directory to YAML
$ plistyamlplist '/tmp/plists/*.plist'
plist-yaml-plist version 1.0.0
Processing 15 file(s)...
Wrote to: /tmp/plists/file1.plist.yaml
Wrote to: /tmp/plists/file2.plist.yaml
...
```

### AutoPkg Recipe Tidying

```bash
# Tidy a single recipe
$ plistyamlplist MyRecipe.recipe.yaml --tidy
Wrote to: MyRecipe.recipe.yaml

# Tidy all recipes in a folder
$ plistyamlplist /path/to/YAML/ --tidy
WARNING! Processing all subfolders...

Processed 47 file(s)
```

## Credits

Swift port by Graham Pugh, based on the original Python implementation:
- [grahampugh/plist-yaml-plist](https://github.com/grahampugh/plist-yaml-plist)

## License

Apache License 2.0 - See LICENSE file for details
