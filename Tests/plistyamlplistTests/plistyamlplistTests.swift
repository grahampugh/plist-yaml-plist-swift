import Testing
import OrderedCollections
@testable import plistyamlplist

@Test func example() async throws {
    // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    // Swift Testing Documentation
    // https://developer.apple.com/documentation/testing
}

// MARK: - RecipeYAMLGenerator Empty Collection Tests

@Test func testEmptyDictionaryAtTopLevel() throws {
    // Create a recipe with an empty dictionary in otherFields (simulates non_core_processors: {})
    var recipe = AutoPkgRecipe()
    recipe.identifier = "com.test.recipe"
    recipe.otherFields["non_core_processors"] = .dictionary(OrderedDictionary<String, PropertyListValue>())

    let yaml = try RecipeYAMLGenerator.generate(from: recipe)
    #expect(yaml.contains("non_core_processors: {}"))

    // Verify the YAML is valid
    try RecipeYAMLGenerator.verify(yaml)
}

@Test func testEmptyArrayAtTopLevel() throws {
    // Create a recipe with an empty array in otherFields
    var recipe = AutoPkgRecipe()
    recipe.identifier = "com.test.recipe"
    recipe.otherFields["empty_list"] = .array([])

    let yaml = try RecipeYAMLGenerator.generate(from: recipe)
    #expect(yaml.contains("empty_list: []"))

    // Verify the YAML is valid
    try RecipeYAMLGenerator.verify(yaml)
}

@Test func testEmptyDictionaryInInput() throws {
    // Create a recipe with an empty dictionary in Input
    var recipe = AutoPkgRecipe()
    recipe.identifier = "com.test.recipe"
    recipe.input = ["EMPTY_OPTIONS": .dictionary(OrderedDictionary<String, PropertyListValue>())]

    let yaml = try RecipeYAMLGenerator.generate(from: recipe)
    #expect(yaml.contains("EMPTY_OPTIONS: {}"))

    // Verify the YAML is valid
    try RecipeYAMLGenerator.verify(yaml)
}

@Test func testNestedEmptyDictionaryInArray() throws {
    // Create a recipe with an array containing an empty dictionary
    var recipe = AutoPkgRecipe()
    recipe.identifier = "com.test.recipe"
    recipe.input = ["LIST_WITH_EMPTY_DICT": .array([.dictionary(OrderedDictionary<String, PropertyListValue>())])]

    let yaml = try RecipeYAMLGenerator.generate(from: recipe)
    #expect(yaml.contains("- {}"))

    // Verify the YAML is valid
    try RecipeYAMLGenerator.verify(yaml)
}

@Test func testNestedEmptyArrayInArray() throws {
    // Create a recipe with an array containing an empty array
    var recipe = AutoPkgRecipe()
    recipe.identifier = "com.test.recipe"
    recipe.input = ["NESTED_EMPTY_ARRAYS": .array([.array([])])]

    let yaml = try RecipeYAMLGenerator.generate(from: recipe)
    #expect(yaml.contains("- []"))

    // Verify the YAML is valid
    try RecipeYAMLGenerator.verify(yaml)
}

@Test func testEmptyDictionaryInParentRecipeTrustInfo() throws {
    // Create a recipe with an empty dictionary in ParentRecipeTrustInfo (real-world use case)
    var recipe = AutoPkgRecipe()
    recipe.identifier = "com.test.recipe"
    recipe.parentRecipe = "com.parent.recipe"
    recipe.parentRecipeTrustInfo = ["non_core_processors": .dictionary(OrderedDictionary<String, PropertyListValue>())]

    let yaml = try RecipeYAMLGenerator.generate(from: recipe)
    #expect(yaml.contains("non_core_processors: {}"))

    // Verify the YAML is valid
    try RecipeYAMLGenerator.verify(yaml)
}

@Test func testMixedEmptyAndNonEmptyCollections() throws {
    // Create a recipe with both empty and non-empty collections
    var recipe = AutoPkgRecipe()
    recipe.identifier = "com.test.recipe"
    recipe.input = [
        "NON_EMPTY": .dictionary(["key": .string("value")]),
        "EMPTY_DICT": .dictionary(OrderedDictionary<String, PropertyListValue>()),
        "NON_EMPTY_LIST": .array([.string("item")]),
        "EMPTY_LIST": .array([])
    ]

    let yaml = try RecipeYAMLGenerator.generate(from: recipe)

    // Check empty collections use inline syntax
    #expect(yaml.contains("EMPTY_DICT: {}"))
    #expect(yaml.contains("EMPTY_LIST: []"))

    // Check non-empty collections use block syntax
    #expect(yaml.contains("NON_EMPTY:"))
    #expect(yaml.contains("key: value"))
    #expect(yaml.contains("NON_EMPTY_LIST:"))
    #expect(yaml.contains("- item"))

    // Verify the YAML is valid
    try RecipeYAMLGenerator.verify(yaml)
}
