// Small Swift wrapper around NSCache

import Foundation

final class Cache<Key: Hashable, Value> {
    private let wrapped = NSCache<WrappedKey, Entry>()
    private let dateProvider: () -> Date
    private let entryLifetime: TimeInterval
    
    init(dateProvider: @escaping () -> Date = Date.init,
         entryLifetime: TimeInterval = 12 * 60 * 60) {
        self.dateProvider = dateProvider
        self.entryLifetime = entryLifetime
    }
    
    /// Insert a new value in the cache
    /// - Parameters:
    ///   - value: Value to insert
    ///   - key: Key to use as identifier
    func insert(_ value: Value, forKey key: Key) {
        let expDate = dateProvider().addingTimeInterval(entryLifetime)
        let entry = Entry(value: value, expirationDate: expDate)
        wrapped.setObject(entry, forKey: WrappedKey(key))
    }
    
    /// Get a value from the cache
    /// - Parameter key: Key to identify a value
    /// - Returns: Value or nil if not found
    func get(forKey key: Key) -> Value? {
        guard let entry = wrapped.object(forKey: WrappedKey(key)) else {
            return nil
        }
        
        guard dateProvider() < entry.expirationDate else {
            remove(forKey: key)
            return nil
        }
        
        return entry.value
    }
    
    /// Removes any existing value from the cache.
    /// - Parameter key: Key to identify the value
    func remove(forKey key: Key) {
        wrapped.removeObject(forKey: WrappedKey(key))
    }
}

extension Cache {
    subscript(key: Key) -> Value? {
        get { return get(forKey: key) }
        set {
            guard let value = newValue else {
                // If nil was assigned using our subscript,
                // then we remove any value for that key:
                remove(forKey: key)
                return
            }

            insert(value, forKey: key)
        }
    }
}

// MARK: - Custom wrappers

private extension Cache {
    /// Wrapper around our key so it can be used in NSCache
    final class WrappedKey: NSObject {
        let key: Key

        init(_ key: Key) { self.key = key }

        override var hash: Int { return key.hashValue }

        override func isEqual(_ object: Any?) -> Bool {
            guard let value = object as? WrappedKey else {
                return false
            }

            return value.key == key
        }
    }
    
    final class Entry {
        let value: Value
        let expirationDate: Date
        
        init(value: Value, expirationDate: Date) {
            self.value = value
            self.expirationDate
        }
    }
}
