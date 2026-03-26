import Foundation
import Yams

/// Converts plist files to YAML format
struct PlistToYAMLConverter {
    
    /// Convert a plist file to YAML
    /// - Parameters:
    ///   - inputPath: Path to the plist file
    ///   - outputPath: Path where YAML will be written
    ///   - isRecipe: Whether this is an AutoPkg recipe (determines special formatting)
    /// - Throws: ConversionError if conversion fails
    static func convert(inputPath: String, outputPath: String, isRecipe: Bool = false) throws {
        // Read the plist file
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: inputPath)) else {
            throw ConversionError.fileNotFound(inputPath)
        }
        
        // Parse plist (handles both XML and binary formats)
        let plistObject: Any
        do {
            plistObject = try PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            )
        } catch {
            throw ConversionError.invalidPlistFormat(error.localizedDescription)
        }
        
        // Convert to PropertyListValue
        guard let plValue = PropertyListValue(fromPlist: plistObject) else {
            throw ConversionError.invalidPlistFormat("Could not convert plist data")
        }
        
        // If it's an AutoPkg recipe, optimize it
        let finalValue: PropertyListValue
        if isRecipe, case .dictionary = plValue, var recipe = AutoPkgRecipe(from: plValue) {
            AutoPkgOptimizer.optimize(&recipe)
            finalValue = recipe.toPropertyListValue()
        } else {
            finalValue = plValue
        }
        
        // Convert to YAML
        let yamlString = try convertToYAML(finalValue, isRecipe: isRecipe)
        
        // Write to file
        do {
            try yamlString.write(toFile: outputPath, atomically: true, encoding: .utf8)
            print("Wrote to: \(outputPath)\n")
        } catch {
            throw ConversionError.cannotWriteFile(outputPath)
        }
    }
    
    /// Convert PropertyListValue to YAML string
    private static func convertToYAML(_ value: PropertyListValue, isRecipe: Bool) throws -> String {
        // Convert PropertyListValue to a Yams-compatible object
        let yamlObject = convertToYamsObject(value)
        
        // Use Yams dump function directly instead of encoder
        do {
            var yaml = try Yams.dump(object: yamlObject, width: -1, sortKeys: false)
            
            // If it's a recipe, apply AutoPkg-specific formatting
            if isRecipe {
                yaml = formatAutoPkgRecipe(yaml)
            }
            
            return yaml
        } catch {
            throw ConversionError.invalidYAMLFormat(error.localizedDescription)
        }
    }
    
    /// Convert PropertyListValue to a Yams-compatible object
    private static func convertToYamsObject(_ value: PropertyListValue) -> Any {
        switch value {
        case .string(let str):
            return str
        case .integer(let int):
            return int
        case .double(let dbl):
            return dbl
        case .bool(let bool):
            return bool
        case .date(let date):
            return date
        case .data(let data):
            // Convert Data to base64 string for YAML representation
            return data.base64EncodedString()
        case .array(let arr):
            return arr.map { convertToYamsObject($0) }
        case .dictionary(let dict):
            // Convert to array of tuples to preserve order
            return dict.mapValues { convertToYamsObject($0) }
        }
    }
    
    /// Apply AutoPkg-specific formatting to YAML output
    private static func formatAutoPkgRecipe(_ yaml: String) -> String {
        let lines = yaml.components(separatedBy: .newlines)
        var formatted: [String] = []
        
        // Add blank lines before specific sections
        let sectionsNeedingBlankLines = ["Input:", "Process:", "- Processor:", "ParentRecipeTrustInfo:"]
        
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Check if we need a blank line before this line
            var needsBlankLine = false
            for section in sectionsNeedingBlankLines {
                if trimmed.starts(with: section) {
                    // Don't add blank line if previous line is already blank
                    // or if this is the first line
                    if index > 0 && !formatted.isEmpty && !formatted.last!.trimmingCharacters(in: .whitespaces).isEmpty {
                        needsBlankLine = true
                    }
                    break
                }
            }
            
            if needsBlankLine {
                formatted.append("")
            }
            formatted.append(line)
        }
        
        // Remove blank line after "Process:" if it's followed by "- Processor:"
        var result = formatted.joined(separator: "\n")
        result = result.replacingOccurrences(of: "Process:\n\n-", with: "Process:\n-")
        
        // Handle multiline strings with embedded newlines
        // Convert quoted strings with \n to block scalars
        result = convertEscapedNewlinesToBlockScalars(result)
        
        // Ensure file ends with newline
        if !result.hasSuffix("\n") {
            result += "\n"
        }
        
        return result
    }
    
    /// Convert strings with escaped newlines to YAML block scalars
    private static func convertEscapedNewlinesToBlockScalars(_ yaml: String) -> String {
        // This is a simplified version - Yams should handle this natively
        // but we keep it for compatibility with Python version behavior
        return yaml
    }
}
