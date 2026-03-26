import Foundation
import Yams
import OrderedCollections

/// Loads YAML while preserving dictionary key order
struct OrderedYAMLLoader {
    
    /// Load YAML preserving dictionary order
    /// Returns objects that use OrderedDictionary for maps
    static func load(yaml: String) throws -> Any {
        guard let node = try Yams.compose(yaml: yaml) else {
            throw ConversionError.invalidYAMLFormat("Failed to parse YAML")
        }
        
        return try construct(from: node)
    }
    
    /// Construct Swift value from YAML node, preserving order for mappings
    private static func construct(from node: Yams.Node) throws -> Any {
        switch node {
        case .scalar(let scalar):
            return constructScalar(scalar)
            
        case .sequence(let nodes):
            return try nodes.map { try construct(from: $0) }
            
        case .mapping(let pairs):
            // Mapping is an array of (Node, Node) pairs - order is preserved!
            var result: OrderedDictionary<String, Any> = [:]
            for (keyNode, valueNode) in pairs {
                // Key must be a string scalar
                guard case .scalar(let keyScalar) = keyNode else {
                    throw ConversionError.invalidYAMLFormat("Map key must be a scalar")
                }
                let key = String(describing: keyScalar.string)
                let value = try construct(from: valueNode)
                result[key] = value
            }
            return result
            
        case .alias:
            throw ConversionError.invalidYAMLFormat("YAML aliases are not supported")
        }
    }
    
    /// Construct Swift value from scalar node
    private static func constructScalar(_ scalar: Yams.Node.Scalar) -> Any {
        let string = scalar.string
        
        // If the scalar is explicitly quoted, keep it as a string
        // This preserves "2.3" as string instead of converting to Double
        let style = scalar.style
        if style == .doubleQuoted || style == .singleQuoted {
            return string
        }
        
        // Try boolean
        if string == "true" || string == "yes" {
            return true
        }
        if string == "false" || string == "no" {
            return false
        }
        
        // Try null
        if string == "null" || string == "~" || string.isEmpty {
            return NSNull()
        }
        
        // Try integer
        if let intValue = Int(string) {
            return intValue
        }
        
        // Try double
        if let doubleValue = Double(string) {
            return doubleValue
        }
        
        // Default to string
        return string
    }
}
