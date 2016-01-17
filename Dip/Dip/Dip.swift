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
_Dip_'s Dependency Containers allow you to do very simple **Dependency Injection**
by associating `protocols` to concrete implementations
*/
public final class DependencyContainer {
  
  /**
   Use a tag in case you need to register multiple instances or factories
   with the same protocol, to differentiate them. Tags can be either String
   or Int, to your convenience.
   */
  public enum Tag: Equatable {
    case String(StringLiteralType)
    case Int(IntegerLiteralType)
  }
  
  var definitions = [DefinitionKey : Definition]()
  let lock = NSRecursiveLock()
  
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
  
  // MARK: - Thread safety
  
  private func threadSafe<T>(@noescape closure: () throws -> T) rethrows -> T {
    lock.lock()
    defer {
      lock.unlock()
    }
    return try closure()
  }

  // MARK: - Removing definitions
  
  /**
   Removes previously registered definition from container.
   
   - parameter tag: tag used to register definition
   - parameter definition: definition to remove
   */
  public func remove<T, F>(definition: DefinitionOf<T, F>, forTag tag: Tag? = nil) {
    let key = DefinitionKey(protocolType: T.self, factoryType: F.self, associatedTag: tag)
    remove(definition, forKey: key)
  }
  
  func remove(definition: Definition, forKey key: DefinitionKey) {
    threadSafe {
      definitions[key] = nil
      if let definition = definition as? _Definition {
        definitions[definition.injectedKey] = nil
        definitions[definition.injectedWeakKey] = nil
      }
    }
  }

  /**
   Clear all the previously registered dependencies on this container.
   */
  public func reset() {
    threadSafe {
      definitions.removeAll()
    }
  }

  // MARK: Register definitions
  
  /**
  Register a Void->T factory associated with optional tag.
  
  - parameter tag: The arbitrary tag to associate this factory with when registering with that protocol. Pass `nil` to associate with any tag. Default value is `nil`.
  - parameter scope: scope to use for this compone
  - parameter factory: The factory to register, with return type of protocol you want to register it for
  - returns: definition created for provided type and factory
  
  - note: You must cast the factory return type to the protocol you want to register it for.
  
  **Example**:
  ```swift
  container.register { ServiceImp() as Service }
  container.register(tag: "service") { ServiceImp() as Service }
  container.register(.ObjectGraph) { ServiceImp() as Service }
  container.register { ClientImp(service: try! container.resolve() as Service) as Client }
  ```
  */
  public func register<T>(tag tag: Tag? = nil, _ scope: ComponentScope = .Prototype, factory: () throws -> T) -> DefinitionOf<T, () throws ->T > {
    return registerFactory(tag: tag, scope: scope, factory: factory)
  }
  
  /**
   Register generic factory associated with optional tag.
   
   - parameter tag: The arbitrary tag to look for when resolving this protocol.
   - parameter factory: generic factory that should be used to create concrete instance of type
   - parameter scope: scope of the component. Default value is `Prototype`
   - returns: definition created for provided type and factory

   - note: You should not call this method directly, instead call any of other `register` methods.
           You _should_ use this method only to register dependency with more runtime arguments
           than _Dip_ supports (currently it's up to six) like in this example:
   
   ```swift
   public func register<T, Arg1, Arg2, Arg3, ...>(tag: Tag? = nil, scope: ComponentScope = .Prototype, factory: (Arg1, Arg2, Arg3, ...) -> T) -> DefinitionOf<T, (Arg1, Arg2, Arg3, ...) -> T> {
     return registerFactory(tag: tag, scope: scope, factory: factory) as DefinitionOf<T, (Arg1, Arg2, Arg3, ...) -> T>
   }
   ```
   
   Though before you do that you should probably review your design and try to reduce number of depnedencies.
   
   */
  public func registerFactory<T, F>(tag tag: Tag? = nil, scope: ComponentScope, factory: F) -> DefinitionOf<T, F> {
    let definition = DefinitionOf<T, F>(scope: scope, factory: factory)
    register(definition, forTag: tag)
    return definition
  }
  
  /**
   Registers new definiton in container and associate it with provided tag.
   Will override already registered definition for the same type and factory associated with the same tag.
   
   - parameter tag: The arbitrary tag to associate definition with
   - parameter definition: definition to register in container
   */
  public func register<T, F>(definition: DefinitionOf<T, F>, forTag tag: Tag? = nil) {
    let key = DefinitionKey(protocolType: T.self, factoryType: F.self, associatedTag: tag)
    register(definition, forKey: key)
  }
  
  func register(definition: Definition, forKey key: DefinitionKey) {
    threadSafe {
      definitions[key] = definition
    
      if let definition = definition as? _Definition where key.associatedTag == nil {
        definitions[definition.injectedKey] = definition.injectedDefinition
        definitions[definition.injectedWeakKey] = definition.injectedWeakDefinition
      }
    }
  }

  // MARK: Resolve dependencies
  
