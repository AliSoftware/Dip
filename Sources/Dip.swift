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

/**
`DependencyContainer` allows you to do _Dependency Injection_
by associating abstractions to concrete implementations.
*/
public final class DependencyContainer {
  
  /**
   Use a tag in case you need to register multiple factories fo the same type,
   to differentiate them. Tags can be either String or Int, to your convenience.
   
   - seealso: `DependencyTagConvertible`
   */
  public enum Tag: Equatable {
    case String(StringLiteralType)
    case Int(IntegerLiteralType)
  }
  
  private(set) public var context: Context!
  var definitions = [DefinitionKey : _Definition]()
  private let resolvedInstances = ResolvedInstances()
  private let lock = RecursiveLock()
  
  private(set) var bootstrapped = false
  private var bootstrapQueue: [() throws -> ()] = []

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
  
  /**
   Call this method to complete container setup. After container is bootstrapped
   you can not add or remove definitions. Trying to do so will cause runtime exception.
   You can completely reset container, after reset you can bootstrap it again. 
   During bootsrap container will instantiate components registered with `EagerSingleton` scope.
   
   - throws: `DipError` if failed to instantiate any component
  */
  public func bootstrap() throws {
    try threadSafe {
      bootstrapped = true
      try bootstrapQueue.forEach({ try $0() })
      bootstrapQueue.removeAll()
    }
  }
  
  private func threadSafe<T>(@noescape closure: () throws -> T) rethrows -> T {
    lock.lock()
    defer {
      lock.unlock()
    }
    return try closure()
  }
  
}

extension DependencyContainer {
  
  /**
   Context provides contextual information about resolution process.
   
   You can use the context for debugging or to pass through tag when you explicitly resolve dependencies.
   When auto-wiring or auto-injecting tag will be implicitly passed through by the container.
   For auto-injected properties you can disable that by providing tag (some value or `nil`) when defining property.
   
   **Example**:
   
   ```swift
   class SomeServiceImp: SomeService {
     //container will pass through the tag ("tag") used to resolve containing instance to resolve this property
     let injected = Injected<SomeDependency>()
   
     //container will use "someTag" tag to resolve this property
     let injectedTagged = Injected<SomeDependency>(tag: "someTag")
   
     //container will use `nil` tag to resolve this property
     let injectedNilTag = Injected<SomeDependency>(tag: nil)
   }
   
   container.register {
     //container will pass through the tag ("tag") used to resolve SomeService to resolve $0
     SomeServiceImp(dependency: $0) as SomeService
   }.resolveDependencies { container, service in
     //container will use `nil` tag to resolve this dependency
     self.dependency = try container.resolve() as SomeDependency
   
     //container will use current context tag ("tag") to resolve this dependency
     self.taggedDependency = try container.resolve(tag: container.context.tag) as SomeDependency
   }
   
   //container will use "tag" to resolve this instance
   let service = try! container.resolve(tag: "tag") as SomeService
   
   ```
   */
  public struct Context {
    
    /// The tag used to resolve currently resolving type.
    private(set) public var tag: Tag?
    
    /// The type that caused currently resolving type to be resolved.
    /// `nil` for root object in a dependencies graph.
    private(set) public var injectedInType: Any.Type?
    
    /// The label of the property where resolved instance will be auto-injected.
    private(set) public var injectedInProperty: String?
    
    /// Currently resolving type.
    private(set) public var resolvingType: Any.Type
    
    private var depth: Int = 0
    
    init(tag: Tag?, injectedInType: Any.Type?, injectedInProperty: String?, resolvingType: Any.Type) {
      self.tag = tag
      self.injectedInType = injectedInType
      self.injectedInProperty = injectedInProperty
      self.resolvingType = resolvingType
    }
  }

