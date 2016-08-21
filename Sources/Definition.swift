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

///A key used to store definitons in a container.
public struct DefinitionKey : Hashable, CustomStringConvertible {
  public let type: Any.Type
  public let typeOfArguments: Any.Type
  public private(set) var tag: DependencyContainer.Tag?

  init(type: Any.Type, typeOfArguments: Any.Type, tag: DependencyContainer.Tag? = nil) {
    self.type = type
    self.typeOfArguments = typeOfArguments
    self.tag = tag
  }
  
  public var hashValue: Int {
    return "\(type)-\(typeOfArguments)-\(tag)".hashValue
  }
  
  public var description: String {
    return "type: \(type), arguments: \(typeOfArguments), tag: \(tag.desc)"
  }
  
  func tagged(_ tag: DependencyContainer.Tag?) -> DefinitionKey {
    var tagged = self
    tagged.tag = tag
    return tagged
  }
  
}

//MARK: - Deprecated
extension DefinitionKey {
  
  @available(*, deprecated: 4.6.1, message: "Property protocolType was renamed to type")
  public var protocolType: Any.Type { return type }
  @available(*, deprecated: 4.6.1, message: "Property argumentsType was renamed to typeOfArguments")
  public var argumentsType: Any.Type { return typeOfArguments }
  @available(*, deprecated: 4.6.1, message: "Property associatedTag was renamed to tag")
  public var associatedTag: DependencyContainer.Tag? { return tag }
}

/// Check two definition keys on equality by comparing their `type`, `factoryType` and `tag` properties.
public func ==(lhs: DefinitionKey, rhs: DefinitionKey) -> Bool {
  return
    lhs.type == rhs.type &&
      lhs.typeOfArguments == rhs.typeOfArguments &&
      lhs.tag == rhs.tag
}

///Component scope defines a strategy used by the `DependencyContainer` to manage resolved instances life cycle.
public enum ComponentScope {
  /**
   A new instance will be created every time it's resolved.
   This is a default strategy. Use this strategy when you don't want instances to be shared
   between different consumers (i.e. if it is not thread safe).
   
   **Example**:
   
   ```
   container.register { ServiceImp() as Service }
   container.register { 
     ServiceConsumerImp(
       service1: try container.resolve() as Service
       service2: try container.resolve() as Service
     ) as ServiceConsumer
   }
   let consumer = container.resolve() as ServiceConsumer
   consumer.service1 !== consumer.service2 //true
   
   ```
   */
  case Unique
  
  @available(*, deprecated: 4.6.1, message: "Prototype scope is renamed to Unique")
  case Prototype
  
  /**
   Instance resolved with the same definition will be reused until topmost `resolve(tag:)` method returns.
   When you resolve the same object graph again the container will create new instances.
   Use this strategy if you want different object in objects graph to share the same instance.
   
   - warning: Make sure this component is thread safe or accessed always from the same thread.
   
   **Example**:
   
   ```
   container.register(.Shared) { ServiceImp() as Service }
   container.register {
     ServiceConsumerImp(
       service1: try container.resolve() as Service
       service2: try container.resolve() as Service
     ) as ServiceConsumer
   }
   let consumer1 = container.resolve() as ServiceConsumer
   let consumer2 = container.resolve() as ServiceConsumer
   consumer1.service1 === consumer1.service2 //true
   consumer2.service1 === consumer2.service2 //true
   consumer1.service1 !== consumer2.service1 //true
   ```
   */
  case Shared
  
  @available(*, deprecated: 4.6.1, message: "ObjectGraph scope is renamed to Shared")
  case ObjectGraph

  /**
   Resolved instance will be retained by the container and always reused.
   Do not mix this life cycle with _singleton pattern_.
   Instance will be not shared between different containers unless they collaborate.
   
   - warning: Make sure this component is thread safe or accessed always from the same thread.
   
   - note: When you override or remove definition from the container an instance 
           that was resolved with this definition will be released. When you reset 
           the container it will release all singleton instances.
   
   **Example**:
   
   ```
   container.register(.Singleton) { ServiceImp() as Service }
   container.register {
     ServiceConsumerImp(
       service1: try container.resolve() as Service
       service2: try container.resolve() as Service
     ) as ServiceConsumer
   }
   let consumer1 = container.resolve() as ServiceConsumer
   let consumer2 = container.resolve() as ServiceConsumer
   consumer1.service1 === consumer1.service2 //true
   consumer2.service1 === consumer2.service2 //true
   consumer1.service1 === consumer2.service1 //true
   ```
   */
  case Singleton
  
  /**
   The same scope as a `Singleton`, but instance will be created when container is bootstrapped.
   
   - seealso: `bootstrap()`
  */
  case EagerSingleton
  
  /**
   The same scope as a `Singleton`, but container stores week reference to the resolved instance.
   While a strong reference to the resolved instance exists resolve will return the same instance.
   After the resolved instance is deallocated next resolve will produce a new instance.
  */
  case WeakSingleton
}

///Dummy protocol to store definitions for different types in collection
public protocol Definition: class { }

/**
 `DefinitionOf<T, F>` describes how instances of type `T` should be created when this type is resolved by the `DependencyContainer`.
 
 - `T` is the type of the instance to resolve
 - `F` is the type of the factory that will create an instance of T.
 
 For example `DefinitionOf<Service, (String) -> Service>` is the type of definition that will create an instance of type `Service` using factory that accepts `String` argument.
*/
public final class DefinitionOf<T, F>: Definition {
  
  init(scope: ComponentScope, factory: F) {
    self.factory = factory
    self.scope = scope
  }
  
  //MARK: - _Definition

