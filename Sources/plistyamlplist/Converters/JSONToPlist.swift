import Foundation
import OrderedCollections

/// Converts JSON files to plist format
struct JSONToPlistConverter {
    
    /// Convert a JSON file to plist
    /// - Parameters:
    ///   - inputPath: Path to the JSON file
    ///   - outputPath: Path where plist will be written
    /// - Throws: ConversionError if conversion fails
    static func convert(inputPath: String, outputPath: String) throws {
        // Read the JSON file
        let jsonData: Data
        do {
            jsonData = try Data(contentsOf: URL(fileURLWithPath: inputPath))
        } catch {
            throw ConversionError.fileNotFound(inputPath)
        }
        
        // Parse JSON
        let jsonObject: Any
        do {
            jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
        } catch {
            throw ConversionError.invalidJSONFormat(error.localizedDescription)
        }
        
        // Convert to PropertyListValue
        guard let plValue = PropertyListValue(fromPlist: jsonObject) else {
            throw ConversionError.invalidJSONFormat("Could not convert JSON data to property list")
        }
        
        // Clean null values (plist doesn't support null)
        let cleanedValue = cleanNullValues(plValue)
        
        // Convert to plist object
        let plistObject = cleanedValue.toPlist()
        
        // Serialize to XML plist format
        let plistData: Data
        do {
            plistData = try PropertyListSerialization.data(
                fromPropertyList: plistObject,
                format: .xml,
                options: 0
            )
        } catch {
            throw ConversionError.invalidPlistFormat(error.localizedDescription)
        }
        
        // Convert to string and ensure final newline
        guard var plistString = String(data: plistData, encoding: .utf8) else {
            throw ConversionError.invalidPlistFormat("Could not encode plist as UTF-8")
        }
        
        if !plistString.hasSuffix("\n") {
            plistString += "\n"
        }
        
        // Write to file
        do {
            try plistString.write(toFile: outputPath, atomically: true, encoding: .utf8)
            print("Wrote to: \(outputPath)\n")
        } catch {
            throw ConversionError.cannotWriteFile(outputPath)
        }
    }
    
    /// Recursively remove null values from PropertyListValue
    /// (JSON allows null but plist does not)
    private static func cleanNullValues(_ value: PropertyListValue) -> PropertyListValue {
        switch value {
        case .array(let arr):
            // Remove null values and recursively clean remaining items
            let cleaned = arr.compactMap { item -> PropertyListValue? in
                // In this implementation, we don't have explicit null values
                // but we recursively clean nested structures
                return cleanNullValues(item)
            }
            return .array(cleaned)
            
        case .dictionary(let dict):
            // Remove null values and recursively clean remaining items
            var cleaned = OrderedDictionary<String, PropertyListValue>()
            for (key, val) in dict {
                cleaned[key] = cleanNullValues(val)
            }
            return .dictionary(cleaned)
            
        default:
            return value
        }
    }
}