  /// Pushes new context created with provided values and calls block. When block returns previous context is restored.
  /// For `nil` values (except tag) new context will use values from the current context.
  /// Will releas resolved instances and call `Resolvable` callbacks when popped to initial context.
  func inContext<T>(tag: Tag?, resolvingType: Any.Type? = nil, injectedInProperty: String? = nil, @noescape block: () throws -> T) throws -> T {
    return try threadSafe {
      let currentContext = self.context
      
      defer {
        self.context = currentContext
        
        if self.context == nil {
          // We call didResolveDependencies only at this point
          // because this is a point when dependencies graph is complete.
          for resolvedInstance in self.resolvedInstances.resolvableInstances.reverse() {
            resolvedInstance.didResolveDependencies()
          }
          self.resolvedInstances.resolvedInstances.removeAll()
          self.resolvedInstances.resolvableInstances.removeAll()
        }
      }
      
      if currentContext ==  nil {
        self.context = Context(tag: tag, injectedInType: nil, injectedInProperty: nil, resolvingType: resolvingType ?? T.self)
      }
      else {
        self.context = Context(
          tag: tag,
          injectedInType: currentContext.injectedInType ?? currentContext.resolvingType,
          injectedInProperty: injectedInProperty ?? currentContext.injectedInProperty,
          resolvingType: resolvingType ?? T.self
        )
        self.context.depth = currentContext.depth + 1
      }
      
      return try block()
    }
  }

}

// MARK: - Registering definitions

extension DependencyContainer {
  
  /**
   Register factory for type `T` and associate it with an optional tag.

   - parameters:
      - tag: The arbitrary tag to associate this factory with. Pass `nil` to associate with any tag. Default value is `nil`.
      - scope: The scope to use for instance created by the factory.
      - factory: The factory to register.

   - returns: A registered definition.

   - note: You should cast the factory return type to the protocol you want to register it for
           (unless you want to register concrete type).

   **Example**:
   ```swift
   container.register { ServiceImp() as Service }
   container.register(tag: "service") { ServiceImp() as Service }
   container.register(.ObjectGraph) { ServiceImp() as Service }
   container.register { try ClientImp(service: container.resolve() as Service) as Client }
   ```
   */
  public func register<T>(tag tag: DependencyTagConvertible? = nil, _ scope: ComponentScope = .Prototype, factory: () throws -> T) -> DefinitionOf<T, () throws -> T> {
    let definition = DefinitionBuilder<T, ()> {
      $0.scope = scope
      $0.factory = factory
    }.build()
    register(definition, forTag: tag)
    return definition
  }
  
  /**
   Register generic factory and auto-wiring factory and associate it with an optional tag.
   
   - parameters:
      - tag: The arbitrary tag to associate this factory with. Pass `nil` to associate with any tag. Default value is `nil`.
      - scope: The scope to use for instance created by the factory.
      - factory: The factory to register.
      - numberOfArguments: The number of factory arguments. Will be used on auto-wiring to sort definitions.
      - autoWiringFactory: The factory to be used on auto-wiring to resolve component.
   
   - returns: A registered definition.
   
   - note: You _should not_ call this method directly, instead call any of other `register` methods.
   You _should_ use this method only to register dependency with more runtime arguments
   than _Dip_ supports (currently it's up to six) like in the following example:
   
   ```swift
   public func register<T, A, B, C, ...>(tag: Tag? = nil, scope: ComponentScope = .Prototype, factory: (A, B, C, ...) throws -> T) -> DefinitionOf<T, (A, B, C, ...) throws -> T> {
     return registerFactory(tag: tag, scope: scope, factory: factory, numberOfArguments: ...) { container, tag in
        try factory(container.resolve(tag: tag), ...)
      }
   }
   ```
   
   Though before you do so you should probably review your design and try to reduce number of depnedencies.
   */
  public func registerFactory<T, U>(tag tag: DependencyTagConvertible? = nil, scope: ComponentScope, factory: U throws -> T, numberOfArguments: Int, autoWiringFactory: (DependencyContainer, Tag?) throws -> T) -> DefinitionOf<T, U throws -> T> {
    let definition = DefinitionBuilder<T, U> {
      $0.scope = scope
      $0.factory = factory
      $0.numberOfArguments = numberOfArguments
      $0.autoWiringFactory = autoWiringFactory
    }.build()
    register(definition, forTag: tag)
    return definition
  }

  /**
   Register definiton in the container and associate it with an optional tag.
   Will override already registered definition for the same type and factory, associated with the same tag.
   
   - parameters:
      - tag: The arbitrary tag to associate this definition with. Pass `nil` to associate with any tag. Default value is `nil`.
      - definition: The definition to register in the container.
   
   */
  public func register<T, U>(definition: DefinitionOf<T, U throws -> T>, forTag tag: DependencyTagConvertible? = nil) {
    let key = DefinitionKey(protocolType: T.self, argumentsType: U.self, associatedTag: tag?.dependencyTag)
    register(definition, forKey: key)

    if case .EagerSingleton = definition.scope {
      bootstrapQueue.append({ let _ = try self.resolve(tag: tag) as T })
    }
  }
  
