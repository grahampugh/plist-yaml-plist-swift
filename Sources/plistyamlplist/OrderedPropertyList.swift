import Foundation
import OrderedCollections

/// A dictionary that maintains insertion order, crucial for AutoPkg recipes
typealias OrderedDictionary<Key: Hashable, Value> = OrderedCollections.OrderedDictionary<Key, Value>

/// Extension to convert PropertyListValue dictionaries to ordered dictionaries
extension PropertyListValue {
    /// Convert to an ordered dictionary if this is a dictionary value
    func toOrderedDictionary() -> OrderedDictionary<String, PropertyListValue>? {
        guard case .dictionary(let dict) = self else { return nil }
        return OrderedDictionary(uniqueKeysWithValues: dict.map { ($0.key, $0.value) })
    }
    
    /// Create a PropertyListValue from an ordered dictionary
    static func fromOrderedDictionary(_ dict: OrderedDictionary<String, PropertyListValue>) -> PropertyListValue {
        return .dictionary(dict)
    }
}

/// Represents an ordered dictionary specifically for property lists
struct OrderedPropertyList {
    var items: OrderedDictionary<String, PropertyListValue>
    
    init(_ items: OrderedDictionary<String, PropertyListValue> = [:]) {
        self.items = items
    }
    
    init?(fromPlist object: Any) {
        guard let dict = object as? [String: Any] else { return nil }
        var ordered: OrderedDictionary<String, PropertyListValue> = [:]
        for (key, value) in dict {
            guard let plValue = PropertyListValue(fromPlist: value) else { return nil }
            ordered[key] = plValue
        }
        self.items = ordered
    }
    
    func toPlist() -> [String: Any] {
        Dictionary(uniqueKeysWithValues: items.map { ($0.key, $0.value.toPlist()) })
    }
    
    subscript(key: String) -> PropertyListValue? {
        get { items[key] }
        set { items[key] = newValue }
    }
}
