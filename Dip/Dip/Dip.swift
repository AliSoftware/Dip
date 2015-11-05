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

import Foundation

// MARK: - DependencyContainer

/**
_Dip_'s Dependency Containers allow you to do very simple **Dependency Injection**
by associating `protocols` to concrete implementations
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
  
  var definitions = [DefinitionKey : Definition]()
  
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
    definitions.removeAll()
  }
  
  // MARK: Register dependencies
  
  /**
  Register a Void->T factory associated with optional tag.
  
  - parameter tag: The arbitrary tag to associate this factory with when registering with that protocol. Pass `nil` to associate with any tag. Default value is `nil`.
  - parameter factory: The factory to register, with return type of protocol you want to register it for
  
  - note: You must cast the factory return type to the protocol you want to register it for.
  Inside factory block if you need to reference container use it as `unowned` to avoid retain cycle.
  
  **Example**
  ```swift
  container.register { ServiceImp() as Service }
  container.register { [unowned container] ClientImp(service: container.resolve()) as Client }
  ```
  */
  public func register<T>(tag tag: Tag? = nil, factory: ()->T) -> DefinitionOf<T> {
    return register(tag: tag, factory: factory, scope: .Prototype) as DefinitionOf<T>
  }
  
  /**
   Register a Singleton instance associated with optional tag.
   
   - parameter tag: The arbitrary tag to associate this instance with when registering with that protocol. 
   Pass `nil` to associate with any tag.
   - parameter instance: The instance to register, with return type of protocol you want to register it for
   
   - note: You must cast the instance to the protocol you want to register it with (e.g `MyClass() as MyAPI`)
   */
  @available(*, deprecated, message="Use inScope(:) method of DefinitionOf instead to define scope.")
  public func register<T>(tag tag: Tag? = nil, @autoclosure(escaping) instance factory: ()->T) -> DefinitionOf<T> {
    return register(tag: tag, factory: { factory() }, scope: .Singleton)
  }
  
  /**
   Register generic factory associated with optional tag.
   
   - parameter tag: The arbitrary tag to look for when resolving this protocol.
   - parameter factory: generic factory that should be used to create concrete instance of type
   - parameter scope: scope of the component. Default value is `Prototype`
   
   - note: You should not call this method directly, instead call any of other `register` methods.
           You _should_ use this method only to register dependency with more runtime arguments
           than _Dip_ supports (currently it's up to six) like in this example:
   
   ```swift
   public func register<T, Arg1, Arg2, Arg3, ...>(tag: Tag? = nil, factory: (Arg1, Arg2, Arg3, ...) -> T) -> DefinitionOf<T> {
     return register(tag: tag, factory: factory, scope: .Prototype) as DefinitionOf<T>
   }
   ```
   
   Though before you do that you should probably review your design and try to reduce number of depnedencies.
   
   */
  public func register<T, F>(tag tag: Tag? = nil, factory: F, scope: ComponentScope) -> DefinitionOf<T> {
    let key = DefinitionKey(protocolType: T.self, factoryType: F.self, associatedTag: tag)
    let definition = DefinitionOf<T>(factory: factory, scope: scope)
    definitions[key] = definition
    return definition
  }
  
  // MARK: Resolve dependencies
  
  /**
  Resolve a dependency. 
  
  If no definition was registered with this `tag` for this `protocol`,
  it will try to resolve the definition associated with `nil` (no tag).
  
  - parameter tag: The arbitrary tag to look for when resolving this protocol.
  
  */
  public func resolve<T>(tag tag: Tag? = nil) -> T {
    return resolve(tag: tag) { (factory: ()->T) in factory() }
  }
  
  /**
   Resolve a dependency using generic builder closure that accepts generic factory and returns created instance.
   
   - parameter tag: The arbitrary tag to look for when resolving this protocol.
   - parameter builder: Generic closure that accepts generic factory and returns inctance produced by that factory
   
   - note: You should not call this method directly, instead call any of other `resolve` methods. (see `RuntimeArguments.swift`).
           You _should_ use this method only to resolve dependency with more runtime arguments than _Dip_ supports
           (currently it's up to six) like in this example:
   
   ```swift
   public func resolve<T, Arg1, Arg2, Arg3, ...>(tag tag: Tag? = nil, _ arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, ...) -> T {
     return resolve(tag: tag) { (factory: (Arg1, Arg2, Arg3, ...) -> T) in factory(arg1, arg2, arg3, ...) }
   }
   ```
   
   Though before you do that you should probably review your design and try to reduce the number of dependencies.
   
   */
  public func resolve<T, F>(tag tag: Tag? = nil, builder: F->T) -> T {
    let key = DefinitionKey(protocolType: T.self, factoryType: F.self, associatedTag: tag)
    let nilTagKey = tag.map { _ in DefinitionKey(protocolType: T.self, factoryType: F.self, associatedTag: nil) }

    guard let definition = (self.definitions[key] ?? self.definitions[nilTagKey]) as? DefinitionOf<T> else {
      fatalError("No definition registered with \(key) or \(nilTagKey)."
        + "Check the tag, type you try to resolve, number, order and types of runtime arguments passed to `resolve()`.")
    }

    let usingKey: DefinitionKey? = definition.scope == .ObjectGraph ? key : nil
    return _resolve(usingKey, definition: definition, builder: builder)
  }
  
  /// Actually resolve dependency
  private func _resolve<T, F>(key: DefinitionKey?, definition: DefinitionOf<T>, builder: F->T) -> T {
    
    resolvedInstances.incrementDepth()
    defer { resolvedInstances.decrementDepth() }
    
    if let previouslyResolved: T = resolvedInstances.previouslyResolved(key, definition: definition) {
      return previouslyResolved
    }
    else {
      let resolvedInstance = builder(definition.factory as! F)
      
      //when builder calls factory it will in turn resolve sub-dependencies (if there are any)
      //when it returns instance that we try to resolve here can be already resolved
      //so we return it, throwing away instance created by previous call to builder
      if let previouslyResolved: T = resolvedInstances.previouslyResolved(key, definition: definition) {
        return previouslyResolved
      }
      
      resolvedInstances.storeResolvedInstance(resolvedInstance, forKey: key, definition: definition)
      definition.resolveDependenciesBlock?(self, resolvedInstance)
      
      return resolvedInstance
    }
  }
  
  // MARK: - Private
  
  let resolvedInstances = ResolvedInstances()
  
  ///Pool to hold instances, created during call to `resolve()`. 
  ///Before `resolve()` returns pool is drained.
  class ResolvedInstances {
    var resolvedInstances = [DefinitionKey: Any]()
    
    func storeResolvedInstance<T>(instance: T, forKey key: DefinitionKey?, definition: DefinitionOf<T>) {
      self.resolvedInstances[key] = instance
      definition.resolvedInstance = instance
    }
    
    func previouslyResolved<T>(key: DefinitionKey?, definition: DefinitionOf<T>) -> T? {
      return (definition.resolvedInstance ?? self.resolvedInstances[key]) as? T
    }
    
    var depth: Int = 0

    func incrementDepth() {
      depth++
    }
    
    func decrementDepth() {
      guard depth-- > 0 else { fatalError("Depth can not be lower than zero") }
      if depth == 0 {
        resolvedInstances.removeAll()
      }
    }
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
  subscript(key: Key?) -> Value? {
    get {
      guard let key = key else { return nil }
      return self[key]
    }
    set {
      guard let key = key else { return }
      self[key] = newValue
    }
  }
}
