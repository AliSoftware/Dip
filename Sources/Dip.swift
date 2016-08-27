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
  
  internal(set) public var context: Context!
  var definitions = [DefinitionKey: _Definition]()
  private var resolvedInstances = ResolvedInstances()
  private let lock = RecursiveLock()
  
  private(set) var bootstrapped = false
  private var bootstrapQueue: [() throws -> ()] = []
  
  private var _weakCollaborators: [WeakBox<DependencyContainer>] = []
  private(set) var _collaborators: [DependencyContainer] {
    get {
      return _weakCollaborators.flatMap({ $0.value })
    }
    set {
      _weakCollaborators = newValue.filter({ $0 !== self }).map(WeakBox.init)
    }
  }

  /**
   Designated initializer for a DependencyContainer
   
   - parameter configBlock: A configuration block in which you typically put all you `register` calls.
   
   - note: The `configBlock` is simply called at the end of the `init` to let you configure everything. 
           It is only present for convenience to have a cleaner syntax when declaring and initializing
           your `DependencyContainer` instances. 
   
   - warning: If you use `configBlock` you need to make sure you don't create retain cycles. For example
              there will be a retain cycle between container and its definition if you reference container
              inside definition's factory. You can avoid that by using unowned reference to container:
   
   ```swift
   let container = DependencyContainer() { container in
     unowned let container = container
     //register definitions
   }
   ```
   
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
   }.resolvingProperties { container, service in
     //container will use `nil` tag to resolve this dependency
     self.dependency = try container.resolve() as SomeDependency
   
     //container will use current context tag ("tag") to resolve this dependency
     self.taggedDependency = try container.resolve(tag: container.context.tag) as SomeDependency
   }
   
   //container will use "tag" to resolve this instance
   let service = try! container.resolve(tag: "tag") as SomeService
   
   ```
   */
  public struct Context: CustomStringConvertible, CustomDebugStringConvertible {
    
    internal(set) public var key: DefinitionKey
    
    /// Currently resolving type.
    public var resolvingType: Any.Type {
      return key.type
    }

    /// The tag used to resolve currently resolving type.
    public var tag: Tag? {
      return key.tag
    }
    
    /// The type that caused currently resolving type to be resolved.
    /// `nil` for root object in a dependencies graph.
    private(set) public var injectedInType: Any.Type?
    
    /// The label of the property where resolved instance will be auto-injected.
    private(set) public var injectedInProperty: String?
    
    var logErrors: Bool = true
    
    init(key: DefinitionKey, injectedInType: Any.Type?, injectedInProperty: String?) {
      self.key = key
      self.injectedInType = injectedInType
      self.injectedInProperty = injectedInProperty
    }
    
    public var debugDescription: String {
      return "Context(key: \(key), injectedInType: \(injectedInType.desc), injectedInProperty: \(injectedInProperty.desc) logErrors: \(logErrors))"
    }
    
    public var description: String {
      let resolvingDescription = "Resolving type \(key.type) with arguments \(key.typeOfArguments) tagged with \(key.tag.desc)"
      if injectedInProperty != nil {
        return "\(resolvingDescription) while auto-injecting property \(injectedInProperty.desc) of \(injectedInType.desc)"
      }
      else if injectedInType != nil {
        return "\(resolvingDescription) while injecting in type \(injectedInType.desc)"
      }
      else {
        return resolvingDescription
      }
    }
    
  }

  /// Pushes new context created with provided values and calls block. When block returns previous context is restored.
  /// For `nil` values (except tag) new context will use values from the current context.
  /// Will releas resolved instances and call `Resolvable` callbacks when popped to initial context.
  func inContext<T>(key: DefinitionKey, injectedInProperty: String? = nil, injectedInType: Any.Type? = nil, logErrors: Bool! = nil, @noescape block: () throws -> T) rethrows -> T {
    return try threadSafe {
      let currentContext = self.context
      
      defer {
        context = currentContext
        
        //clean instances pool if it is owned not by other container
        if context == nil {
          resolvedInstances.resolvedInstances.removeAll()
          for (key, instance) in resolvedInstances.weakSingletons {
            if resolvedInstances.weakSingletons[key] is WeakBoxType { continue }
            resolvedInstances.weakSingletons[key] = WeakBox(instance)
          }
          
          // We call didResolveDependencies only at this point
          // because this is a point when dependencies graph is complete.
          for resolvedInstance in resolvedInstances.resolvableInstances.reverse() {
            resolvedInstance.didResolveDependencies()
          }
          resolvedInstances.resolvableInstances.removeAll()
        }
      }
      
      context = Context(
        key: key,
        injectedInType: injectedInType ?? currentContext?.resolvingType,
        injectedInProperty: injectedInProperty
      )
      context.logErrors = logErrors ?? currentContext?.logErrors ?? true
      
      do {
        return try block()
      }
      catch {
        if context.logErrors { log(.Errors, error) }
        throw error
      }
    }
  }

}

