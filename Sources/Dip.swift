//
//  Dip.swift
//  Dip
//
//  Created by Olivier Halligon on 11/09/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation

public class Dependency {
    public typealias TagType = String
    typealias InstanceType = Any
    typealias InstanceFactory = TagType?->InstanceType
    
    /**
     *  Internal representation of a key to associate protocols & tags to an instance factory
     */
    private struct Key : Hashable, CustomDebugStringConvertible {
        var protocolType: Any.Type
        var associatedTag: TagType?
        
        var hashValue: Int {
            return "\(protocolType)-\(associatedTag)".hashValue
        }
        
        var debugDescription: String {
            return "type: \(protocolType), tag: \(associatedTag)"
        }
    }
    
    private static var dependencies = [Key: InstanceFactory]()
    
    // MARK: - Reset all dependencies
    
    public static func reset() {
        dependencies.removeAll()
    }
    
    // MARK: - Register dependencies
    
    /// Register a TagType?->T factory (which takes the tag as parameter)
    public static func register<T : Any>(tag: TagType? = nil, instanceFactory: TagType?->T) {
        let key = Key(protocolType: T.self, associatedTag: tag)
        dependencies[key] = { instanceFactory($0) }
    }
    
    /// Register a Void->T factory (which don't care about the tag used)
    public static func register<T : Any>(tag: TagType? = nil, instanceFactory: Void->T) {
        let key = Key(protocolType: T.self, associatedTag: tag)
        dependencies[key] = { _ in instanceFactory() }
    }
    
    /// Register a Singleton instance
    public static func register<T : Any>(tag: TagType? = nil, @autoclosure(escaping) instance instanceFactory: Void->T) {
        let key = Key(protocolType: T.self, associatedTag: tag)
        // FIXME: Make it thread-safe
        dependencies[key] = { _ in
            let instance = instanceFactory()
            dependencies[key] = { _ in return instance }
            return instance
        }
    }
    
    // MARK: - Resolve dependencies
    
    /// Resolve a dependency
    ///
    /// **Note** If a tag is given, it will try to resolve using the tag to generate a specific instance,
    ///          and fallback without the tag if not found with it
    public static func resolve<T>(tag: TagType? = nil) -> T! {
        let key = Key(protocolType: T.self, associatedTag: tag)
        let nilKey = Key(protocolType: T.self, associatedTag: nil)
        guard let factory = dependencies[key] ?? dependencies[nilKey] else {
            fatalError("No instance factory registered with \(key)")
        }
        return factory(tag) as! T
    }
}

// MARK: - Key equality

private func == (lhs: Dependency.Key, rhs: Dependency.Key) -> Bool {
    return lhs.protocolType == rhs.protocolType && lhs.associatedTag == rhs.associatedTag
}
