import Foundation

/// Handles path logic including YAML/_YAML and JSON/_JSON folder conventions
struct PathHandler {
    
    /// Check if path contains a YAML or _YAML folder and determine output path
    /// Returns the output directory if found, nil otherwise
    static func checkForYAMLFolder(_ path: String) -> String? {
        let absolutePath = (path as NSString).expandingTildeInPath
        let yamlFolders = ["_YAML", "YAML"]
        
        for yamlFolder in yamlFolders {
            if absolutePath.contains("/\(yamlFolder)/") {
                print("\(yamlFolder) folder exists: \(absolutePath)")
                
                // Split on the YAML folder
                guard let range = absolutePath.range(of: "/\(yamlFolder)/") else { continue }
                let topPath = String(absolutePath[..<range.lowerBound])
                let basePath = String(absolutePath[range.upperBound...])
                
                // Construct output path
                let outputPath = (topPath as NSString).appendingPathComponent(basePath)
                let outputDir = (outputPath as NSString).deletingLastPathComponent
                
                // Check if output directory exists
                if FileManager.default.fileExists(atPath: outputDir) {
                    print("Path exists: \(outputDir)")
                    return outputDir
                } else {
                    print("Path does not exist: \(outputDir)")
                    print("Please create this folder and try again")
                    return nil // Caller should exit with error
                }
            }
        }
        
        return nil
    }
    
    /// Check if path contains a JSON or _JSON folder and determine output path
    /// Returns the output directory if found, nil otherwise
    static func checkForJSONFolder(_ path: String) -> String? {
        let absolutePath = (path as NSString).expandingTildeInPath
        let jsonFolders = ["_JSON", "JSON"]
        
        for jsonFolder in jsonFolders {
            if absolutePath.contains("/\(jsonFolder)/") {
                print("\(jsonFolder) folder exists: \(absolutePath)")
                
                // Split on the JSON folder
                guard let range = absolutePath.range(of: "/\(jsonFolder)/") else { continue }
                let topPath = String(absolutePath[..<range.lowerBound])
                let basePath = String(absolutePath[range.upperBound...])
                
                // Construct output path
                let outputPath = (topPath as NSString).appendingPathComponent(basePath)
                let outputDir = (outputPath as NSString).deletingLastPathComponent
                
                // Check if output directory exists
                if FileManager.default.fileExists(atPath: outputDir) {
                    print("Path exists: \(outputDir)")
                    return outputDir
                } else {
                    print("Path does not exist: \(outputDir)")
                    print("Please create this folder and try again")
                    return nil // Caller should exit with error
                }
            }
        }
        
        return nil
    }
    
    /// Determine output path when none is provided
    /// - Parameters:
    ///   - inputPath: Input file path
    ///   - fileType: Detected file type
    /// - Returns: Output path, or nil if error (e.g., folder doesn't exist)
    static func determineOutputPath(for inputPath: String, fileType: FileType) -> String? {
        let absolutePath = (inputPath as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: absolutePath)
        let filename = url.deletingPathExtension().lastPathComponent
        
        switch fileType {
        case .yaml:
            // Check for YAML folder convention
            if let outputDir = checkForYAMLFolder(absolutePath) {
                return (outputDir as NSString).appendingPathComponent(filename)
            } else if absolutePath.contains("/YAML/") || absolutePath.contains("/_YAML/") {
                // YAML folder exists but output directory doesn't
                return nil
            }
            // Remove .yaml extension
            return url.deletingPathExtension().path
            
        case .json:
            // Check for JSON folder convention
            if let outputDir = checkForJSONFolder(absolutePath) {
                return (outputDir as NSString).appendingPathComponent(filename)
            } else if absolutePath.contains("/JSON/") || absolutePath.contains("/_JSON/") {
                // JSON folder exists but output directory doesn't
                return nil
            }
            // Remove .json extension
            return url.deletingPathExtension().path
            
        case .plist:
            // For plist files, add .yaml extension
            return absolutePath + ".yaml"
            
        case .unknown:
            // Try to detect if it's a plist by content
            if FileDetector.isPlistFile(absolutePath) {
                return absolutePath + ".yaml"
            }
            return nil
        }
    }
    
    /// Expand tilde in path
    static func expandTilde(_ path: String) -> String {
        return (path as NSString).expandingTildeInPath
    }
    
    /// Check if a directory exists
    static func directoryExists(_ path: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
    
    /// Check if a file exists
    static func fileExists(_ path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }
}
