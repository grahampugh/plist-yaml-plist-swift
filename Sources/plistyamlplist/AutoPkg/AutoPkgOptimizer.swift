import Foundation
import OrderedCollections

/// Utilities for optimizing AutoPkg recipe formatting
enum AutoPkgOptimizer {
    
    /// Optimize an AutoPkg recipe's Input dictionary to have NAME first
    static func optimizeInput(_ input: OrderedDictionary<String, PropertyListValue>) -> OrderedDictionary<String, PropertyListValue> {
        var optimized: OrderedDictionary<String, PropertyListValue> = [:]
        
        // Add NAME first if it exists
        if let nameValue = input["NAME"] {
            optimized["NAME"] = nameValue
        }
        
        // Add all other keys in their original order
        for (key, value) in input where key != "NAME" {
            optimized[key] = value
        }
        
        return optimized
    }
    
    /// Optimize a full recipe by reordering Input and Process entries
    static func optimize(_ recipe: inout AutoPkgRecipe) {
        // Optimize Input dictionary to have NAME first
        if let input = recipe.input {
            recipe.input = optimizeInput(input)
        }
        
        // Process array is already handled by ProcessorStep.toPropertyListValue()
        // which ensures Processor is first, Comment second, Arguments last
    }
}
