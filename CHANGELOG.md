# Changelog

All notable changes to plist-yaml-plist (Swift) will be documented in this file.

## [1.0.0] - 2026-03-26

### Added
- Initial Swift implementation of plist-yaml-plist
- Full plist ↔ YAML bidirectional conversion
- JSON → plist conversion with null value cleaning
- Native binary and XML plist support via PropertyListSerialization
- AutoPkg recipe detection by filename and content
- AutoPkg recipe optimization:
  - Top-level key ordering (Comment → Description → Identifier → ParentRecipe → MinimumVersion → Input → Process → ParentRecipeTrustInfo)
  - Process array ordering (Processor first, Comment second, Arguments last)
  - Input dictionary ordering (NAME key always first)
  - Blank line insertion for readability
- YAML/_YAML and JSON/_JSON folder convention support
- Glob pattern support for batch conversion
- Recursive directory processing
- Folder structure replication
- `--tidy` flag for reformatting YAML recipes in-place
- Command-line interface with ArgumentParser
- Comprehensive error handling
- macOS 15+ native implementation with Swift 6.0

### Features
- Faster batch operations compared to Python version
- No external dependencies (except Swift Package Manager packages)
- No need for `plutil` command (native plist support)
- Full CLI compatibility with Python version
- Maintains key ordering for AutoPkg recipes

### Technical Details
- Built with Swift 6.0
- Dependencies: Yams 5.4.0, swift-argument-parser 1.7.1, swift-collections 1.4.1
- Uses OrderedCollections for maintaining dictionary key order
- PropertyListSerialization for native plist handling
- Glob pattern matching via glob(3)

### Compatibility
- Requires macOS 15.0 or later
- Full feature parity with Python version
- Command-line interface matches Python version exactly

### Known Limitations
- macOS 15+ only (Python version supports older versions)
- No backward compatibility for older macOS versions planned