  /// Actually register definition
  func register(definition: _Definition, forKey key: DefinitionKey) {
    precondition(!bootstrapped, "You can not modify container's definitions after it was bootstrapped.")
    
    threadSafe {
      definitions[key] = definition
      resolvedInstances.singletons[key] = nil
    }
  }
  
}

// MARK: - Resolve dependencies

extension DependencyContainer {
  
  /**
   Resolve a an instance of type `T`.
   
   If no matching definition was registered with provided `tag`,
   container will lookup definition associated with `nil` tag.
   
   - parameter tag: The arbitrary tag to use to lookup definition.
   
   - throws: `DipError.DefinitionNotFound`, `DipError.AutoInjectionFailed`, `DipError.AmbiguousDefinitions`
   
   - returns: An instance of type `T`.
   
   - seealso: `register(tag:_:factory:)`
   
   **Example**:
   ```swift
   let service = try! container.resolve() as Service
   let service = try! container.resolve(tag: "service") as Service
   let service: Service = try! container.resolve()
   ```
   
   */
  public func resolve<T>(tag tag: DependencyTagConvertible? = nil) throws -> T {
    return try resolve(tag: tag) { (factory: () throws -> T) in try factory() }
  }
  
  /**
   Resolve a an instance of provided type. Weakly-typed alternative of `resolve(tag:)`
   
   - warning: This method does not make any type checks, so there is no guaranty that
              resulting instance is actually an instance of requrested type.
              That can happen if you register forwarded type that is not implemented by resolved instance.
   
   **Example**:
   ```swift
   let service = try! container.resolve(Service.self) as! Service
   let service = try! container.resolve(Service.self, tag: "service") as! Service
   ```
   
   - seealso: `resolve(tag:)`, `register(tag:_:factory:)`, `implements(_:)`
   */
  public func resolve(type: Any.Type, tag: DependencyTagConvertible? = nil) throws -> Any {
    return try self.resolve(type, tag: tag) { factory in try factory(())}
  }

  /**
   Resolve an instance of type `T` using generic builder closure that accepts generic factory and returns created instance.
   
   - parameters:
      - tag: The arbitrary tag to use to lookup definition.
      - builder: Generic closure that accepts generic factory and returns inctance created by that factory.
   
   - throws: `DipError.DefinitionNotFound`, `DipError.AutoInjectionFailed`, `DipError.AmbiguousDefinitions`
   
   - returns: An instance of type `T`.
   
   - note: You _should not_ call this method directly, instead call any of other 
           `resolve(tag:)` or `resolve(tag:withArguments:)` methods.
           You _should_ use this method only to resolve dependency with more runtime arguments than
           _Dip_ supports (currently it's up to six) like in the following example:
   
   ```swift
   public func resolve<T, A, B, C, ...>(tag tag: Tag? = nil, _ arg1: A, _ arg2: B, _ arg3: C, ...) throws -> T {
     return try resolve(tag: tag) { factory in factory(arg1, arg2, arg3, ...) }
   }
   ```
   
   Though before you do so you should probably review your design and try to reduce the number of dependencies.
   */
  public func resolve<T, U>(tag tag: DependencyTagConvertible? = nil, builder: (U throws -> T) throws -> T) throws -> T {
    let resolved = try resolve(T.self, tag: tag, builder: { (factory: (U throws -> Any)) in
      try builder({
        guard let resolved = try factory($0) as? T else {
          let key = DefinitionKey(protocolType: T.self, argumentsType: U.self, associatedTag: tag?.dependencyTag)
          throw DipError.DefinitionNotFound(key: key)
        }
        return resolved
      })
    })
    
    return resolved as! T
  }
  
