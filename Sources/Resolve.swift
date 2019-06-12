//
// Dip
//
// Copyright (c) 2015 Olivier Halligon <olivier@halligon.net>
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

extension DependencyContainer {
  
  /**
   Resolve an instance of type `T`.
   
   If no matching definition was registered with provided `tag`,
   container will lookup definition associated with `nil` tag.
   
   - parameter tag: The arbitrary tag to use to lookup definition.
   
   - throws: `DipError.DefinitionNotFound`, `DipError.AutoInjectionFailed`, `DipError.AmbiguousDefinitions`, `DipError.InvalidType`
   
   - returns: An instance of type `T`.
   
   **Example**:
   ```swift
   let service = try! container.resolve() as Service
   let service = try! container.resolve(tag: "service") as Service
   let service: Service = try! container.resolve()
   ```
   
   - seealso: `register(_:type:tag:factory:)`
   */
  public func resolve<T>(tag: DependencyTagConvertible? = nil) throws -> T {
    return try _resolve(tag: tag) { (factory: () throws -> T) in try factory() }
  }

  /**
   Resolve an instance of requested type. Weakly-typed alternative of `resolve(tag:)`
   
   - warning: This method does not make any type checks, so there is no guaranty that
              resulting instance is actually an instance of requested type.
              That can happen if you register forwarded type that is not implemented by resolved instance.
   
   - parameters:
      - type: Type to resolve
      - tag: The arbitrary tag to use to lookup definition.
   
   - throws: `DipError.DefinitionNotFound`, `DipError.AutoInjectionFailed`, `DipError.AmbiguousDefinitions`, `DipError.InvalidType`
   
   - returns: An instance of requested type.

   **Example**:
   ```swift
   let service = try! container.resolve(Service.self) as! Service
   let service = try! container.resolve(Service.self, tag: "service") as! Service
   ```

   - seealso: `resolve(tag:)`, `register(_:type:tag:factory:)`
   */
  public func resolve(_ type: Any.Type, tag: DependencyTagConvertible? = nil) throws -> Any {
    return try resolve(type, tag: tag) { (factory: () throws -> Any) in try factory() }
  }
  
  /**
   Resolve an instance of type `T` using generic builder closure that accepts generic factory and returns created instance.
   
   - parameters:
      - tag: The arbitrary tag to use to lookup definition.
      - builder: Generic closure that accepts generic factory and returns inctance created by that factory.
   
   - throws: `DipError.DefinitionNotFound`, `DipError.AutoInjectionFailed`, `DipError.AmbiguousDefinitions`, `DipError.InvalidType`
   
   - returns: An instance of type `T`.
   
   - note: You _should not_ call this method directly, instead call any of other 
           `resolve(tag:)` or `resolve(tag:withArguments:)` methods.
           You _should_ use this method only to resolve dependency with more runtime arguments than
           _Dip_ supports (currently it's up to six) like in the following example:
   
   ```swift
   public func resolve<T, A, B, C, ...>(tag: Tag? = nil, _ arg1: A, _ arg2: B, _ arg3: C, ...) throws -> T {
     return try resolve(tag: tag) { factory in factory(arg1, arg2, arg3, ...) }
   }
   ```
   
   Though before you do so you should probably review your design and try to reduce the number of dependencies.
   */
  public func resolve<T, U>(tag: DependencyTagConvertible? = nil, builder: ((U) throws -> T) throws -> T) throws -> T {
    return try _resolve(tag: tag, builder: builder)
  }

  public func resolve<T>(tag: DependencyTagConvertible? = nil, builder: (() throws -> T) throws -> T) throws -> T {
    return try _resolve(tag: tag, builder: builder)
  }

  /**
   Resolve an instance of provided type using builder closure. Weakly-typed alternative of `resolve(tag:builder:)`
   
   - seealso: `resolve(tag:builder:)`
  */
  public func resolve<U>(_ type: Any.Type, tag: DependencyTagConvertible? = nil, builder: ((U) throws -> Any) throws -> Any) throws -> Any {
    return try _resolve(type: type, tag: tag, builder: builder)
  }