  let factory: F
  let scope: ComponentScope
  fileprivate(set) var weakFactory: ((Any) throws -> Any)!
  fileprivate(set) var resolveDependenciesBlock: ((DependencyContainer, Any) throws -> ())?
  
  /**
   Set the block that will be used to resolve dependencies of the instance.
   This block will be called before `resolve(tag:)` returns.
   
   - parameter block: The block to use to resolve dependencies of the instance.
   
   - returns: modified definition
   
   - note: To resolve circular dependencies at least one of them should use this block
           to resolve its dependencies. Otherwise the application will enter an infinite loop and crash.
   
   - note: You can call this method several times on the same definition. 
           Container will call all provided blocks in the same order.
   
   **Example**
   
   ```swift
   container.register { ClientImp(service: try container.resolve() as Service) as Client }
   
   container.register { ServiceImp() as Service }
     .resolvingProperties { container, service in
       service.client = try container.resolve() as Client
     }
   ```
   
   */
  @discardableResult public func resolvingProperties(_ block: @escaping (DependencyContainer, T) throws -> ()) -> DefinitionOf {
    let oldBlock = self.resolveDependenciesBlock
    self.resolveDependenciesBlock = {
      try oldBlock?($0, $1 as! T)
      try block($0, $1 as! T)
    }
    return self
  }

  /// Calls `resolveDependencies` block if it was set.
  func resolveProperties(instance: Any, container: DependencyContainer) throws {
    guard let resolvedInstance = instance as? T else { return }
    if let resolveDependenciesBlock = self.resolveDependenciesBlock {
      try resolveDependenciesBlock(container, resolvedInstance)
    }
  }
  
  //MARK: - AutoWiringDefinition
  
  fileprivate(set) var autoWiringFactory: ((DependencyContainer, DependencyContainer.Tag?) throws -> Any)?
  fileprivate(set) var numberOfArguments: Int?
  
  //MARK: - TypeForwardingDefinition
  
  /// Types that can be resolved using this definition.
  fileprivate(set) var implementingTypes: [Any.Type] = [(T?).self, (T!).self]
  
  /// Return `true` if type can be resolved using this definition
  func doesImplements(_ type: Any.Type) -> Bool {
    return implementingTypes.contains(where: { $0 == type })
  }
  
  //MARK: - _TypeForwardingDefinition

  /// Adds type as being able to be resolved using this definition
  fileprivate func implements(_ type: Any.Type) {
    implements([type])
  }
  
  /// Adds types as being able to be resolved using this definition
  fileprivate func implements(_ types: [Any.Type]) {
    implementingTypes.append(contentsOf: types.filter({ !doesImplements($0) }))
  }

  /// Definition to which resolution will be forwarded to
  fileprivate weak var forwardsToDefinition: _TypeForwardingDefinition? {
    didSet {
      if let forwardsToDefinition = forwardsToDefinition {
        implements(forwardsToDefinition.type)
        implements(forwardsToDefinition.implementingTypes)
        
        for definition in [forwardsToDefinition] + forwardsToDefinition.forwardsFromDefinitions {
          definition.implements(type)
          definition.implements(implementingTypes)
        }
        forwardsToDefinition.forwardsFromDefinitions.append(self)
        resolvingProperties({ try forwardsToDefinition.resolveProperties(instance: $1, container: $0) })
      }
    }
  }
  
  /// Definitions that will forward resolution to this definition
  fileprivate var forwardsFromDefinitions: [_TypeForwardingDefinition] = []
  
}

//MARK: - _Definition

protocol _Definition: Definition, AutoWiringDefinition, TypeForwardingDefinition {
  var type: Any.Type { get }
  var scope: ComponentScope { get }
  var weakFactory: ((Any) throws -> Any)! { get }
  func resolveProperties(instance: Any, container: DependencyContainer) throws
}

//MARK: - Type Forwarding

private protocol _TypeForwardingDefinition: TypeForwardingDefinition, _Definition {
  weak var forwardsToDefinition: _TypeForwardingDefinition? { get set }
  var forwardsFromDefinitions: [_TypeForwardingDefinition] { get set }
  func implements(_ type: Any.Type)
  func implements(_ type: [Any.Type])
}

extension DefinitionOf: _TypeForwardingDefinition {
  var type: Any.Type {
    return T.self
  }
}

extension DefinitionOf: CustomStringConvertible {
  public var description: String {
    return "type: \(T.self), factory: \(F.self), scope: \(scope)"
  }
}

//MARK: - Definition Builder

/// Internal class used to build definition
/// Need this builder as alternative to changing to DefinitionOf<T, U> where U - type of arguments
class DefinitionBuilder<T, U> {
  typealias F = (U) throws -> T
  
  var scope: ComponentScope!
  var factory: F!
  
  var numberOfArguments: Int?
  var autoWiringFactory: ((DependencyContainer, DependencyContainer.Tag?) throws -> T)?
  
  var forwardsDefinition: _Definition?
  
  init(configure: (DefinitionBuilder) -> ()) {
    configure(self)
  }
  
  func build() -> DefinitionOf<T, F> {
    let factory = self.factory!
    let definition = DefinitionOf<T, F>(scope: scope, factory: factory)
    definition.numberOfArguments = numberOfArguments
    definition.autoWiringFactory = autoWiringFactory
    definition.weakFactory = { try factory($0 as! U) }
    definition.forwardsToDefinition = forwardsDefinition as? _TypeForwardingDefinition
    return definition
  }
}

//MARK: - Deprecated methods

extension DefinitionOf {
  
  @available(*, deprecated:4.6.1, message:"Use resolvingProperties(_:)")
  public func resolveDependencies(block: @escaping (DependencyContainer, T) throws -> ()) -> DefinitionOf {
    return resolvingProperties(block)
  }

}
