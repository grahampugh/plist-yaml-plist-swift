import Foundation

/// Errors that can occur during conversion operations
enum ConversionError: LocalizedError {
    case fileNotFound(String)
    case cannotReadFile(String)
    case cannotWriteFile(String)
    case invalidPlistFormat(String)
    case invalidYAMLFormat(String)
    case invalidJSONFormat(String)
    case unsupportedFileType(String)
    case pathDoesNotExist(String)
    case notAPlistFile(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "ERROR: could not find \(path)"
        case .cannotReadFile(let path):
            return "ERROR: could not read \(path)"
        case .cannotWriteFile(let path):
            return "ERROR: could not create \(path)"
        case .invalidPlistFormat(let reason):
            return "ERROR: Invalid plist format - \(reason)"
        case .invalidYAMLFormat(let reason):
            return "ERROR: Invalid YAML format - \(reason)"
        case .invalidJSONFormat(let reason):
            return "ERROR: Invalid JSON format - \(reason)"
        case .unsupportedFileType(let path):
            return "ERROR: File is not PLIST, JSON or YAML format: \(path)"
        case .pathDoesNotExist(let path):
            return "Path does not exist: \(path)\nPlease create this folder and try again"
        case .notAPlistFile(let path):
            return "ERROR: Input File is not PLIST, JSON or YAML format: \(path)"
        }
    }
}