  /**
   Resolve an instance of provided type using builder closure. Weakly-typed alternative of `resolve(tag:builder:)`
   
   - seealso: `resolve(tag:builder:)`
  */
  public func resolve<U>(type: Any.Type, tag: DependencyTagConvertible? = nil, builder: (U throws -> Any) throws -> Any) throws -> Any {
    return try inContext(tag?.dependencyTag, resolvingType: type) {
      let key = DefinitionKey(protocolType: type, argumentsType: U.self, associatedTag: tag?.dependencyTag)
      
      return try _resolveKey(key, builder: { definition throws -> Any in
        try builder(definition.weakFactory)
      })
    }
  }
  
  /// Lookup definition by the key and use it to resolve instance. Fallback to the key with `nil` tag.
  func _resolveKey<T>(key: DefinitionKey, builder: _Definition throws -> T) throws -> T {
    guard let matching = definition(matching: key) else {
      //if no definition found - auto-wire
      return try _autowire(key)
    }
    
    do {
      return try _resolveDefinition(matching.definition, forKey: matching.key, builder: builder)
    }
      //if failed to resolve type for matching key - try auto-wiring
      //(usually happens when inferring optional type)
    catch let DipError.DefinitionNotFound(errorKey) where errorKey.protocolType == matching.key.protocolType {
      return try _autowire(key)
    }
  }
  
  /// Actually resolve dependency.
  private func _resolveDefinition<T>(definition: _Definition, forKey key: DefinitionKey, builder: _Definition throws -> T) throws -> T {
    
    //first search for already resolved instance for this type or any of forwarding types
    if let previouslyResolved: T = previouslyResolved(definition, key: key) {
      return previouslyResolved
    }
    
    var resolvedInstance = try builder(definition)
    
    /*
     Strongly-typed `resolve(tag:builder:)` calls weakly-typed `resolve(_:tag:builder:)`,
     so `T` will be `Any` at runtime, erasing type information when this method returns.
     When we try to cast result of `Any` to generic type T Swift fails to cast it.
     The same happens in the following code snippet:
     
     let optService: Service? = ServiceImp()
     let anyService: Any = optService
     let service: Service = anyService as! Service
     
     As a workaround we detect boxing here and unwrap it so that we return not a box, but wrapped instance.
     */
    if let box = resolvedInstance as? BoxType, unboxed = box.unboxed as? T {
      resolvedInstance = unboxed
    }
    
    //when builder calls factory it will in turn resolve sub-dependencies (if there are any)
    //when it returns instance that we try to resolve here can be already resolved
    //so we return it, throwing away instance created by previous call to builder
    if let previouslyResolved: T = previouslyResolved(definition, key: key) {
      return previouslyResolved
    }
    
    resolvedInstances.storeResolvedInstance(resolvedInstance, forKey: key, inScope: definition.scope)
    
    try definition.resolveDependenciesOf(resolvedInstance, withContainer: self)
    try autoInjectProperties(resolvedInstance)
    
    return resolvedInstance
  }
  
  private func previouslyResolved<T>(definition: _Definition, key: DefinitionKey) -> T? {
    let keys = definition.implementingTypes.map({
      DefinitionKey(protocolType: $0, argumentsType: key.argumentsType, associatedTag: key.associatedTag)
    })
    for key in [key] + keys {
      if let previouslyResolved: T = resolvedInstances.previouslyResolvedInstance(forKey: key, inScope: definition.scope) {
        return previouslyResolved
      }
    }
    return nil
  }
  
  /// Searches for definition that matches provided key
  private func definition(matching key: DefinitionKey) -> KeyDefinitionPair? {
    let typeDefinitions = definitions.filter({ $0.0.protocolType ==  key.protocolType })
    guard !typeDefinitions.isEmpty else {
      return typeForwardingDefinition(key.protocolType, tag: key.associatedTag)
    }
    
    if let definition = (self.definitions[key] ?? self.definitions[key.tagged(nil)]) {
      return (key, definition)
    }
    return nil
  }
  
}

// MARK: - Removing definitions

extension DependencyContainer {
  
  /**
   Removes definition registered in the container.

   - parameters:
      - tag: The tag used to register definition.
      - definition: The definition to remove
   */
  public func remove<T, U>(definition: DefinitionOf<T, U>, forTag tag: DependencyTagConvertible? = nil) {
    let key = DefinitionKey(protocolType: T.self, argumentsType: U.self, associatedTag: tag?.dependencyTag)
    remove(definitionForKey: key)
  }
  
