import Foundation
import Yams

/// Detects file types for conversion
enum FileType {
    case plist
    case yaml
    case json
    case unknown
    
    /// Detect file type from extension
    static func from(extension ext: String) -> FileType {
        let lower = ext.lowercased()
        switch lower {
        case "plist":
            return .plist
        case "yaml", "yml":
            return .yaml
        case "json":
            return .json
        default:
            return .unknown
        }
    }
    
    /// Detect file type from path
    static func from(path: String) -> FileType {
        let url = URL(fileURLWithPath: path)
        let ext = url.pathExtension
        return from(extension: ext)
    }
}

/// Utilities for detecting file types and formats
struct FileDetector {
    
    /// Check if a file is a plist by reading its content
    /// Looks for "PLIST 1.0" on line 2 (index 1)
    static func isPlistFile(_ path: String) -> Bool {
        guard let fileHandle = FileHandle(forReadingAtPath: path) else {
            return false
        }
        
        defer { fileHandle.closeFile() }
        
        // Read first few lines
        guard let data = try? fileHandle.read(upToCount: 1024),
              let content = String(data: data, encoding: .utf8) else {
            return false
        }
        
        let lines = content.components(separatedBy: .newlines)
        
        // Check line 2 (index 1) for PLIST 1.0
        if lines.count > 1 {
            return lines[1].contains("PLIST 1.0")
        }
        
        return false
    }
    
    /// Determine file type by extension first, then by content if needed
    static func detectFileType(_ path: String) -> FileType {
        let typeFromExtension = FileType.from(path: path)
        
        // If extension gives us an answer, use it
        if typeFromExtension != .unknown {
            return typeFromExtension
        }
        
        // Check if it's a plist by reading content
        if isPlistFile(path) {
            return .plist
        }
        
        return .unknown
    }
    
    /// Check if a path represents an AutoPkg recipe based on filename
    static func isRecipeFilename(_ path: String) -> Bool {
        return AutoPkgRecipe.isRecipeFilename(path)
    }
    
    /// Check if file contents represent an AutoPkg recipe
    static func isRecipeContent(at path: String) throws -> Bool {
        let fileType = detectFileType(path)
        
        switch fileType {
        case .plist:
            // Read plist and check for Process key
            guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
                  let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
                return false
            }
            return AutoPkgRecipe.isRecipe(plist)
            
        case .yaml:
            // Read YAML and check for Process key
            guard let yamlString = try? String(contentsOfFile: path, encoding: .utf8),
                  let yamlObject = try? Yams.load(yaml: yamlString) as? [String: Any] else {
                return false
            }
            return AutoPkgRecipe.isRecipe(yamlObject)
            
        default:
            return false
        }
    }
}
