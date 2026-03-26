import Foundation
import OrderedCollections

/// Represents an AutoPkg recipe with ordered keys for proper formatting
struct AutoPkgRecipe {
    var description: String?
    var comment: String?  // Can be "Comment" or "Comments"
    var identifier: String?
    var parentRecipe: String?
    var minimumVersion: String?
    var input: OrderedDictionary<String, PropertyListValue>?
    var process: [ProcessorStep]?
    var parentRecipeTrustInfo: OrderedDictionary<String, PropertyListValue>?
    
    /// Additional fields not in the standard order
    var otherFields: OrderedDictionary<String, PropertyListValue> = [:]
    
    init() {}
    
    /// Detect if a property list dictionary is an AutoPkg recipe
    static func isRecipe(_ dict: [String: Any]) -> Bool {
        return dict["Process"] != nil
    }
    
    /// Detect if a filename indicates an AutoPkg recipe
    static func isRecipeFilename(_ path: String) -> Bool {
        let lower = path.lowercased()
        return lower.hasSuffix(".recipe") || 
               lower.hasSuffix(".recipe.plist") || 
               lower.hasSuffix(".recipe.yaml")
    }
    
    /// Parse a recipe from a PropertyListValue dictionary
    init?(from value: PropertyListValue) {
        guard case .dictionary(let dict) = value else { return nil }
        
        // Extract standard fields (handle both Comment and Comments)
        if case .string(let val) = dict["Description"] {
            self.description = val
        }
        if case .string(let val) = dict["Comment"] {
            self.comment = val
        } else if case .string(let val) = dict["Comments"] {
            self.comment = val
        }
        if case .string(let val) = dict["Identifier"] {
            self.identifier = val
        }
        if case .string(let val) = dict["ParentRecipe"] {
            self.parentRecipe = val
        }
        if case .string(let val) = dict["MinimumVersion"] {
            self.minimumVersion = val
        }
        
        // Parse Input dictionary
        if case .dictionary(let inputDict) = dict["Input"] {
            self.input = OrderedDictionary(uniqueKeysWithValues: inputDict.map { ($0, $1) })
        }
        
        // Parse Process array
        if case .array(let processArray) = dict["Process"] {
            self.process = processArray.compactMap { ProcessorStep(from: $0) }
        }
        
        // Parse ParentRecipeTrustInfo
        if case .dictionary(let trustDict) = dict["ParentRecipeTrustInfo"] {
            self.parentRecipeTrustInfo = OrderedDictionary(uniqueKeysWithValues: trustDict.map { ($0, $1) })
        }
        
        // Store other fields
        let knownKeys = Set(["Description", "Comment", "Comments", "Identifier", "ParentRecipe", 
                             "MinimumVersion", "Input", "Process", "ParentRecipeTrustInfo"])
        for (key, value) in dict where !knownKeys.contains(key) {
            self.otherFields[key] = value
        }
    }
    
    /// Convert to ordered PropertyListValue with proper key ordering
    func toPropertyListValue() -> PropertyListValue {
        var ordered: OrderedDictionary<String, PropertyListValue> = [:]
        
        // Add fields in the desired order (only if present)
        // 1. Description (first if present)
        if let description = description {
            ordered["Description"] = .string(description)
        }
        // 2. Comment/Comments (second if present at top level)
        if let comment = comment {
            // Use "Comment" as the key (normalize)
            ordered["Comment"] = .string(comment)
        }
        // 3. Identifier (third)
        if let identifier = identifier {
            ordered["Identifier"] = .string(identifier)
        }
        // 4. ParentRecipe (fourth if present)
        if let parentRecipe = parentRecipe {
            ordered["ParentRecipe"] = .string(parentRecipe)
        }
        // 5. MinimumVersion (fifth)
        if let minimumVersion = minimumVersion {
            ordered["MinimumVersion"] = .string(minimumVersion)
        }
        // [blank line will be added by formatter]
        // 6. Input
        if let input = input {
            ordered["Input"] = .dictionary(input)
        }
        // [blank line will be added by formatter]
        // 7. Process
        if let process = process {
            ordered["Process"] = .array(process.map { $0.toPropertyListValue() })
        }
        // [blank line will be added by formatter before ParentRecipeTrustInfo]
        // 8. ParentRecipeTrustInfo
        if let trustInfo = parentRecipeTrustInfo {
            ordered["ParentRecipeTrustInfo"] = .dictionary(trustInfo)
        }
        
        // Add other fields at the end
        for (key, value) in otherFields {
            ordered[key] = value
        }
        
        return .dictionary(ordered)
    }
}

/// Represents a processor step in an AutoPkg recipe
struct ProcessorStep {
    var processor: String
    var comment: String?  // Can be "Comment" or "Comments"
    var arguments: OrderedDictionary<String, PropertyListValue>?
    var otherFields: OrderedDictionary<String, PropertyListValue> = [:]
    
    init?(from value: PropertyListValue) {
        guard case .dictionary(let dict) = value else { return nil }
        
        // Processor is required
        guard case .string(let proc) = dict["Processor"] else { return nil }
        self.processor = proc
        
        // Extract optional fields (handle both Comment and Comments)
        if case .string(let val) = dict["Comment"] {
            self.comment = val
        } else if case .string(let val) = dict["Comments"] {
            self.comment = val
        }
        if case .dictionary(let argsDict) = dict["Arguments"] {
            self.arguments = OrderedDictionary(uniqueKeysWithValues: argsDict.map { ($0, $1) })
        }
        
        // Store other fields
        let knownKeys = Set(["Processor", "Comment", "Comments", "Arguments"])
        for (key, value) in dict where !knownKeys.contains(key) {
            self.otherFields[key] = value
        }
    }
    
    /// Convert to PropertyListValue with proper key ordering
    /// Processor comes first, Comment/Comments second, Arguments third
    func toPropertyListValue() -> PropertyListValue {
        var ordered: OrderedDictionary<String, PropertyListValue> = [:]
        
        // 1. Always add Processor first
        ordered["Processor"] = .string(processor)
        
        // 2. Add Comment/Comments second (if present)
        if let comment = comment {
            // Use "Comment" as the key (normalize)
            ordered["Comment"] = .string(comment)
        }
        
        // 3. Add Arguments third (if present)
        if let arguments = arguments {
            ordered["Arguments"] = .dictionary(arguments)
        }
        
        // 4. Add other fields after Arguments
        for (key, value) in otherFields {
            ordered[key] = value
        }
        
        return .dictionary(ordered)
    }
}