  private func remove(definitionForKey key: DefinitionKey) {
    precondition(!bootstrapped, "You can not modify container's definitions after it was bootstrapped.")
    
    threadSafe {
      definitions[key] = nil
      resolvedInstances.singletons[key] = nil
    }
  }

  /**
   Removes all definitions registered in the container.
   */
  public func reset() {
    threadSafe {
      definitions.removeAll()
      resolvedInstances.singletons.removeAll()
      bootstrapped = false
    }
  }

}

extension DependencyContainer {
  
  /**
   Validates container configuration trying to resolve each registered definition one by one.
   If definition fails to be resolved without arguments will search provided arguments array
   for arguments matched by type and try to resolve this definition using these arguments.
   If there are no matching arguments will rethrow original error.
   
   - parameter arguments: set of arguments to use to resolve registered definitions.
                          Use a tuple for registered factories that accept several runtime arguments.
  */
  public func validate(arguments: Any...) throws {
    validateNextDefinition: for (key, _) in definitions {
      do {
        //try to resolve key using provided arguments
        for argumentsSet in arguments where argumentsSet.dynamicType == key.argumentsType {
          do {
            try inContext(key.associatedTag, resolvingType: key.protocolType) {
              try _resolveKey(key, builder: { definition throws -> Any in
                try definition.weakFactory(argumentsSet)
              })
            }
            continue validateNextDefinition
          }
          catch let error as DipError {
            throw error
          }
            //ignore other errors
          catch { print(error) }
        }
        
        //try to resolve key using auto-wiring
        do {
          try self.resolve(key.protocolType, tag: key.associatedTag)
        }
        catch let error as DipError {
          throw error
        }
          //ignore other errors
        catch { print(error) }
      }
    }
  }
}

///Pool to hold instances, created during call to `resolve()`.
///Before `resolve()` returns pool is drained.
private class ResolvedInstances {
  var resolvedInstances = [DefinitionKey: Any]()
  var singletons = [DefinitionKey: Any]()
  var resolvableInstances = [Resolvable]()
  
  func storeResolvedInstance<T>(instance: T, forKey key: DefinitionKey, inScope scope: ComponentScope) {
    switch scope {
    case .Singleton, .EagerSingleton: singletons[key] = instance
    case .ObjectGraph: resolvedInstances[key] = instance
    case .Prototype: break
    }
    
    if let resolvable = instance as? Resolvable {
      resolvableInstances.append(resolvable)
    }
  }
  
  func previouslyResolvedInstance<T>(forKey key: DefinitionKey, inScope scope: ComponentScope) -> T? {
    switch scope {
    case .Singleton, .EagerSingleton: return singletons[key] as? T
    case .ObjectGraph: return resolvedInstances[key] as? T
    case .Prototype: return nil
    }
  }
  
  private var depth: Int = 0
  
  func resolve<T>(@noescape block: () throws ->T) rethrows -> T {
    depth = depth + 1
    
    defer {
      depth = depth - 1
      if depth == 0 {
        // We call didResolveDependencies only at this point
        // because this is a point when dependencies graph is complete.
        for resolvedInstance in resolvableInstances.reverse() {
          resolvedInstance.didResolveDependencies()
        }
        resolvedInstances.removeAll()
        resolvableInstances.removeAll()
      }
    }
    
    let resolved = try block()
    return resolved
  }
}

extension DependencyContainer: CustomStringConvertible {
  
  public var description: String {
    return "Definitions: \(definitions.count)\n" + definitions.map({ "\($0.0)" }).joinWithSeparator("\n")
  }
  
}

//MARK: - Resolvable

/// Conform to this protocol when you need to have a callback when all the dependencies are injected.
public protocol Resolvable {
  /// This method is called by the container when all dependencies of the instance are resolved.
  func didResolveDependencies()
}

//MARK: - DependencyTagConvertible

/// Implement this protocol of your type if you want to use its instances as `DependencyContainer`'s tags.
/// `DependencyContainer.Tag`, `String`, `Int` and any `RawRepresentable` with `RawType` of `String` or `Int` by default confrom to this protocol.
public protocol DependencyTagConvertible {
  var dependencyTag: DependencyContainer.Tag { get }
}

extension DependencyContainer.Tag: DependencyTagConvertible {
  public var dependencyTag: DependencyContainer.Tag {
    return self
  }
}

