import Foundation
import OrderedCollections

/// Represents an AutoPkg recipe with ordered keys for proper formatting
struct AutoPkgRecipe {
    var comment: String?
    var description: String?
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
        
        // Extract standard fields
        if case .string(let val) = dict["Comment"] {
            self.comment = val
        }
        if case .string(let val) = dict["Description"] {
            self.description = val
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
        let knownKeys = Set(["Comment", "Description", "Identifier", "ParentRecipe", 
                             "MinimumVersion", "Input", "Process", "ParentRecipeTrustInfo"])
        for (key, value) in dict where !knownKeys.contains(key) {
            self.otherFields[key] = value
        }
    }
    
    /// Convert to ordered PropertyListValue with proper key ordering
    func toPropertyListValue() -> PropertyListValue {
        var ordered: OrderedDictionary<String, PropertyListValue> = [:]
        
        // Add fields in the desired order (only if present)
        if let comment = comment {
            ordered["Comment"] = .string(comment)
        }
        if let description = description {
            ordered["Description"] = .string(description)
        }
        if let identifier = identifier {
            ordered["Identifier"] = .string(identifier)
        }
        if let parentRecipe = parentRecipe {
            ordered["ParentRecipe"] = .string(parentRecipe)
        }
        if let minimumVersion = minimumVersion {
            ordered["MinimumVersion"] = .string(minimumVersion)
        }
        if let input = input {
            let inputDict = Dictionary(uniqueKeysWithValues: input.map { ($0, $1) })
            ordered["Input"] = .dictionary(inputDict)
        }
        if let process = process {
            ordered["Process"] = .array(process.map { $0.toPropertyListValue() })
        }
        if let trustInfo = parentRecipeTrustInfo {
            let trustDict = Dictionary(uniqueKeysWithValues: trustInfo.map { ($0, $1) })
            ordered["ParentRecipeTrustInfo"] = .dictionary(trustDict)
        }
        
        // Add other fields at the end
        for (key, value) in otherFields {
            ordered[key] = value
        }
        
        let dict = Dictionary(uniqueKeysWithValues: ordered.map { ($0, $1) })
        return .dictionary(dict)
    }
}

/// Represents a processor step in an AutoPkg recipe
struct ProcessorStep {
    var processor: String
    var comment: String?
    var arguments: OrderedDictionary<String, PropertyListValue>?
    var otherFields: OrderedDictionary<String, PropertyListValue> = [:]
    
    init?(from value: PropertyListValue) {
        guard case .dictionary(let dict) = value else { return nil }
        
        // Processor is required
        guard case .string(let proc) = dict["Processor"] else { return nil }
        self.processor = proc
        
        // Extract optional fields
        if case .string(let val) = dict["Comment"] {
            self.comment = val
        }
        if case .dictionary(let argsDict) = dict["Arguments"] {
            self.arguments = OrderedDictionary(uniqueKeysWithValues: argsDict.map { ($0, $1) })
        }
        
        // Store other fields
        let knownKeys = Set(["Processor", "Comment", "Arguments"])
        for (key, value) in dict where !knownKeys.contains(key) {
            self.otherFields[key] = value
        }
    }
    
    /// Convert to PropertyListValue with proper key ordering
    /// Processor comes first, Comment second, Arguments last
    func toPropertyListValue() -> PropertyListValue {
        var ordered: OrderedDictionary<String, PropertyListValue> = [:]
        
        // Always add Processor first
        ordered["Processor"] = .string(processor)
        
        // Add other fields (not Comment or Arguments)
        for (key, value) in otherFields {
            ordered[key] = value
        }
        
        // Add Comment second-to-last
        if let comment = comment {
            ordered["Comment"] = .string(comment)
        }
        
        // Add Arguments last
        if let arguments = arguments {
            let argsDict = Dictionary(uniqueKeysWithValues: arguments.map { ($0, $1) })
            ordered["Arguments"] = .dictionary(argsDict)
        }
        
        let dict = Dictionary(uniqueKeysWithValues: ordered.map { ($0, $1) })
        return .dictionary(dict)
    }
}
