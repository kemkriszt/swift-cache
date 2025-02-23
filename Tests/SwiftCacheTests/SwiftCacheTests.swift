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
    
    @Test
    func testCacheThreadSafety() async throws {
        // unchecked sendable wrapper to make sure that the responsability of thread
        // safety is on the Cache
        class SendableWrapper: @unchecked Sendable {
            let cache = Cache<String, Int>()
            
            func get(forKey key: String) -> Int? {
                cache.get(forKey: key)
            }
            
            func insert(_ value: Int, forKey key: String) {
                cache.insert(value, forKey: key)
            }
            
            func remove(forKey key: String) {
                cache.remove(forKey: key)
            }
        }
        
        let cache = SendableWrapper()
        let key = "key"
        let value = 1
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0...10000 {
                group.addTask {
                    let r = Int.random(in: 0...2)
                    switch r {
                    case 0: let _ = cache.get(forKey: key)
                    case 1: cache.insert(value, forKey: key)
                    default: cache.remove(forKey: key)
                    }
                }
            }
            
            await group.waitForAll()
        }
    }
}