  public func resolve(_ type: Any.Type, tag: DependencyTagConvertible? = nil, builder: (() throws -> Any) throws -> Any) throws -> Any {
    return try _resolve(type: type, tag: tag, builder: builder)
  }

}

extension DependencyContainer {
  
  func _resolve<T>(tag aTag: DependencyTagConvertible? = nil, builder: (() throws -> T) throws -> T) throws -> T {
    return try resolve(T.self, tag: aTag, builder: { factory in
      try withoutActuallyEscaping(factory, do: { (factory) throws -> T in
        try builder({ try factory() as! T })
      })
    }) as! T
  }
  
  func _resolve(type aType: Any.Type, tag: DependencyTagConvertible? = nil, builder: (() throws -> Any) throws -> Any) throws -> Any {
    let key = DefinitionKey(type: aType, typeOfArguments: Void.self, tag: tag?.dependencyTag)
    
    return try inContext(key:key, injectedInType: context?.resolvingType) {
      try self._resolve(key: key, builder: { definition in
        try builder { try definition.weakFactory(()) }
      })
    }
  }
  
  func _resolve<T, U>(tag aTag: DependencyTagConvertible? = nil, builder: ((U) throws -> T) throws -> T) throws -> T {
    return try resolve(T.self, tag: aTag, builder: { factory in
      try withoutActuallyEscaping(factory, do: { (factory) throws -> T in
        try builder({ try factory($0) as! T })
      })
    }) as! T
  }
  
  func _resolve<U>(type aType: Any.Type, tag: DependencyTagConvertible? = nil, builder: ((U) throws -> Any) throws -> Any) throws -> Any {
    let key = DefinitionKey(type: aType, typeOfArguments: U.self, tag: tag?.dependencyTag)
    
    return try inContext(key:key, injectedInType: context?.resolvingType) {
      try self._resolve(key: key, builder: { definition in
        try builder(definition.weakFactory)
      })
    }
  }
  
  /// Lookup definition by the key and use it to resolve instance. Fallback to the key with `nil` tag.
  func _resolve<T>(key aKey: DefinitionKey, builder: (_Definition) throws -> T) throws -> T {
    guard let matching = self.definition(matching: aKey) else {
      do {
        return try autowire(key: aKey)
      } catch {
        if let resolved = collaboratingResolve(key: aKey, builder: builder) {
          return resolved
        } else {
          throw error
        }
      }
    }
    
    let (key, definition) = matching
    
    //first search for already resolved instance for this type or any of forwarding types
    if let previouslyResolved: T = previouslyResolved(for: definition, key: key) {
      log(level: .Verbose, "Reusing previously resolved instance \(previouslyResolved)")
      return previouslyResolved
    }
    
    if let context = context { log(level: .Verbose, context) }
    var resolvedInstance = try builder(definition)
    
    /*
     Strongly-typed `resolve(tag:builder:)` calls weakly-typed `resolve(_:tag:builder:)`,
     so `T` will be `Any` at runtime, erasing type information when this method returns.
     When we try to cast result of `Any` to generic type T Swift fails to cast it.
     The same happens in the following code snippet:
     
     let optService: Service? = ServiceImp()
     let anyService: Any = optService
     let service: Service = anyService as! Service
     
     That happens because when Optional is casted to Any Swift can not implicitly unwrap it with as operator.
     As a workaround we detect boxing here and unwrap it so that we return not a box, but wrapped instance.
     */
    if let box = resolvedInstance as? BoxType, let unboxedAny = box.unboxed, let unboxed = unboxedAny as? T {
      resolvedInstance = unboxed
    }
    
    //when builder calls factory it will in turn resolve sub-dependencies (if there are any)
    //when it returns instance that we try to resolve here can be already resolved
    //so we return it, throwing away instance created by previous call to builder
    if let previouslyResolved: T = previouslyResolved(for: definition, key: key) {
      log(level: .Verbose, "Reusing previously resolved instance \(previouslyResolved)")
      return previouslyResolved
    }
    
    resolvedInstances[key: key, inScope: definition.scope, context: context] = resolvedInstance
    
    if let resolvable = resolvedInstance as? Resolvable {
      resolvedInstances.resolvableInstances.append(resolvable)
      resolvable.resolveDependencies(self)
    }

    let shouldAutoInject = definition.autoInjectProperties ?? self.autoInjectProperties
    if shouldAutoInject {
      try autoInjectProperties(in: resolvedInstance)
    }
    try definition.resolveProperties(of: resolvedInstance, container: self)
    
    log(level: .Verbose, "Resolved type \(key.type) with \(resolvedInstance)")
    return resolvedInstance
  }
  