  /**
  Resolve a dependency.
  
  If no definition was registered with this `tag` for this `protocol`,
  it will try to resolve the definition associated with `nil` (no tag).
  
  Will throw `DipError.DefinitionNotFound` if no registered definition found
  that would match type, runtime arguments and tag.
  
  - parameter tag: The arbitrary tag to look for when resolving this protocol.
  
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
   Resolve a dependency using generic builder closure that accepts generic factory and returns created instance.
   
   - parameter tag: The arbitrary tag to look for when resolving this protocol.
   - parameter builder: Generic closure that accepts generic factory and returns inctance produced by that factory
   - returns: resolved instance of type T
   
   - note: You should not call this method directly, instead call any of other `resolve` methods. (see `RuntimeArguments.swift`).
   You _should_ use this method only to resolve dependency with more runtime arguments than _Dip_ supports
   (currently it's up to six) like in this example:
   
   ```swift
   public func resolve<T, Arg1, Arg2, Arg3, ...>(tag tag: Tag? = nil, _ arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, ...) throws -> T {
     return try resolve(tag: tag) { (factory: (Arg1, Arg2, Arg3, ...) -> T) in factory(arg1, arg2, arg3, ...) }
   }
   ```
   
   Though before you do that you should probably review your design and try to reduce the number of dependencies.
   
   */
  public func resolve<T, F>(tag tag: Tag? = nil, builder: F throws -> T) throws -> T {
    let key = DefinitionKey(protocolType: T.self, factoryType: F.self, associatedTag: tag)
    let nilTagKey = tag.map { _ in DefinitionKey(protocolType: T.self, factoryType: F.self, associatedTag: nil) }

    return try threadSafe {
      guard let definition = (self.definitions[key] ?? self.definitions[nilTagKey]) as? DefinitionOf<T, F> else {
        throw DipError.DefinitionNotFound(key)
      }
      
      let usingKey: DefinitionKey? = definition.scope == .ObjectGraph ? key : nil
      return try self._resolve(tag, key: usingKey, definition: definition, builder: builder)
    }
  }
  
  /// Actually resolve dependency
  private func _resolve<T, F>(tag: Tag? = nil, key: DefinitionKey?, definition: DefinitionOf<T, F>, builder: F throws -> T) rethrows -> T {
    
    return try resolvedInstances.resolve {
      
      if let previouslyResolved: T = resolvedInstances.previouslyResolved(key, definition: definition) {
        return previouslyResolved
      }
      else {
        let resolvedInstance = try builder(definition.factory)
        
        //when builder calls factory it will in turn resolve sub-dependencies (if there are any)
        //when it returns instance that we try to resolve here can be already resolved
        //so we return it, throwing away instance created by previous call to builder
        if let previouslyResolved: T = resolvedInstances.previouslyResolved(key, definition: definition) {
          return previouslyResolved
        }
        
        resolvedInstances.storeResolvedInstance(resolvedInstance, forKey: key, definition: definition)
        definition.resolvedInstance = resolvedInstance
        
        try definition.resolveDependenciesBlock?(self, resolvedInstance)
        
        //we perform auto-injection as the last step to be able to reuse instances
        //stored when manually resolving dependencies in resolveDependencies block
        try resolveDependencies(resolvedInstance)
        
        return resolvedInstance
      }
    }
  }
  
  // MARK: - Private
  
  let resolvedInstances = ResolvedInstances()
  
  ///Pool to hold instances, created during call to `resolve()`. 
  ///Before `resolve()` returns pool is drained.
  class ResolvedInstances {
    var resolvedInstances = [DefinitionKey: Any]()

    func storeResolvedInstance<T, F>(instance: T, forKey key: DefinitionKey?, definition: DefinitionOf<T, F>) {
      resolvedInstances[key] = instance
      
      //to be able to reuse instances for auto-injected properties
      if key != nil {
        resolvedInstances[definition.injectedKey] = instance
        resolvedInstances[definition.injectedWeakKey] = instance
      }
    }
    
    func previouslyResolved<T, F>(key: DefinitionKey?, definition: DefinitionOf<T, F>) -> T? {
      if let singleton = definition.resolvedInstance {
        return singleton
      }
      else if let resolved = resolvedInstances[key] {
        return resolved as? T
      }
      else if let key = key where key.associatedTag == nil {
        //for cases when type was previously resolved as auto-injected property
        if let resolved = resolvedInstances[definition.injectedKey] ?? resolvedInstances[definition.injectedWeakKey] {
          return resolved as? T
        }
      }
      return nil
    }
    
    private var depth: Int = 0
    
    func resolve<T>(@noescape block: () throws ->T) rethrows -> T {
      depth++
      
      defer {
        depth--
        if depth == 0 {
          resolvedInstances.removeAll()
        }
      }
      
      let resolved = try block()
      return resolved
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

public enum DipError: ErrorType, CustomStringConvertible {
  case DefinitionNotFound(DefinitionKey)
  
  public var description: String {
    switch self {
    case let .DefinitionNotFound(key):
      if let wrappedType = autoInjectedType(key.associatedTag) {
        return "Failed to auto-inject property of type \(wrappedType). Check if you registered factory with no tag and no runtime arguments for type \(wrappedType)."
      }
      return "Failed to resolve type \(key.protocolType) - no definition registered for \(key).\nCheck the tag, type you try to resolve, number, order and types of runtime arguments passed to `resolve()` and match them with registered factories for type \(key.protocolType)."
    }
  }
}
