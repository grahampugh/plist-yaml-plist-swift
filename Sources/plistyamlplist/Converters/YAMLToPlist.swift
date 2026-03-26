import Foundation
import Yams

/// Converts YAML files to plist format
struct YAMLToPlistConverter {
    
    /// Convert a YAML file to plist
    /// - Parameters:
    ///   - inputPath: Path to the YAML file
    ///   - outputPath: Path where plist will be written
    /// - Throws: ConversionError if conversion fails
    static func convert(inputPath: String, outputPath: String) throws {
        // Read the YAML file
        let yamlString: String
        do {
            yamlString = try String(contentsOfFile: inputPath, encoding: .utf8)
        } catch {
            throw ConversionError.fileNotFound(inputPath)
        }
        
        // Parse YAML
        let yamlObject: Any
        do {
            yamlObject = try Yams.load(yaml: yamlString) ?? [:]
        } catch {
            throw ConversionError.invalidYAMLFormat(error.localizedDescription)
        }
        
        // Convert to PropertyListValue
        guard let plValue = PropertyListValue(fromPlist: yamlObject) else {
            throw ConversionError.invalidYAMLFormat("Could not convert YAML data to property list")
        }
        
        // Convert to plist object
        let plistObject = plValue.toPlist()
        
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
        
        // Convert to string and add final newline
        guard var plistString = String(data: plistData, encoding: .utf8) else {
            throw ConversionError.invalidPlistFormat("Could not encode plist as UTF-8")
        }
        
        if !plistString.hasSuffix("\n") {
            plistString += "\n"
        }
        
        // Write to file
        do {
            try plistString.write(toFile: outputPath, atomically: true, encoding: .utf8)
            print("Written to \(outputPath)\n")
        } catch {
            throw ConversionError.cannotWriteFile(outputPath)
        }
    }
}