  private func previouslyResolved<T>(for definition: _Definition, key: DefinitionKey) -> T? {
    //first check if exact key was already resolved
    if let previouslyResolved: T = resolvedInstances[key: key, inScope: definition.scope, context: context] {
      return previouslyResolved
    }
    //then check if any related type was already resolved
    let keys = definition.implementingTypes.map({
      DefinitionKey(type: $0, typeOfArguments: key.typeOfArguments, tag: key.tag)
    })
    for key in keys {
      if let previouslyResolved: T = resolvedInstances[key: key, inScope: definition.scope, context: context] {
        return previouslyResolved
      }
    }
    return nil
  }
  
  /// Searches for definition that matches provided key
  func definition(matching key: DefinitionKey) -> KeyDefinitionPair? {
    if let definition = (self.definitions[key] ?? self.definitions[key.tagged(with: nil)]) {
      return (key, definition)
    }
    
    //if no definition registered for exact type try to find type-forwarding definition that can resolve the type
    //that will actually happen only when resolving optionals
    if definitions.filter({ $0.0.type == key.type }).isEmpty {
      return typeForwardingDefinition(forKey: key)
    }
    return nil
  }
  
}

///Pool to hold instances, created during call to `resolve()`.
///Before `resolve()` returns pool is drained.
class ResolvedInstances {
  
  var resolvedInstances = [DefinitionKey: Any]()
  var resolvableInstances = [Resolvable]()
  
  //singletons are stored using reference type wrapper to be able to share them between containers
  var sharedSingletonsBox = Box<[DefinitionKey: Any]>([:])
  var sharedSingletons: [DefinitionKey: Any] {
    get { return sharedSingletonsBox.unboxed }
    set { sharedSingletonsBox.unboxed = newValue }
  }
  var singletons = [DefinitionKey: Any]()
  
  var sharedWeakSingletonsBox = Box<[DefinitionKey: Any]>([:])
  var sharedWeakSingletons: [DefinitionKey: Any] {
    get { return sharedWeakSingletonsBox.unboxed }
    set { sharedWeakSingletonsBox.unboxed = newValue }
  }
  var weakSingletons = [DefinitionKey: Any]()
  
  subscript<T>(key key: DefinitionKey, inScope scope: ComponentScope, context context: DependencyContainer.Context) -> T? {
    get {
      let instance: Any?
      switch scope {
      case .singleton, .eagerSingleton:
        instance = context.inCollaboration ? sharedSingletons[key] : singletons[key]
      case .weakSingleton:
        let singletons = context.inCollaboration ? sharedWeakSingletons : weakSingletons
        if let boxed = singletons[key] as? WeakBoxType { instance = boxed.unboxed }
        else { instance = singletons[key] }
      case .shared:
        instance = resolvedInstances[key]
      case .unique:
        return nil
      }
      return instance.flatMap { $0 as? T }
    }
    set {
      switch scope {
      case .singleton, .eagerSingleton:
        sharedSingletons[key] = newValue
        singletons[key] = newValue
      case .weakSingleton:
        sharedWeakSingletons[key] = newValue
        weakSingletons[key] = newValue
      case .shared:
        resolvedInstances[key] = newValue
      case .unique:
        break
      }
    }
  }
  
}

//MARK: - Resolvable

/// Resolvable protocol provides some extension points for resolving dependencies with property injection.
public protocol Resolvable {
  /// This method will be called right after instance is created by the container.
  func resolveDependencies(_ container: DependencyContainer)
  /// This method will be called when all dependencies of the instance are resolved.
  /// When resolving objects graph the last resolved instance will receive this callback first.
  func didResolveDependencies()
}

extension Resolvable {
  func resolveDependencies(_ container: DependencyContainer) {}
  func didResolveDependencies() {}
}
