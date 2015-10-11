//
//  Dip.swift
//  Dip
//
//  Created by Olivier Halligon on 11/09/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation

/**
*  Internal representation of a key to associate protocols & tags to an instance factory
*/
private struct ProtoTagKey<TagType : Equatable> : Hashable, Equatable, CustomDebugStringConvertible {
    var protocolType: Any.Type
    var associatedTag: TagType?
    
    var hashValue: Int {
        return "\(protocolType)-\(associatedTag)".hashValue
    }
    
    var debugDescription: String {
        return "type: \(protocolType), tag: \(associatedTag)"
    }
}

private func ==<T>(lhs: ProtoTagKey<T>, rhs: ProtoTagKey<T>) -> Bool {
    return lhs.protocolType == rhs.protocolType && lhs.associatedTag == rhs.associatedTag
}

// MARK: - DependencyContainer

public class DependencyContainer<TagType : Equatable> {
    typealias InstanceType = Any
    typealias InstanceFactory = TagType?->InstanceType
    private typealias Key = ProtoTagKey<TagType>
    
    private var dependencies = [Key : InstanceFactory]()
    private var lock: OSSpinLock = OS_SPINLOCK_INIT
    
    public init(@noescape configBlock: (DependencyContainer->Void) = { _ in }) {
        configBlock(self)
    }
    
    // MARK: Reset all dependencies
    
    public func reset() {
        lockAndDo {
            dependencies.removeAll()
        }
    }
    
    // MARK: Register dependencies
    
    /// Register a TagType?->T factory (which takes the tag as parameter)
    public func register<T : Any>(tag: TagType? = nil, factory: TagType?->T) {
        let key = Key(protocolType: T.self, associatedTag: tag)
        lockAndDo {
            dependencies[key] = { factory($0) }
        }
    }
    
    /// Register a Void->T factory (which don't care about the tag used)
    public func register<T : Any>(tag: TagType? = nil, factory: Void->T) {
        let key = Key(protocolType: T.self, associatedTag: tag)
        lockAndDo {
            dependencies[key] = { _ in factory() }
        }
    }
    
    /// Register a Singleton instance
    public func register<T : Any>(tag: TagType? = nil, @autoclosure(escaping) instance factory: Void->T) {
        let key = Key(protocolType: T.self, associatedTag: tag)
        lockAndDo {
            dependencies[key] = { _ in
                let instance = factory()
                self.dependencies[key] = { _ in return instance }
                return instance
            }
        }
    }
    
    // MARK: Resolve dependencies
    
    /// Resolve a dependency
    ///
    /// **Note** If a tag is given, it will try to resolve using the tag to generate a specific instance,
    ///          and fallback without the tag if not found with it
    public func resolve<T>(tag: TagType? = nil) -> T! {
        let key = Key(protocolType: T.self, associatedTag: tag)
        let nilKey = Key(protocolType: T.self, associatedTag: nil)
        var resolved: T!
        lockAndDo { [unowned self] in
            guard let factory = self.dependencies[key] ?? self.dependencies[nilKey] else {
                fatalError("No instance factory registered with \(key)")
            }
            resolved = factory(tag) as! T
        }
        return resolved
    }

    private func lockAndDo(@noescape block: Void->Void) {
        OSSpinLockLock(&lock)
        defer { OSSpinLockUnlock(&lock) }
        block()
    }
}

