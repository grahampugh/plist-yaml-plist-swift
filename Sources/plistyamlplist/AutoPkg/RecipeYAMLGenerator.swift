import Foundation
import Yams

/// Manual YAML generator for AutoPkg recipes that preserves exact key ordering
struct RecipeYAMLGenerator {
    
    /// Generate YAML from an AutoPkg recipe with preserved ordering
    static func generate(from recipe: AutoPkgRecipe) throws -> String {
        var lines: [String] = []
        
        // 1. Description (first if present)
        if let description = recipe.description {
            if description.contains("\n") {
                appendBlockScalar(description, withKey: "Description", toLines: &lines, indent: 0)
            } else {
                lines.append("Description: \(quoteIfNeeded(description))")
            }
        }
        
        // 2. Comment/Comments (second if present)
        if let comment = recipe.comment {
            if comment.contains("\n") {
                appendBlockScalar(comment, withKey: "Comment", toLines: &lines, indent: 0)
            } else {
                lines.append("Comment: \(quoteIfNeeded(comment))")
            }
        }
        
        // 3. Identifier
        if let identifier = recipe.identifier {
            lines.append("Identifier: \(quoteIfNeeded(identifier))")
        }
        
        // 4. ParentRecipe (if present)
        if let parentRecipe = recipe.parentRecipe {
            lines.append("ParentRecipe: \(quoteIfNeeded(parentRecipe))")
        }
        
        // 5. MinimumVersion
        if let minimumVersion = recipe.minimumVersion {
            lines.append("MinimumVersion: \(quoteIfNeeded(minimumVersion))")
        }
        
        // Blank line before Input
        if recipe.input != nil {
            lines.append("")
        }
        
        // 6. Input dictionary
        if let input = recipe.input {
            lines.append("Input:")
            for (key, value) in input {
                try appendValue(value, withKey: key, toLines: &lines, indent: 2)
            }
        }
        
        // Blank line before Process
        if recipe.process != nil {
            lines.append("")
        }
        
        // 7. Process array
        if let process = recipe.process {
            lines.append("Process:")
            for (index, processor) in process.enumerated() {
                // Add blank line between processors (but not before the first)
                if index > 0 {
                    lines.append("")
                }
                try appendProcessor(processor, toLines: &lines, indent: 2)
            }
        }
        
        // Blank line before ParentRecipeTrustInfo
        if recipe.parentRecipeTrustInfo != nil {
            lines.append("")
        }
        
        // 8. ParentRecipeTrustInfo
        if let trustInfo = recipe.parentRecipeTrustInfo {
            lines.append("ParentRecipeTrustInfo:")
            for (key, value) in trustInfo {
                try appendValue(value, withKey: key, toLines: &lines, indent: 2)
            }
        }
        
        // 9. Other fields (if any)
        for (key, value) in recipe.otherFields {
            lines.append("")
            try appendValue(value, withKey: key, toLines: &lines, indent: 0)
        }
        
        // Ensure final newline
        var yaml = lines.joined(separator: "\n")
        if !yaml.hasSuffix("\n") {
            yaml += "\n"
        }
        
        return yaml
    }
    
    /// Append a processor to the YAML lines
    private static func appendProcessor(_ processor: ProcessorStep, toLines lines: inout [String], indent: Int) throws {
        let indentStr = String(repeating: " ", count: indent)
        
        // Start the list item
        lines.append("\(indentStr)- Processor: \(quoteIfNeeded(processor.processor))")
        
        // Add Comment if present
        if let comment = processor.comment {
            // Use block scalar for multiline comments
            if comment.contains("\n") {
                appendBlockScalar(comment, withKey: "Comment", toLines: &lines, indent: indent + 2)
            } else {
                lines.append("\(indentStr)  Comment: \(quoteIfNeeded(comment))")
            }
        }
        
        // Add Arguments if present
        if let arguments = processor.arguments {
            lines.append("\(indentStr)  Arguments:")
            for (key, value) in arguments {
                try appendValue(value, withKey: key, toLines: &lines, indent: indent + 4)
            }
        }
        
        // Add other fields if any
        for (key, value) in processor.otherFields {
            try appendValue(value, withKey: key, toLines: &lines, indent: indent + 2)
        }
    }
    
    /// Append a value with a key to the YAML lines
    private static func appendValue(_ value: PropertyListValue, withKey key: String, toLines lines: inout [String], indent: Int) throws {
        let indentStr = String(repeating: " ", count: indent)
        
        switch value {
        case .string(let str):
            // Use block scalar (heredoc) for multiline strings
            if str.contains("\n") {
                appendBlockScalar(str, withKey: key, toLines: &lines, indent: indent)
            } else {
                lines.append("\(indentStr)\(key): \(quoteIfNeeded(str))")
            }
            
        case .integer(let int):
            lines.append("\(indentStr)\(key): \(int)")
            
        case .double(let dbl):
            lines.append("\(indentStr)\(key): \(dbl)")
            
        case .bool(let bool):
            lines.append("\(indentStr)\(key): \(bool ? "true" : "false")")
            
        case .date(let date):
            let formatter = ISO8601DateFormatter()
            lines.append("\(indentStr)\(key): \(formatter.string(from: date))")
            
        case .data(let data):
            lines.append("\(indentStr)\(key): \(data.base64EncodedString())")
            
        case .array(let arr):
            if arr.isEmpty {
                lines.append("\(indentStr)\(key): []")
            } else {
                lines.append("\(indentStr)\(key):")
                for item in arr {
                    try appendArrayItem(item, toLines: &lines, indent: indent + 2)
                }
            }
            
        case .dictionary(let dict):
            if dict.isEmpty {
                lines.append("\(indentStr)\(key): {}")
            } else {
                lines.append("\(indentStr)\(key):")
                for (subKey, subValue) in dict {
                    try appendValue(subValue, withKey: subKey, toLines: &lines, indent: indent + 2)
                }
            }
        }
    }