// MARK: - Registering definitions

extension DependencyContainer {
  
  /**
   Register factory for type `T` and associate it with an optional tag.

   - parameters:
      - scope: The scope to use for instance created by the factory. Default value is `Shared`.
      - type: Type to register definition for. Default value is return value of factory.
      - tag: The arbitrary tag to associate this factory with. Pass `nil` to associate with any tag. Default value is `nil`.
      - factory: The factory that produces instance of `type`. Will be used to resolve instances of `type`.

   - returns: A registered definition.

   - note: You should cast the factory return type to the protocol you want to register it for
           (unless you want to register concrete type) or provide `type` parameter.
   
   - seealso: `Definition`, `ComponentScope`, `DependencyTagConvertible`

   **Example**:
   ```swift
   //Register ServiceImp as Service
   container.register { ServiceImp() as Service }
   
   //Register ServiceImp as Service named by "service"
   container.register(tag: "service") { ServiceImp() as Service }
   
   //Register unique ServiceImp as Service
   container.register(.Unique) { ServiceImp() as Service }
   
   //Register ClientImp as Client and resolve it's service dependency
   container.register { try ClientImp(service: container.resolve() as Service) as Client }
   
   //Register ServiceImp as concrete type
   container.register { ServiceImp() }
   container.register(factory: ServiceImp.init)
   
   //Register ServiceImp as Service
   container.register(Service.self, factory: ServiceImp.init)
   
   //Register ClientImp as Client
   container.register(Client.self, factory: ClientImp.init(service:))
   ```
   */
  public func register<T>(scope: ComponentScope = .Shared, type: T.Type = T.self, tag: DependencyTagConvertible? = nil, factory: () throws -> T) -> Definition<T, ()> {
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
   public func register<T, A, B, C, ...>(scope: ComponentScope = .Shared, tag: Tag? = nil, factory: (A, B, C, ...) throws -> T) -> Definition<T, (A, B, C, ...)> {
     return register(scope, tag: tag, factory: factory, numberOfArguments: ...) { container, tag in
        try factory(container.resolve(tag: tag), ...)
      }
   }
   ```
   
   Though before you do so you should probably review your design and try to reduce number of depnedencies.
   */
  public func registerFactory<T, U>(tag tag: DependencyTagConvertible? = nil, scope: ComponentScope, factory: U throws -> T, numberOfArguments: Int, autoWiringFactory: (DependencyContainer, Tag?) throws -> T) -> Definition<T, U> {
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
  public func register<T, U>(definition: Definition<T, U>, forTag tag: DependencyTagConvertible? = nil) {
    precondition(!bootstrapped, "You can not modify container's definitions after it was bootstrapped.")
    
    threadSafe {
      let key = DefinitionKey(type: T.self, typeOfArguments: U.self, tag: tag?.dependencyTag)
      if let _ = definitions[key] {
        remove(definitionForKey: key)
      }
      
      definition.container = self
      definitions[key] = definition
      resolvedInstances.singletons[key] = nil
      resolvedInstances.weakSingletons[key] = nil
      
      if case .EagerSingleton = definition.scope {
        bootstrapQueue.append({ let _ = try self.resolve(tag: tag) as T })
      }
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
    return try resolve(tag: tag) { factory in try factory() }
  }
  
  /**
   Resolve an instance of provided type. Weakly-typed alternative of `resolve(tag:)`
   
   - warning: This method does not make any type checks, so there is no guaranty that
              resulting instance is actually an instance of requested type.
              That can happen if you register forwarded type that is not implemented by resolved instance.
   
   **Example**:
   ```swift
   let service = try! container.resolve(Service.self) as! Service
   let service = try! container.resolve(Service.self, tag: "service") as! Service
   ```
   
   - seealso: `resolve(tag:)`, `register(tag:_:factory:)`
   */
  public func resolve(type: Any.Type, tag: DependencyTagConvertible? = nil) throws -> Any {
    return try resolve(type, tag: tag) { factory in try factory() }
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
    return try resolve(T.self, tag: tag, builder: { factory in
      try builder({ try factory($0) as! T })
    }) as! T
  }
  
  /**
   Resolve an instance of provided type using builder closure. Weakly-typed alternative of `resolve(tag:builder:)`
   
   - seealso: `resolve(tag:builder:)`
  */
  public func resolve<U>(type: Any.Type, tag: DependencyTagConvertible? = nil, builder: (U throws -> Any) throws -> Any) throws -> Any {
    let key = DefinitionKey(type: type, typeOfArguments: U.self, tag: tag?.dependencyTag)
    
    return try inContext(key) {
      try resolve(key: key, builder: { definition in
        try builder(definition.weakFactory)
      })
    }
  }
  
  /// Lookup definition by the key and use it to resolve instance. Fallback to the key with `nil` tag.
  func resolve<T>(key key: DefinitionKey, builder: (_Definition throws -> T)) throws -> T {
    guard let matching = self.definition(matching: key) else {
      return try resolveCollaborating(key, builder: builder) ?? autowire(key)
    }
    
    let (key, definition) = matching
    
    //first search for already resolved instance for this type or any of forwarding types
    if let previouslyResolved: T = previouslyResolved(definition, key: key) {
      log(.Verbose, "Reusing previously resolved instance \(previouslyResolved)")
      return previouslyResolved
    }
    
    log(.Verbose, context)
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
    if let box = resolvedInstance as? BoxType, unboxed = box.unboxed as? T {
      resolvedInstance = unboxed
    }
    
    //when builder calls factory it will in turn resolve sub-dependencies (if there are any)
    //when it returns instance that we try to resolve here can be already resolved
    //so we return it, throwing away instance created by previous call to builder
    if let previouslyResolved: T = previouslyResolved(definition, key: key) {
      log(.Verbose, "Reusing previously resolved instance \(previouslyResolved)")
      return previouslyResolved
    }

    resolvedInstances[key: key, inScope: definition.scope] = resolvedInstance

    if let resolvable = resolvedInstance as? Resolvable {
      resolvedInstances.resolvableInstances.append(resolvable)
      resolvable.resolveDependencies(self)
    }

    try autoInjectProperties(resolvedInstance)
    try definition.resolveProperties(of: resolvedInstance, container: self)
    
    log(.Verbose, "Resolved type \(key.type) with \(resolvedInstance)")
    return resolvedInstance
  }
  
  private func previouslyResolved<T>(definition: _Definition, key: DefinitionKey) -> T? {
    //first check if exact key was already resolved
    if let previouslyResolved = resolvedInstances[key: key, inScope: definition.scope] as? T {
      return previouslyResolved
    }
    //then check if any related type was already resolved
    let keys = definition.implementingTypes.map({
      DefinitionKey(type: $0, typeOfArguments: key.typeOfArguments, tag: key.tag)
    })
    for key in keys {
      if let previouslyResolved = resolvedInstances[key: key, inScope: definition.scope] as? T {
        return previouslyResolved
      }
    }
    return nil
  }
  
  /// Searches for definition that matches provided key
  private func definition(matching key: DefinitionKey) -> KeyDefinitionPair? {
    if let definition = (self.definitions[key] ?? self.definitions[key.tagged(nil)]) {
      return (key, definition)
    }
    
    //if no definition registered for exact type try to find type-forwarding definition that can resolve the type
    //that will actually happen only when resolving optionals
    if definitions.filter({ $0.0.type == key.type }).isEmpty {
      return typeForwardingDefinition(key)
    }
    return nil
  }
  
}

//MARK: - Collaborating containers

extension DependencyContainer {
  
  /**
   Adds collaborating containers as weak references. Circular references are allowed.
   References to the container itself are ignored.
   */
  public func collaborate(with containers: DependencyContainer...) {
    collaborate(with: containers)
  }
  
  /**
   Adds collaborating containers as weak references. Circular references are allowed.
   References to the container itself are ignored.
   */
  public func collaborate(with containers: [DependencyContainer]) {
    _collaborators += containers
    for container in containers {
      container.resolvedInstances.singletonsBox = self.resolvedInstances.singletonsBox
      container.resolvedInstances.weakSingletonsBox = self.resolvedInstances.weakSingletonsBox
    }
  }
  
  /// Tries to resolve key using collaborating containers
  private func resolveCollaborating<T>(key: DefinitionKey, builder: _Definition throws -> T) -> T? {
    for collaborator in _collaborators {
      do {
        //if container is already in a context resolving this type 
        //it means that it has been already called to resolve this type,
        //so there is probably a cercular reference between containers.
        //To break it skip this container
        if let context = collaborator.context where
          context.resolvingType == key.type &&
          context.tag == key.tag { continue }

        //Pass current container's instances pool to collect instances resolved by collaborator
        let resolvedInstances = collaborator.resolvedInstances
        collaborator.resolvedInstances = self.resolvedInstances
        //Set collaborator context to preserve current container context
        let context = collaborator.context
        collaborator.context = self.context
        defer {
          collaborator.resolvedInstances = resolvedInstances
          collaborator.context = context
        }
        
        let resolved = try collaborator.inContext(key, injectedInProperty: self.context.injectedInProperty, injectedInType: self.context.injectedInType, logErrors: false) {
          try collaborator.resolve(key: key, builder: builder)
        }

        return resolved
      }
      catch {
        continue
      }
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
  public func remove<T, U>(definition: Definition<T, U>, forTag tag: DependencyTagConvertible? = nil) {
    let key = DefinitionKey(type: T.self, typeOfArguments: U.self, tag: tag?.dependencyTag)
    remove(definitionForKey: key)
  }
  
  private func remove(definitionForKey key: DefinitionKey) {
    precondition(!bootstrapped, "You can not modify container's definitions after it was bootstrapped.")
    
    threadSafe {
      definitions[key]?.container = nil
      definitions[key] = nil
      resolvedInstances.singletons[key] = nil
      resolvedInstances.weakSingletons[key] = nil
    }
  }

  /**
   Removes all definitions registered in the container.
   */
  public func reset() {
    threadSafe {
      definitions.forEach { $0.1.container = nil }
      definitions.removeAll()
      resolvedInstances.singletons.removeAll()
      resolvedInstances.weakSingletons.removeAll()
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
        for argumentsSet in arguments where argumentsSet.dynamicType == key.typeOfArguments {
          do {
            try inContext(key) {
              try resolve(key: key, builder: { definition throws -> Any in
                try definition.weakFactory(argumentsSet)
              })
            }
            continue validateNextDefinition
          }
          catch let error as DipError {
            throw error
          }
            //ignore other errors
          catch { log(.Errors, error) }
        }
        
        //try to resolve key using auto-wiring
        do {
          try self.resolve(key.type, tag: key.tag)
        }
        catch let error as DipError {
          throw error
        }
          //ignore other errors
        catch { log(.Errors, error) }
      }
    }
  }
}

///Pool to hold instances, created during call to `resolve()`.
///Before `resolve()` returns pool is drained.
private class ResolvedInstances {
  
  var resolvedInstances = [DefinitionKey: Any]()
  var resolvableInstances = [Resolvable]()
  
  //singletons are stored using reference type wrapper to be able to share them between containers
  private var singletonsBox = Box<[DefinitionKey: Any]>([:])
  var singletons: [DefinitionKey: Any] {
    get { return singletonsBox.unboxed }
    set { singletonsBox.unboxed = newValue }
  }
  
  private var weakSingletonsBox = Box<[DefinitionKey: Any]>([:])
  var weakSingletons: [DefinitionKey: Any] {
    get { return weakSingletonsBox.unboxed }
    set { weakSingletonsBox.unboxed = newValue }
  }
  subscript(key key: DefinitionKey, inScope scope: ComponentScope) -> Any? {
    get {
      switch scope {
      case .Singleton, .EagerSingleton: return singletons[key]
      case .WeakSingleton: return (weakSingletons[key] as? WeakBoxType)?.unboxed ?? weakSingletons[key]
      case .Shared, .ObjectGraph: return resolvedInstances[key]
      case .Unique, .Prototype: return nil
      }
    }
    set {
      switch scope {
      case .Singleton, .EagerSingleton: singletons[key] = newValue
      case .WeakSingleton: weakSingletons[key] = newValue
      case .Shared, .ObjectGraph: resolvedInstances[key] = newValue
      case .Unique, .Prototype: break
      }
    }
  }
  
}

extension DependencyContainer: CustomStringConvertible {
  
  public var description: String {
    return "Definitions: \(definitions.count)\n" + definitions.map({ "\($0.0)" }).joinWithSeparator("\n")
  }
  
}

//MARK: - Resolvable

/// Resolvable protocol provides some extension points for resolving dependencies with property injection.
public protocol Resolvable {
  /// This method will be called right after instance is created by the container.
  func resolveDependencies(container: DependencyContainer)
  /// This method will be called when all dependencies of the instance are resolved.
  /// When resolving objects graph the last resolved instance will receive this callback first.
  func didResolveDependencies()
}

extension Resolvable {
  func resolveDependencies(container: DependencyContainer) { }
  func didResolveDependencies() { }
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
  case AmbiguousDefinitions(type: Any.Type, definitions: [DefinitionType])
  
  public var description: String {
    switch self {
    case let .DefinitionNotFound(key):
      return "No definition registered for \(key).\nCheck the tag, type you try to resolve, number, order and types of runtime arguments passed to `resolve()` and match them with registered factories for type \(key.type)."
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

//MARK: - Deprecated methods

extension DependencyContainer {
  @available(*, deprecated=4.3.0, message="Use registerFactory(tag:scope:factory:numberOfArguments:autoWiringFactory:) instead.")
  public func registerFactory<T, U>(tag tag: DependencyTagConvertible? = nil, scope: ComponentScope, factory: U throws -> T) -> Definition<T, U> {
    let definition = DefinitionBuilder<T, U> {
      $0.scope = scope
      $0.factory = factory
      }.build()
    register(definition, forTag: tag)
    return definition
  }
}
