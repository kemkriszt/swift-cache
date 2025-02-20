import Foundation
import Testing
@testable import SwiftCache

class SwiftCacheTests {
    private static let entryLifetime = 5.0
    private static let testValue = 1
    private static let testKey = "1"
    
    @Test
    func testCacheStoresValue() async throws {
        let cache = Cache<String, Int>(entryLifetime: Self.entryLifetime)
        
        cache.insert(Self.testValue, forKey: Self.testKey)
        #expect(cache.get(forKey: Self.testKey) == Self.testValue)
        try await Task.sleep(nanoseconds: UInt64(Self.entryLifetime * Double(NSEC_PER_SEC)))
        #expect(cache.get(forKey: Self.testKey) == nil)
    }
    
    @Test
    func testCacheSubscript() {
        let cache = Cache<String, Int>(entryLifetime: Self.entryLifetime)
        
        cache[Self.testKey] = Self.testValue
        #expect(cache[Self.testKey] == Self.testValue)
        #expect(cache.get(forKey: Self.testKey) == Self.testValue)
    }
    
    @Test
    func testCacheRemove() async throws {
        let cache = Cache<String, Int>(entryLifetime: Self.entryLifetime)
        
        cache.insert(Self.testValue, forKey: Self.testKey)
        cache[Self.testKey] = nil
        #expect(cache[Self.testKey] == nil)
        cache.insert(Self.testValue, forKey: Self.testKey)
        cache.remove(forKey: Self.testKey)
        #expect(cache[Self.testKey] == nil)
    }
}