    /// Append an array item to the YAML lines
    private static func appendArrayItem(_ value: PropertyListValue, toLines lines: inout [String], indent: Int) throws {
        let indentStr = String(repeating: " ", count: indent)
        
        switch value {
        case .string(let str):
            // Use block scalar (heredoc) for multiline strings in arrays
            if str.contains("\n") {
                let blockIndicator = str.hasSuffix("\n") ? "|" : "|-"
                lines.append("\(indentStr)- \(blockIndicator)")
                let trimmedValue = str.hasSuffix("\n") ? String(str.dropLast()) : str
                let stringLines = trimmedValue.split(separator: "\n", omittingEmptySubsequences: false)
                for line in stringLines {
                    lines.append("\(indentStr)  \(line)")
                }
            } else {
                lines.append("\(indentStr)- \(quoteIfNeeded(str))")
            }
            
        case .integer(let int):
            lines.append("\(indentStr)- \(int)")
            
        case .double(let dbl):
            lines.append("\(indentStr)- \(dbl)")
            
        case .bool(let bool):
            lines.append("\(indentStr)- \(bool ? "true" : "false")")
            
        case .date(let date):
            let formatter = ISO8601DateFormatter()
            lines.append("\(indentStr)- \(formatter.string(from: date))")
            
        case .data(let data):
            lines.append("\(indentStr)- \(data.base64EncodedString())")
            
        case .array(let arr):
            if arr.isEmpty {
                lines.append("\(indentStr)- []")
            } else {
                lines.append("\(indentStr)-")
                for item in arr {
                    try appendArrayItem(item, toLines: &lines, indent: indent + 2)
                }
            }

        case .dictionary(let dict):
            if dict.isEmpty {
                lines.append("\(indentStr)- {}")
            } else {
                lines.append("\(indentStr)-")
                for (key, subValue) in dict {
                    try appendValue(subValue, withKey: key, toLines: &lines, indent: indent + 2)
                }
            }
        }
    }
    
    /// Quote a string if it needs quoting for YAML
    /// Note: This is only called for single-line strings; multiline strings use block scalars
    private static func quoteIfNeeded(_ string: String) -> String {
        // Check if the string needs quoting
        let needsQuoting = string.isEmpty ||
            string.contains(":") ||
            string.contains("#") ||
            string.contains("%") ||  // AutoPkg variables
            string.contains("\t") ||  // Tabs will be converted to spaces
            string.starts(with: " ") ||
            string.hasSuffix(" ") ||
            string.starts(with: "-") ||
            string.starts(with: "!") ||
            string.starts(with: "&") ||
            string.starts(with: "*") ||
            string.starts(with: "?") ||
            string.starts(with: "|") ||
            string.starts(with: ">") ||
            string.starts(with: "@") ||
            string.starts(with: "`") ||
            string == "true" ||
            string == "false" ||
            string == "yes" ||
            string == "no" ||
            string == "null" ||
            Int(string) != nil ||
            Double(string) != nil
        
        if needsQuoting {
            // Escape special characters for YAML string literals
            // Note: tabs are converted to spaces per user preference
            // Note: newlines/carriage returns should never reach here (they use block scalars)
            let escaped = string
                .replacingOccurrences(of: "\t", with: "    ")  // Convert tabs to 4 spaces first
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
            return "\"\(escaped)\""
        }
        
        return string
    }
    
    /// Verify that the generated YAML is valid by re-parsing it
    static func verify(_ yaml: String) throws {
        do {
            _ = try Yams.load(yaml: yaml)
        } catch {
            // Print the YAML for debugging
            print("Generated YAML that failed verification:")
            print("---")
            print(yaml)
            print("---")
            throw ConversionError.invalidYAMLFormat("Generated YAML failed verification: \(error.localizedDescription)")
        }
    }
    
    /// Append a block scalar (heredoc) for a multiline string
    /// Uses `|-` to strip trailing newline if the string doesn't end with one
    private static func appendBlockScalar(_ value: String, withKey key: String, toLines lines: inout [String], indent: Int) {
        let indentStr = String(repeating: " ", count: indent)
        
        // Use `|-` (strip final newlines) if string doesn't end with newline
        // Use `|` (keep final newline) if string ends with newline
        let blockIndicator = value.hasSuffix("\n") ? "|" : "|-"
        lines.append("\(indentStr)\(key): \(blockIndicator)")
        
        // Remove trailing newline if present (we'll let the block indicator handle it)
        let trimmedValue = value.hasSuffix("\n") ? String(value.dropLast()) : value
        let stringLines = trimmedValue.split(separator: "\n", omittingEmptySubsequences: false)
        
        for line in stringLines {
            lines.append("\(indentStr)  \(line)")
        }
    }
}
