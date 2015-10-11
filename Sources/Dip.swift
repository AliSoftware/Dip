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

/**
  _Dip_'s Dependency Containers allow you to do very simple **Dependency Injection**
  by associating `protocols` to concrete implementations
*/
public class DependencyContainer<TagType : Equatable> {
    private typealias InstanceType = Any
    private typealias InstanceFactory = TagType?->InstanceType
    private typealias Key = ProtoTagKey<TagType>
    
    private var dependencies = [Key : InstanceFactory]()
    private var lock: OSSpinLock = OS_SPINLOCK_INIT
    
    /**
    Designated initializer for a DependencyContainer
    
    - parameter configBlock: A configuration block in which you typically put all you `register` calls.

    - note: The `configBlock` is simply called at the end of the `init` to let you configure everything.
            It is only present for convenience to have a cleaner syntax when declaring and initializing
            your `DependencyContainer` instances.
    
    - returns: A new DependencyContainer
    */
    public init(@noescape configBlock: (DependencyContainer->Void) = { _ in }) {
        configBlock(self)
    }
    
    // MARK: - Reset all dependencies
    
    /**
    Clear all the previously registered dependencies on this container
    */
    public func reset() {
        lockAndDo {
            dependencies.removeAll()
        }
    }
    
    // MARK: Register dependencies
    
    /**
    Register a `TagType?->T` factory (which takes the tag as parameter) with a given tag
    
    - parameter tag:     The arbitrary tag to associate this factory with when registering with that protocol. `nil` to associate with any tag.
    - parameter factory: The factory to register, typed/casted as the protocol you want to register it as
    
    - note: You must cast the factory return type to the protocol you want to register it with (e.g `MyClass() as MyAPI`)
    */
    public func register<T : Any>(tag: TagType? = nil, factory: TagType?->T) {
        let key = Key(protocolType: T.self, associatedTag: tag)
        lockAndDo {
            dependencies[key] = { factory($0) }
        }
    }
    
    /**
    Register a Void->T factory (which don't care about the tag used)
    
    - parameter tag:     The arbitrary tag to associate this factory with when registering with that protocol. `nil` to associate with any tag.
    - parameter factory: The factory to register, typed/casted as the protocol you want to register it as
    
    - note: You must cast the factory return type to the protocol you want to register it with (e.g `MyClass() as MyAPI`)
    */
    public func register<T : Any>(tag: TagType? = nil, factory: Void->T) {
        let key = Key(protocolType: T.self, associatedTag: tag)
        lockAndDo {
            dependencies[key] = { _ in factory() }
        }
    }
    
    /**
    Register a Singleton instance
    
    
    - parameter tag:      The arbitrary tag to associate this instance with when registering with that protocol. `nil` to associate with any tag.
    - parameter instance: The instance to register, typed/casted as the protocol you want to register it as
    
    - note: You must cast the instance to the protocol you want to register it with (e.g `MyClass() as MyAPI`)
    */
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
    
    /**
    Resolve a dependency

     - parameter tag: The arbitrary tag to look for when resolving this protocol.
                      If no instance/factory was registered with this `tag` for this `protocol`,
                      it will resolve to the instance/factory associated with `nil` (no tag).
    */
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

    // MARK: - Private
    
    private func lockAndDo(@noescape block: Void->Void) {
        OSSpinLockLock(&lock)
        defer { OSSpinLockUnlock(&lock) }
        block()
    }
}

