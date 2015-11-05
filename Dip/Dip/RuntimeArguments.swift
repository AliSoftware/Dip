//
//  RuntimeArguments.swift
//  Dip
//
//  Created by Ilya Puchka on 04.11.15.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation

// MARK: - Register/resolve dependencies with runtime arguments

extension DependencyContainer {

    /**
     Registers factory that accepts one runtime argument. You can use up to six runtime arguments.

     - parameter tag: The arbitrary tag to associate this factory with when registering with that protocol. Pass `nil` to associate with any tag. Default value is `nil`.
     - parameter factory: The factory to register, with return type of protocol you want to register it for

     - note: You can have several factories with different number or types of arguments registered to for same type. When you resolve it container will match the type and tag as well as __number__, __types__ and __order__ of runtime arguments that you pass to `resolve` method.

     - seealso: `register(tag:factory:scope:)`
     */
    public func register<T, Arg1>(tag tag: Tag? = nil, factory: (Arg1) -> T) -> DefinitionOf<T> {
        return register(tag: tag, factory: factory, scope: .Prototype) as DefinitionOf<T>
    }
    
    /**
     Resolve a dependency with runtime argument. Factories will be matched by tag and the type to resolve as well as __number__, __types__ and __order__ of runtime arguments that you pass to this method.
     
     - parameter tag: The arbitrary tag to look for when resolving this protocol.
     - parameter arg1: First argument to be passed to factory
     
     - seealso: `resolve(tag:)`
    */
    public func resolve<T, Arg1>(tag tag: Tag? = nil, _ arg1: Arg1) -> T {
        return resolve(tag: tag) { (factory: (Arg1) -> T) in factory(arg1) }
    }

    /// - seealso: `register(:factory:scope:)`
    public func register<T, Arg1, Arg2>(tag tag: Tag? = nil, factory: (Arg1, Arg2) -> T) -> DefinitionOf<T> {
        return register(tag: tag, factory: factory, scope: .Prototype) as DefinitionOf<T>
    }
    
    /// - seealso: `resolve(tag:_:)`
    public func resolve<T, Arg1, Arg2>(tag tag: Tag? = nil, _ arg1: Arg1, _ arg2: Arg2) -> T {
        return resolve(tag: tag) { (factory: (Arg1, Arg2) -> T) in factory(arg1, arg2) }
    }
    
    public func register<T, Arg1, Arg2, Arg3>(tag tag: Tag? = nil, factory: (Arg1, Arg2, Arg3) -> T) -> DefinitionOf<T> {
        return register(tag: tag, factory: factory, scope: .Prototype) as DefinitionOf<T>
    }
    
    /// - seealso: `resolve(tag:_:)`
    public func resolve<T, Arg1, Arg2, Arg3>(tag tag: Tag? = nil, _ arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3) -> T {
        return resolve(tag: tag) { (factory: (Arg1, Arg2, Arg3) -> T) in factory(arg1, arg2, arg3) }
    }
    
    public func register<T, Arg1, Arg2, Arg3, Arg4>(tag tag: Tag? = nil, factory: (Arg1, Arg2, Arg3, Arg4) -> T) -> DefinitionOf<T> {
        return register(tag: tag, factory: factory, scope: .Prototype) as DefinitionOf<T>
    }
    
    /// - seealso: `resolve(tag:_:)`
    public func resolve<T, Arg1, Arg2, Arg3, Arg4>(tag tag: Tag? = nil, _ arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4) -> T {
        return resolve(tag: tag) { (factory: (Arg1, Arg2, Arg3, Arg4) -> T) in factory(arg1, arg2, arg3, arg4) }
    }
    
    public func register<T, Arg1, Arg2, Arg3, Arg4, Arg5>(tag tag: Tag? = nil, factory: (Arg1, Arg2, Arg3, Arg4, Arg5) -> T) -> DefinitionOf<T> {
        return register(tag: tag, factory: factory, scope: .Prototype) as DefinitionOf<T>
    }
    
    /// - seealso: `resolve(tag:_:)`
    public func resolve<T, Arg1, Arg2, Arg3, Arg4, Arg5>(tag tag: Tag? = nil, _ arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5) -> T {
        return resolve(tag: tag) { (factory: (Arg1, Arg2, Arg3, Arg4, Arg5) -> T) in factory(arg1, arg2, arg3, arg4, arg5) }
    }
    
    public func register<T, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6>(tag tag: Tag? = nil, factory: (Arg1, Arg2, Arg3, Arg4, Arg5, Arg6) -> T) -> DefinitionOf<T> {
        return register(tag: tag, factory: factory, scope: .Prototype) as DefinitionOf<T>
    }
    
    /// - seealso: `resolve(tag:_:)`
    public func resolve<T, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6>(tag tag: Tag? = nil, _ arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5, _ arg6: Arg6) -> T {
        return resolve(tag: tag) { (factory: (Arg1, Arg2, Arg3, Arg4, Arg5, Arg6) -> T) in factory(arg1, arg2, arg3, arg4, arg5, arg6) }
    }
}
