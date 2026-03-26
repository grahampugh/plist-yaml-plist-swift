# Implementation Notes

## AutoPkg Recipe Formatting

### Key Ordering

The Swift implementation uses a custom YAML generator (`RecipeYAMLGenerator`) to ensure precise key ordering for AutoPkg recipes:

**Top-level keys:**
1. Description (if present)
2. Comment/Comments (if present)  
3. Identifier
4. ParentRecipe (if present)
5. MinimumVersion
6. [blank line]
7. Input
8. [blank line]
9. Process
10. [blank line]
11. ParentRecipeTrustInfo (if present)

**Within each Processor:**
1. Processor
2. Comment/Comments (if present)
3. Arguments (if present)
4. [other fields]

**Blank lines:**
- Before Input
- Before Process (but NOT between "Process:" and first processor)
- Between each processor in Process array
- Before ParentRecipeTrustInfo and other top-level keys after Process

### Technical Approach

Rather than relying on Yams to preserve dictionary ordering (which Swift's `Dictionary` type doesn't guarantee), recipes use manual YAML generation that:

1. Directly generates YAML text from `AutoPkgRecipe` structure
2. Maintains exact ordering from `OrderedDictionary` instances
3. Automatically quotes strings containing special characters (%, :, #, etc.)
4. Verifies generated YAML by re-parsing with Yams before writing to file

Non-recipe files still use standard Yams conversion for simplicity.

### Differences from Python Version

- Boolean representation: `true`/`false` (Swift) vs `True`/`False` (Python) - both valid YAML
- String quoting: More conservative quoting to ensure valid YAML
- Order preservation: Guaranteed via manual generation vs. ruamel.yaml's OrderedDict handling

## File Structure

```
Sources/plistyamlplist/
├── AutoPkg/
│   ├── AutoPkgRecipe.swift       # Recipe data model with ordering
│   ├── AutoPkgOptimizer.swift    # NAME-first optimization
│   └── RecipeYAMLGenerator.swift # Manual YAML generation ⭐
├── Converters/
│   ├── PlistToYAML.swift        # Uses RecipeYAMLGenerator for recipes
│   ├── YAMLToPlist.swift
│   └── JSONToPlist.swift
└── [other modules]
```

## Testing

Tested with real AutoPkg recipes including:
- PaloAltoGlobalProtect.download.recipe
- Round-trip conversion (plist → yaml → plist)
- YAML verification via Yams parsing

All key ordering requirements met and verified.
