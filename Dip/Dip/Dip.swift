//
//  Dip.swift
//  Dip
//
//  Created by Olivier Halligon on 11/09/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation

// MARK: - DependencyContainer

/**
 * _Dip_'s Dependency Containers allow you to do very simple **Dependency Injection**
 * by associating `protocols` to concrete implementations
 */
public class DependencyContainer {
  
    /**
     Use a tag in case you need to register multiple instances or factories
     with the same protocol, to differentiate them. Tags can be either String
     or Int, to your convenience.
     */
    public enum Tag: Equatable {
        case String(StringLiteralType)
        case Int(IntegerLiteralType)
    }

    private var dependencies = [DefinitionKey : Definition]()
    private var lock: OSSpinLock = OS_SPINLOCK_INIT
    
    /**
     Designated initializer for a DependencyContainer
     
     - parameter configBlock: A configuration block in which you typically put all you `register` calls.
     
     - note: The `configBlock` is simply called at the end of the `init` to let you configure everything. 
     It is only present for convenience to have a cleaner syntax when declaring and initializing 
     your `DependencyContainer` instances.
     
     - returns: A new DependencyContainer.
     */
    public init(@noescape configBlock: (DependencyContainer->()) = { _ in }) {
        configBlock(self)
    }
    
    // MARK: - Reset all dependencies
    
    /**
    Clear all the previously registered dependencies on this container.
    */
    public func reset() {
        lockAndDo {
            dependencies.removeAll()
        }
    }
    
    // MARK: Register dependencies
    
    /**
     Register a Void->T factory associated with optional tag.
     
     - parameter tag: The arbitrary tag to associate this factory with when registering with that protocol. Pass `nil` to associate with any tag. Default value is `nil`.
     - parameter factory: The factory to register, with return type of protocol you want to register it for
     
     - note: You must cast the factory return type to the protocol you want to register it with (e.g `MyClass() as MyAPI`)
     */
    public func register<T>(tag tag: Tag? = nil, factory: ()->T) -> DefinitionOf<T> {
        return register(tag: tag, factory: factory, scope: .Prototype) as DefinitionOf<T>
    }
    
    /**
     Register a Singleton instance associated with optional tag.
     
     - parameter tag: The arbitrary tag to associate this instance with when registering with that protocol. `nil` to associate with any tag.
     - parameter instance: The instance to register, with return type of protocol you want to register it for
     
     - note: You must cast the instance to the protocol you want to register it with (e.g `MyClass() as MyAPI`)
     */
    public func register<T>(tag tag: Tag? = nil, @autoclosure(escaping) instance factory: ()->T) -> DefinitionOf<T> {
        return register(tag: tag, factory: { factory() }, scope: .Singleton)
    }
    
    /**
     Register generic factory associated with optional tag.

     - parameter tag: The arbitrary tag to look for when resolving this protocol.
     - parameter factory: generic factory that should be used to create concrete instance of type
     - parameter scope: scope of the component. Default value is `Prototype`

     -note: You should not call this method directly, instead call any of other `register` methods. You _should_ use this method only to register dependency with more runtime arguments than _Dip_ supports (currently it's up to six) like in this example:
     
     ```swift
     public func register<T, Arg1, Arg2, Arg3, ...>(tag: Tag? = nil, factory: (Arg1, Arg2, Arg3, ...) -> T) -> DefinitionOf<T> {
         return register(tag, factory: factory, scope: .Prototype) as DefinitionOf<T>
     }
     ```
     
     Though before you do that you should probably review your design and try to reduce number of depnedencies.
     
     */
    public func register<T, F>(tag tag: Tag? = nil, factory: F, scope: ComponentScope) -> DefinitionOf<T> {
        let key = DefinitionKey(protocolType: T.self, factoryType: F.self, associatedTag: tag)
        let definition = DefinitionOf<T>(factory: factory, scope: scope)
        lockAndDo {
            dependencies[key] = definition
        }
        return definition
    }
    
    // MARK: Resolve dependencies
    
    /**
    Resolve a dependency. 
    
    If no instance/factory was registered with this `tag` for this `protocol`, it will try to resolve the instance/factory associated with `nil` (no tag).
    
    - parameter tag: The arbitrary tag to look for when resolving this protocol.
    */
    public func resolve<T>(tag tag: Tag? = nil) -> T {
        return resolve(tag: tag) { (factory: ()->T) in factory() }
    }
    
    /**
     Resolve a dependency using generic builder closure that accepts generic factory and returns created instance.

     - parameter tag: The arbitrary tag to look for when resolving this protocol.
     - parameter builder: Generic closure that accepts generic factory and returns inctance produced by that factory
     
     - note: You should not call this method directly, instead call any of other `resolve` methods. You _should_ use this method only to resolve dependency with more runtime arguments than _Dip_ supports (currently it's up to six) like in this example:
     
     ```swift
     public func resolve<T, Arg1, Arg2, Arg3, ...>(tag tag: Tag? = nil, _ arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, ...) -> T {
         return resolve(tag) { (factory: (Arg1, Arg2, Arg3, ...) -> T) in factory(arg1, arg2, arg3, ...) }
     }
     ```
     
     Though before you do that you should probably review your design and try to reduce number of depnedencies.
     
    */
    public func resolve<T, F>(tag tag: Tag? = nil, builder: F->T) -> T {
        let key = DefinitionKey(protocolType: T.self, factoryType: F.self, associatedTag: tag)
        let nilTagKey = tag.map { _ in DefinitionKey(protocolType: T.self, factoryType: F.self, associatedTag: nil) }
        
        var resolved: T!
        lockAndDo { [unowned self] in
            resolved = self._resolve(key, nilTagKey: nilTagKey, builder: builder)
        }
        return resolved
    }
    
    /// Actually resolve dependency
    private func _resolve<T, F>(key: DefinitionKey, nilTagKey: DefinitionKey?, builder: F->T) -> T {
        guard let definition = (self.dependencies[key] ?? self.dependencies[nilTagKey]) as? DefinitionOf<T> else {
            fatalError("No instance factory registered with \(key) or \(nilTagKey)")
        }
        
        if let resolvedInstance = definition.resolvedInstance {
            return resolvedInstance
        }
        else {
            let resolved = builder(definition.factory as! F)
            definition.resolvedInstance = resolved
            return resolved
        }
    }
    
    // MARK: - Private
    
    private func lockAndDo(@noescape block: Void->Void) {
        OSSpinLockLock(&lock)
        defer { OSSpinLockUnlock(&lock) }
        block()
    }
}

extension DependencyContainer.Tag: IntegerLiteralConvertible {
    public init(integerLiteral value: IntegerLiteralType) {
        self = .Int(value)
    }
}

extension DependencyContainer.Tag: StringLiteralConvertible {
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    public typealias UnicodeScalarLiteralType = StringLiteralType
    
    public init(stringLiteral value: StringLiteralType) {
        self = .String(value)
    }
    
    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        self.init(stringLiteral: value)
    }
    
    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        self.init(stringLiteral: value)
    }
}

public func ==(lhs: DependencyContainer.Tag, rhs: DependencyContainer.Tag) -> Bool {
    switch (lhs, rhs) {
    case let (.String(lhsString), .String(rhsString)):
        return lhsString == rhsString
    case let (.Int(lhsInt), .Int(rhsInt)):
        return lhsInt == rhsInt
    default:
        return false
    }
}

extension Dictionary {
    subscript(key: Key?) -> Value! {
        guard let key = key else { return nil }
        return self[key]
    }
}