extension String: DependencyTagConvertible {
  public var dependencyTag: DependencyContainer.Tag {
    return .String(self)
  }
}

extension Int: DependencyTagConvertible {
  public var dependencyTag: DependencyContainer.Tag {
    return .Int(self)
  }
}

extension DependencyTagConvertible where Self: RawRepresentable, Self.RawValue == Int {
  public var dependencyTag: DependencyContainer.Tag {
    return .Int(rawValue)
  }
}

extension DependencyTagConvertible where Self: RawRepresentable, Self.RawValue == String {
  public var dependencyTag: DependencyContainer.Tag {
    return .String(rawValue)
  }
}

extension DependencyContainer.Tag: StringLiteralConvertible {
  
  public init(stringLiteral value: StringLiteralType) {
    self = .String(value)
  }
  
  public init(unicodeScalarLiteral value: StringLiteralType) {
    self.init(stringLiteral: value)
  }
  
  public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
    self.init(stringLiteral: value)
  }
  
}

extension DependencyContainer.Tag: IntegerLiteralConvertible {
  
  public init(integerLiteral value: IntegerLiteralType) {
    self = .Int(value)
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

//MARK: - DipError

/**
 Errors thrown by `DependencyContainer`'s methods.
 
 - seealso: `resolve(tag:)`
*/
public enum DipError: ErrorType, CustomStringConvertible {
  
  /**
   Thrown by `resolve(tag:)` if no matching definition was registered in container.
   
   - parameter key: definition key used to lookup matching definition
  */
  case DefinitionNotFound(key: DefinitionKey)

  /**
   Thrown by `resolve(tag:)` if failed to auto-inject required property.
   
   - parameters:
      - label: The name of the property
      - type: The type of the property
      - underlyingError: The error that caused auto-injection to fail
  */
  case AutoInjectionFailed(label: String?, type: Any.Type, underlyingError: ErrorType)
  
  /**
   Thrown by `resolve(tag:)` if failed to auto-wire a type.
   
   - parameters:
      - type: The type that failed to be resolved by auto-wiring
      - underlyingError: The error that cause auto-wiring to fail
  */
  case AutoWiringFailed(type: Any.Type, underlyingError: ErrorType)

  /**
   Thrown when auto-wiring type if several definitions with the same number of runtime arguments
   are registered for that type.
   
   - parameters:
      - type: The type that failed to be resolved by auto-wiring
      - definitions: Ambiguous definitions
  */
  case AmbiguousDefinitions(type: Any.Type, definitions: [Definition])
  
  public var description: String {
    switch self {
    case let .DefinitionNotFound(key):
      return "No definition registered for \(key).\nCheck the tag, type you try to resolve, number, order and types of runtime arguments passed to `resolve()` and match them with registered factories for type \(key.protocolType)."
    case let .AutoInjectionFailed(label, type, error):
      return "Failed to auto-inject property \"\(label.desc)\" of type \(type). \(error)"
    case let .AutoWiringFailed(type, error):
      return "Failed to auto-wire type \"\(type)\". \(error)"
    case let .AmbiguousDefinitions(type, definitions):
      return "Ambiguous definitions for \(type):\n" +
      definitions.map({ "\($0)" }).joinWithSeparator(";\n")
    }
  }
}

///Internal protocol used to unwrap optional values.
private protocol BoxType {
  var unboxed: Any? { get }
}

extension Optional: BoxType {
  private var unboxed: Any? {
    switch self {
    case let .Some(value): return value
    default: return nil
    }
  }
}

extension ImplicitlyUnwrappedOptional: BoxType {
  private var unboxed: Any? {
    switch self {
    case let .Some(value): return value
    default: return nil
    }
  }
}

//MARK: - Deprecated methods

extension DependencyContainer {
  @available(*, deprecated=4.3.0, message="Use registerFactory(tag:scope:factory:numberOfArguments:autoWiringFactory:) instead.")
  public func registerFactory<T, U>(tag tag: DependencyTagConvertible? = nil, scope: ComponentScope, factory: U throws -> T) -> DefinitionOf<T, U throws -> T> {
    let definition = DefinitionBuilder<T, U> {
      $0.scope = scope
      $0.factory = factory
      }.build()
    register(definition, forTag: tag)
    return definition
  }
}
