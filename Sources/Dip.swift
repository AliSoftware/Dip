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

// MARK: - DependencyContainer

/**
`DependencyContainer` allows you to do _Dependency Injection_
by associating abstractions to concrete implementations.
*/
public final class DependencyContainer {
  
  /**
   Use a tag in case you need to register multiple factories fo the same type,
   to differentiate them. Tags can be either String or Int, to your convenience.
   */
  public enum Tag: Equatable {
    case String(StringLiteralType)
    case Int(IntegerLiteralType)
  }
  
  var definitions = [DefinitionKey : Definition]()
  let resolvedInstances = ResolvedInstances()
  let lock = RecursiveLock()
  
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
  public func register<T>(tag tag: Tag? = nil, _ scope: ComponentScope = .Prototype, factory: () throws -> T) -> DefinitionOf<T, () throws -> T> {
    return registerFactory(tag: tag, scope: scope, factory: factory)
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
   public func register<T, Arg1, Arg2, Arg3, ...>(tag: Tag? = nil, scope: ComponentScope = .Prototype, factory: (Arg1, Arg2, Arg3, ...) throws -> T) -> DefinitionOf<T, (Arg1, Arg2, Arg3, ...) throws -> T> {
     return registerFactory(tag: tag, scope: scope, factory: factory) as DefinitionOf<T, (Arg1, Arg2, Arg3, ...) throws -> T>
   }
   ```
   
   Though before you do so you should probably review your design and try to reduce number of depnedencies.
   */
  public func registerFactory<T, F>(tag tag: Tag? = nil, scope: ComponentScope, factory: F) -> DefinitionOf<T, F> {
    let definition = DefinitionOf<T, F>(scope: scope, factory: factory)
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
  public func register<T, F>(definition: DefinitionOf<T, F>, forTag tag: Tag? = nil) {
    let key = DefinitionKey(protocolType: T.self, factoryType: F.self, associatedTag: tag)
    register(definition, forKey: key)
  }
  
  func register(definition: Definition, forKey key: DefinitionKey) {
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
   
   - throws: An error of type `DipError`:
             `ResolutionFailed` - if some error was thrown during resolution;
             `DefinitionNotFound` - if no matching definition was registered in that container.
             `AutoInjectionFailed` - if failed to auto-inject required property
   
   - returns: An instance of type `T`.
   
   - seealso: `register(tag:_:factory:)`
   
   **Example**:
   ```swift
   let service = try! container.resolve() as Service
   let service = try! container.resolve(tag: "service") as Service
   let service: Service = try! container.resolve()
   ```
   
   */
  public func resolve<T>(tag tag: Tag? = nil) throws -> T {
    return try resolve(tag: tag) { (factory: () throws -> T) in try factory() }
  }
  
  /**
   Resolve an instance of type `T` using generic builder closure that accepts generic factory and returns created instance.
   
   - parameters:
      - tag: The arbitrary tag to use to lookup definition.
      - builder: Generic closure that accepts generic factory and returns inctance created by that factory.
   
   - throws: An error of type `DipError`:
             `ResolutionFailed` - if some error was thrown during resolution;
             `DefinitionNotFound` - if no matching definition was registered in that container.
             `AutoInjectionFailed` - if failed to auto-inject required property

   - returns: An instance of type `T`.
   
   - note: You _should not_ call this method directly, instead call any of other 
           `resolve(tag:)` or `resolve(tag:withArguments:)` methods.
           You _should_ use this method only to resolve dependency with more runtime arguments than
           _Dip_ supports (currently it's up to six) like in the following example:
   
   ```swift
   public func resolve<T, Arg1, Arg2, Arg3, ...>(tag tag: Tag? = nil, _ arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, ...) throws -> T {
     return try resolve(tag: tag) { (factory: (Arg1, Arg2, Arg3, ...) -> T) in factory(arg1, arg2, arg3, ...) }
   }
   ```
   
   Though before you do so you should probably review your design and try to reduce the number of dependencies.
   */
  public func resolve<T, F>(tag tag: Tag? = nil, builder: F throws -> T) throws -> T {
    let key = DefinitionKey(protocolType: T.self, factoryType: F.self, associatedTag: tag)

    do {
      return try _resolveKey(key, builder: builder)
    }
    catch {
      switch error {
      case let DipError.DefinitionNotFound(errorKey) where key == errorKey:
        throw error
      default:
        throw DipError.ResolutionFailed(key: key, underlyingError: error)
      }
    }
  }
  
  /// Lookup definition by the key and use it to resolve instance. Fallback to the key with `nil` tag.
  func _resolveKey<T, F>(key: DefinitionKey, builder: F throws -> T) throws -> T {
    return try threadSafe {
      let nilTagKey = key.associatedTag.map { _ in DefinitionKey(protocolType: T.self, factoryType: F.self, associatedTag: nil) }

      guard let definition = (self.definitions[key] ?? self.definitions[nilTagKey]) as? DefinitionOf<T, F> else {
        throw DipError.DefinitionNotFound(key: key)
      }
      return try self._resolveDefinition(definition, key: key, builder: builder)
    }
  }
  
  /// Actually resolve dependency.
  private func _resolveDefinition<T, F>(definition: DefinitionOf<T, F>, key: DefinitionKey, builder: F throws -> T) rethrows -> T {
    return try resolvedInstances.resolve {
      if let previouslyResolved: T = resolvedInstances.previouslyResolvedInstance(forKey: key, inScope: definition.scope) {
        return previouslyResolved
      }
      else {
        let resolvedInstance = try builder(definition.factory)
        
        //when builder calls factory it will in turn resolve sub-dependencies (if there are any)
        //when it returns instance that we try to resolve here can be already resolved
        //so we return it, throwing away instance created by previous call to builder
        if let previouslyResolved: T = resolvedInstances.previouslyResolvedInstance(forKey: key, inScope: definition.scope) {
          return previouslyResolved
        }
        
        resolvedInstances.storeResolvedInstance(resolvedInstance, forKey: key, inScope: definition.scope)
        
        try definition.resolveDependenciesOf(resolvedInstance, withContainer: self)
        
        //we perform auto-injection as the last step to be able to reuse instances
        //stored when manually resolving dependencies in resolveDependencies block
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

    func storeResolvedInstance<T>(instance: T, forKey key: DefinitionKey, inScope scope: ComponentScope) {
      switch scope {
      case .Singleton: singletons[key] = instance
      case .ObjectGraph: resolvedInstances[key] = instance
      case .Prototype: break
      }
    }
    
    func previouslyResolvedInstance<T>(forKey key: DefinitionKey, inScope scope: ComponentScope) -> T? {
      switch scope {
      case .Singleton: return singletons[key] as? T
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
          resolvedInstances.removeAll()
        }
      }
      
      let resolved = try block()
      return resolved
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
  public func remove<T, F>(definition: DefinitionOf<T, F>, forTag tag: Tag? = nil) {
    let key = DefinitionKey(protocolType: T.self, factoryType: F.self, associatedTag: tag)
    remove(definitionForKey: key)
  }
  
  func remove(definitionForKey key: DefinitionKey) {
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
    }
  }

}

extension DependencyContainer: CustomStringConvertible {
  
  public var description: String {
    return "Definitions: \(definitions.count)\n" + definitions.map({ "\($0.0)" }).joinWithSeparator("\n")
  }
  
}

extension DependencyContainer.Tag: IntegerLiteralConvertible {

  public init(integerLiteral value: IntegerLiteralType) {
    self = .Int(value)
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
 Errors thrown by `DependencyContainer`'s methods.
 
 - seealso: `resolve(tag:)`
*/
public enum DipError: ErrorType, CustomStringConvertible {
  /**
  Thrown by `resolve(tag:)` if some error was thrown during resolution.
   
   - parameters:
      - key: The key, which is associated with definition used to resolve instance
      - underlyingError: The error that caused resolution to fail
   */
  case ResolutionFailed(key: DefinitionKey, underlyingError: ErrorType)
  
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
  
  public var description: String {
    switch self {
    case let .ResolutionFailed(key, error):
      return "Failed to resolve type \(key.protocolType). \(error)"
    case let .DefinitionNotFound(key):
      return "No definition registered for \(key).\nCheck the tag, type you try to resolve, number, order and types of runtime arguments passed to `resolve()` and match them with registered factories for type \(key.protocolType)."
    case let .AutoInjectionFailed(label, type, error):
      return "Failed to auto-inject property \"\(label)\" of type \(type). \(error)"
    }
  }
}
