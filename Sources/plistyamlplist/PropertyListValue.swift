import Foundation

/// Represents a property list value that can be converted to/from plist, YAML, and JSON
enum PropertyListValue: Equatable {
    case string(String)
    case integer(Int)
    case double(Double)
    case bool(Bool)
    case date(Date)
    case data(Data)
    case array([PropertyListValue])
    case dictionary([String: PropertyListValue])
    
    /// Convert from a Foundation property list object
    init?(fromPlist object: Any) {
        switch object {
        case let string as String:
            self = .string(string)
        case let number as NSNumber:
            // Distinguish between bool, int, and double
            if CFNumberGetType(number as CFNumber) == .charType {
                self = .bool(number.boolValue)
            } else if CFNumberIsFloatType(number as CFNumber) {
                self = .double(number.doubleValue)
            } else {
                self = .integer(number.intValue)
            }
        case let date as Date:
            self = .date(date)
        case let data as Data:
            self = .data(data)
        case let array as [Any]:
            let values = array.compactMap { PropertyListValue(fromPlist: $0) }
            guard values.count == array.count else { return nil }
            self = .array(values)
        case let dict as [String: Any]:
            var result: [String: PropertyListValue] = [:]
            for (key, value) in dict {
                guard let plValue = PropertyListValue(fromPlist: value) else { return nil }
                result[key] = plValue
            }
            self = .dictionary(result)
        default:
            return nil
        }
    }
    
    /// Convert to a Foundation property list object
    func toPlist() -> Any {
        switch self {
        case .string(let value):
            return value
        case .integer(let value):
            return NSNumber(value: value)
        case .double(let value):
            return NSNumber(value: value)
        case .bool(let value):
            return NSNumber(value: value)
        case .date(let value):
            return value
        case .data(let value):
            return value
        case .array(let values):
            return values.map { $0.toPlist() }
        case .dictionary(let dict):
            return dict.mapValues { $0.toPlist() }
        }
    }
}
