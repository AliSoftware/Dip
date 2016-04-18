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
  
  var definitions = [DefinitionKey : _Definition]()
  let resolvedInstances = ResolvedInstances()
  let lock = RecursiveLock()
  
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
   container.register { ClientImp(service: try! container.resolve() as Service) as Client }
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
   Register generic factory associated with an optional tag.
   
   - parameters:
      - tag: The arbitrary tag to associate this factory with. Pass `nil` to associate with any tag. Default value is `nil`.
      - scope: The scope to use for instance created by the factory.
      - factory: The factory to register.
   
   - returns: A registered definition.
   
   - note: You _should not_ call this method directly, instead call any of other `register` methods.
   You _should_ use this method only to register dependency with more runtime arguments
   than _Dip_ supports (currently it's up to six) like in the following example:
   
   ```swift
   public func register<T, A, B, C, ...>(tag: Tag? = nil, scope: ComponentScope = .Prototype, factory: (A, B, C, ...) throws -> T) -> DefinitionOf<T, (A, B, C, ...) throws -> T> {
     return registerFactory(tag: tag, scope: scope, factory: factory)
   }
   ```
   
   Though before you do so you should probably review your design and try to reduce number of depnedencies.
   */
  @available(*, deprecated=4.3.0, message="Use registerFactory(tag:scope:factory:numberOfArguments:autoWiringFactory:) instead.")
  public func registerFactory<T, U>(tag tag: DependencyTagConvertible? = nil, scope: ComponentScope, factory: U throws -> T) -> DefinitionOf<T, U throws -> T> {
    let definition = DefinitionBuilder<T, U> {
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
        try factory(try container.resolve(tag: tag), ...)
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
    let key = DefinitionKey(protocolType: T.self, argumentsType: U.self, associatedTag: tag?.dependencyTag)

    do {
      //first we try to find defintion that exactly matches parameters
      return try _resolveKey(key, builder: { definition throws -> T in
        typealias F = U throws -> T
        guard let factory = definition.baseFactory as? F else {
          throw DipError.DefinitionNotFound(key: key)
        }
        return try builder(factory)
      })
    }
    catch {
      guard let resolved = try _autoWireOrRethrow(key, type: T.self, error: error) as? T else {
        throw error
      }
      return resolved
    }
  }
  
  /// Lookup definition by the key and use it to resolve instance. Fallback to the key with `nil` tag.
  func _resolveKey<T>(key: DefinitionKey, builder: _Definition throws -> T) throws -> T {
    return try threadSafe {
      let nilTagKey = key.associatedTag.map { _ in
        DefinitionKey(protocolType: key.protocolType, argumentsType: key.argumentsType, associatedTag: nil)
      }

      guard let definition = (self.definitions[key] ?? self.definitions[nilTagKey]) else {
        throw DipError.DefinitionNotFound(key: key)
      }
      return try self._resolveDefinition(definition, usingKey: key, builder: builder)
    }
  }
  
  /// Actually resolve dependency.
  private func _resolveDefinition<T>(definition: _Definition, usingKey key: DefinitionKey, builder: _Definition throws -> T) rethrows -> T {
    return try resolvedInstances.resolve {
      if let previouslyResolved: T = resolvedInstances.previouslyResolvedInstance(forKey: key, inScope: definition.scope) {
        return previouslyResolved
      }
      else {
        let resolvedInstance = try builder(definition)
        
        //when builder calls factory it will in turn resolve sub-dependencies (if there are any)
        //when it returns instance that we try to resolve here can be already resolved
        //so we return it, throwing away instance created by previous call to builder
        if let previouslyResolved: T = resolvedInstances.previouslyResolvedInstance(forKey: key, inScope: definition.scope) {
          return previouslyResolved
        }
        
        resolvedInstances.storeResolvedInstance(resolvedInstance, forKey: key, inScope: definition.scope)
        
        try definition.resolveDependenciesOf(resolvedInstance, withContainer: self)
        try autoInjectProperties(resolvedInstance)
        
        return resolvedInstance
      }
    }
  }
  
  ///Pool to hold instances, created during call to `resolve()`.
  ///Before `resolve()` returns pool is drained.
  class ResolvedInstances {
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
  
}

//MARK: - Auto-wiring

extension DependencyContainer {
  
  private func _autoWireOrRethrow(key: DefinitionKey, type: Any.Type, error: ErrorType) throws -> Any? {
    switch error {
    case let DipError.DefinitionNotFound(errorKey) where key == errorKey:
      //if no definition found for key that we were trying to resolve - try atuo-wiring
      return try threadSafe {
        guard let resolved = try _resolveByAutoWiring(key, type: type) else {
          throw error
        }
        return resolved
      }
    default:
      throw error
    }
  }

}

//MARK: - Weakly typed resolve

extension DependencyContainer {
  
  public func resolve(type: Any.Type, tag: DependencyTagConvertible? = nil) throws -> Any {
    return try self.resolve(type, tag: tag) { factory in try factory(())}
  }
  
  public func resolve<U>(type: Any.Type, tag: DependencyTagConvertible? = nil, builder: (U throws -> Any) throws -> Any) throws -> Any {
    let key = DefinitionKey(protocolType: type, argumentsType: U.self, associatedTag: tag?.dependencyTag)
    
    do {
      //first we try to find defintion that exactly matches parameters
      return try _resolveKey(key, builder: { definition throws -> Any in
        try builder(definition.weakFactory)
      })
    }
    catch {
      return try _autoWireOrRethrow(key, type: type, error: error)
    }
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
  
  func remove(definitionForKey key: DefinitionKey) {
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
   Thrown by `resolve(tag:)` if found ambigous definitions registered for resolved type
   
   - parameters:
      - type: The type that failed to be resolved
      - definitions: Ambiguous definitions
  */
  case AmbiguousDefinitions(type: Any.Type, definitions: [Definition])
  
  public var description: String {
    switch self {
    case let .DefinitionNotFound(key):
      return "No definition registered for \(key).\nCheck the tag, type you try to resolve, number, order and types of runtime arguments passed to `resolve()` and match them with registered factories for type \(key.protocolType)."
    case let .AutoInjectionFailed(label, type, error):
      return "Failed to auto-inject property \"\(label.desc)\" of type \(type). \(error)"
    case let .AmbiguousDefinitions(type, definitions):
      return "Ambiguous definitions for \(type):\n" +
      definitions.map({ "\($0)" }).joinWithSeparator(";\n")
    }
  }
}
