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
    Register a `Tag?->T` factory (which takes the tag as parameter) with a given tag
    
    - parameter tag:     The arbitrary tag to associate this factory with when registering with that protocol. `nil` to associate with any tag.
    - parameter factory: The factory to register, typed/casted as the protocol you want to register it as
    
    - note: You must cast the factory return type to the protocol you want to register it with (e.g `MyClass() as MyAPI`)
    */
    public func register<T>(tag: Tag? = nil, factory: (Tag?)->T) {
        _register(tag, factory: factory) as DefinitionOf<T>
    }
    
    /**
     Register a Void->T factory (which don't care about the tag used)
     
     - parameter tag:     The arbitrary tag to associate this factory with when registering with that protocol. `nil` to associate with any tag.
     - parameter factory: The factory to register, typed/casted as the protocol you want to register it as
     
     - note: You must cast the factory return type to the protocol you want to register it with (e.g `MyClass() as MyAPI`)
     */
    public func register<T>(tag: Tag? = nil, factory: ()->T) {
        _register(tag, factory: factory) as DefinitionOf<T>
    }
    
    /**
     Register a Singleton instance
     
     - parameter tag:      The arbitrary tag to associate this instance with when registering with that protocol. `nil` to associate with any tag.
     - parameter instance: The instance to register, typed/casted as the protocol you want to register it as
     
     - note: You must cast the instance to the protocol you want to register it with (e.g `MyClass() as MyAPI`)
     */
    public func register<T>(tag: Tag? = nil, @autoclosure(escaping) instance factory: ()->T) {
        _register(tag, factory: { factory() }, scope: .Singleton) as DefinitionOf<T>
    }
    
    private func _register<T, F>(tag: Tag? = nil, factory: F, scope: ComponentScope = .Prototype) -> DefinitionOf<T> {
        let key = DefinitionKey(protocolType: T.self, factory: F.self, associatedTag: tag)
        let definition = DefinitionOf<T>(factory: factory, scope: scope)
        lockAndDo {
            dependencies[key] = definition
        }
        return definition
    }
    
    // MARK: Resolve dependencies
    
    /**
    Resolve a dependency
    
    - parameter tag: The arbitrary tag to look for when resolving this protocol.
    If no instance/factory was registered with this `tag` for this `protocol`,
    it will resolve to the instance/factory associated with `nil` (no tag).
    */
    public func resolve<T>(tag: Tag? = nil) -> T {
        return _resolve(tag) { (factory: ()->T) in factory() }
    }
    
    private func _resolve<T, F>(tag: Tag? = nil, builder: F->T) -> T {
        let key = DefinitionKey(protocolType: T.self, factory: F.self, associatedTag: tag)
        let nilTagKey = DefinitionKey(protocolType: T.self, factory: F.self, associatedTag: nil)
        
        var resolved: T!
        lockAndDo { [unowned self] in
            resolved = self._resolve(key, nilTagKey: nilTagKey, builder: builder)
        }
        return resolved
    }
    
    private func _resolve<T, F>(key: DefinitionKey, nilTagKey: DefinitionKey, builder: F->T) -> T {
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

/**
 *  Internal representation of a key to associate protocols & tags to an instance factory
 */
private struct DefinitionKey : Hashable, Equatable, CustomDebugStringConvertible {
    var protocolType: Any.Type
    var factory: Any.Type
    var associatedTag: DependencyContainer.Tag?
    
    var hashValue: Int {
        return "\(protocolType)-\(factory)-\(associatedTag)".hashValue
    }
    
    var debugDescription: String {
        return "type: \(protocolType), factory: \(factory), tag: \(associatedTag)"
    }
}

private func ==(lhs: DefinitionKey, rhs: DefinitionKey) -> Bool {
    return
        lhs.protocolType == rhs.protocolType &&
            lhs.factory == rhs.factory &&
            lhs.associatedTag == rhs.associatedTag
}

///Describes the lifecycle of instances created by container.
public enum ComponentScope {
    /// (default) Indicates that new instance of the component will be always created.
    case Prototype
    /// Indicates that resolved component should be retained by container and always reused.
    case Singleton
}

public final class DefinitionOf<T>: Definition {
    private let factory: Any
    private let scope: ComponentScope
    
    init(factory: Any, scope: ComponentScope = .Prototype) {
        self.factory = factory
        self.scope = scope
    }
    
    private var resolvedInstance: T? {
        get {
            guard scope == .Singleton else { return nil }
            return _resolvedInstance
        }
        set {
            guard scope == .Singleton else { return }
            _resolvedInstance = newValue
        }
    }
    
    private var _resolvedInstance: T?
}

private protocol Definition {}

// MARK: - Register dependencies with runtime arguments
extension DependencyContainer {
    public func register<T, Arg1>(tag: Tag? = nil, factory: (Arg1) -> T) {
        _register(tag, factory: factory) as DefinitionOf<T>
    }
    
    public func resolve<T, Arg1>(tag: Tag? = nil, _ arg1: Arg1) -> T {
        return _resolve(tag) { (factory: (Arg1) -> T) in factory(arg1) }
    }
    
    public func register<T, Arg1, Arg2>(tag: Tag? = nil, factory: (Arg1, Arg2) -> T) {
        _register(tag, factory: factory) as DefinitionOf<T>
    }
    
    public func resolve<T, Arg1, Arg2>(tag: Tag? = nil, _ arg1: Arg1, _ arg2: Arg2) -> T {
        return _resolve(tag) { (factory: (Arg1, Arg2) -> T) in factory(arg1, arg2) }
    }
    
    public func register<T, Arg1, Arg2, Arg3>(tag: Tag? = nil, factory: (Arg1, Arg2, Arg3) -> T) {
        _register(tag, factory: factory) as DefinitionOf<T>
    }
    
    public func resolve<T, Arg1, Arg2, Arg3>(tag: Tag? = nil, _ arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3) -> T {
        return _resolve(tag) { (factory: (Arg1, Arg2, Arg3) -> T) in factory(arg1, arg2, arg3) }
    }
    
    public func register<T, Arg1, Arg2, Arg3, Arg4>(tag: Tag? = nil, factory: (Arg1, Arg2, Arg3, Arg4) -> T) {
        _register(tag, factory: factory) as DefinitionOf<T>
    }
    
    public func resolve<T, Arg1, Arg2, Arg3, Arg4>(tag: Tag? = nil, _ arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4) -> T {
        return _resolve(tag) { (factory: (Arg1, Arg2, Arg3, Arg4) -> T) in factory(arg1, arg2, arg3, arg4) }
    }
    
    public func register<T, Arg1, Arg2, Arg3, Arg4, Arg5>(tag: Tag? = nil, factory: (Arg1, Arg2, Arg3, Arg4, Arg5) -> T) {
        _register(tag, factory: factory) as DefinitionOf<T>
    }
    
    public func resolve<T, Arg1, Arg2, Arg3, Arg4, Arg5>(tag: Tag? = nil, _ arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, arg5: Arg5) -> T {
        return _resolve(tag) { (factory: (Arg1, Arg2, Arg3, Arg4, Arg5) -> T) in factory(arg1, arg2, arg3, arg4, arg5) }
    }
    
    public func register<T, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6>(tag: Tag? = nil, factory: (Arg1, Arg2, Arg3, Arg4, Arg5, Arg6) -> T) {
        _register(tag, factory: factory) as DefinitionOf<T>
    }
    
    public func resolve<T, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6>(tag: Tag? = nil, _ arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5, _ arg6: Arg6) -> T {
        return _resolve(tag) { (factory: (Arg1, Arg2, Arg3, Arg4, Arg5, Arg6) -> T) in factory(arg1, arg2, arg3, arg4, arg5, arg6) }
    }
}
