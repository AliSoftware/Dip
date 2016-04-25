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
  public let protocolType: Any.Type
  public let argumentsType: Any.Type
  public let associatedTag: DependencyContainer.Tag?
  
  init(protocolType: Any.Type, argumentsType: Any.Type, associatedTag: DependencyContainer.Tag? = nil) {
    self.protocolType = protocolType
    self.argumentsType = argumentsType
    self.associatedTag = associatedTag
  }
  
  public var hashValue: Int {
    return "\(protocolType)-\(argumentsType)-\(associatedTag)".hashValue
  }
  
  public var description: String {
    return "type: \(protocolType), arguemnts: \(argumentsType), tag: \(associatedTag.desc)"
  }
  
}

/// Check two definition keys on equality by comparing their `protocolType`, `factoryType` and `associatedTag` properties.
public func ==(lhs: DefinitionKey, rhs: DefinitionKey) -> Bool {
  return
    lhs.protocolType == rhs.protocolType &&
      lhs.argumentsType == rhs.argumentsType &&
      lhs.associatedTag == rhs.associatedTag
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
  case Prototype
  
  /**
   Instance resolved with the same definition will be reused until topmost `resolve(tag:)` method returns.
   When you resolve the same object graph again the container will create new instances.
   Use this strategy if you want different object in objects graph to share the same instance.
   
   - warning: Make sure this component is thread safe or accessed always from the same thread.
   
   **Example**:
   
   ```
   container.register(.ObjectGraph) { ServiceImp() as Service }
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
  case ObjectGraph

  /**
   Resolved instance will be retained by the container and always reused.
   Do not mix this life cycle with _singleton pattern_.
   Instance will be not shared between different containers.
   
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
   The same scope as `Singleton`, but instance will be created when container is bootstrapped.
   
   - seealso: `bootstrap()`
  */
  case EagerSingleton
}

/**
 `DefinitionOf<T, F>` describes how instances of type `T` should be created when this type is resolved by the `DependencyContainer`.
 
 - `T` is the type of the instance to resolve
 - `F` is the type of the factory that will create an instance of T.
 
 For example `DefinitionOf<Service, (String) -> Service>` is the type of definition that will create an instance of type `Service` using factory that accepts `String` argument.
*/
public final class DefinitionOf<T, F>: Definition {
  
  let factory: F
  let scope: ComponentScope
  
  private(set) var weakFactory: (Any throws -> Any)!
  private var resolveDependenciesBlock: ((DependencyContainer, Any) throws -> ())?
  
  //Auto-wiring helpers
  
  private(set) var autoWiringFactory: ((DependencyContainer, DependencyContainer.Tag?) throws -> Any)?
  private(set) var numberOfArguments: Int = 0
  
  init(scope: ComponentScope, factory: F) {
    self.factory = factory
    self.scope = scope
  }

  /**
   Set the block that will be used to resolve dependencies of the instance.
   This block will be called before `resolve(tag:)` returns. It can be set only once.
   
   - parameter block: The block to use to resolve dependencies of the instance.
   
   - returns: modified definition
   
   - note: To resolve circular dependencies at least one of them should use this block
   to resolve its dependencies. Otherwise the application will enter an infinite loop and crash.
   
   **Example**
   
   ```swift
   container.register { ClientImp(service: try container.resolve() as Service) as Client }

   container.register { ServiceImp() as Service }
     .resolveDependencies { container, service in
       service.client = try container.resolve() as Client
   }
   ```
   
   */
  public func resolveDependencies(block: (DependencyContainer, T) throws -> ()) -> DefinitionOf {
    guard resolveDependenciesBlock == nil else {
      fatalError("You can not change resolveDependencies block after it was set.")
    }
    self.resolveDependenciesBlock = { try block($0, $1 as! T) }
    return self
  }
  
  /**
   Provides information about forwarded types that are also implemented by registered instance.
   Use this method to reuse the same definition to resolve different types.
   You can register up to 4 forwarded types. You can not change forwarded types after they were set once.
   Every type implicitly registers its optional variants as forwarded types.
   
   - warning: Currently in Swift there is no way to guaranty type safety in this method.
              That is - there is no way to ensure that an instance produced by this definition
              actually implements forwarded type. If you provide forwarded type that is not
              actually implemented by a produced instance container will throw
              an error when you will try to resolve forwarded type (unless weakly-typed `resolve` is used).
   
   - parameter a: Forwarded type
   
   - returns: modified definition
   
   **Example**:
   
   ```swift
   class ServiceImp: Service, AnotherService { ... }
   
   container.register { ServiceImp() as Service }
     .implements(AnotherService.self)
   
   let service = try! container.resolve() as Service
   let service = try! container.resolve() as AnotherService
   ```
   
  */
  public func implements<A>(a: A.Type) -> DefinitionOf {
    let types: [Any.Type] = [a, Optional<A>.self, ImplicitlyUnwrappedOptional<A>.self]
    _implementingTypes.appendContentsOf(types)
    return self
  }

  /// - seealso: `implements(_:)`
  public func implements<A, B>(a: A.Type, _ b: B.Type) -> DefinitionOf {
    let types: [Any.Type] = [
      a, (A?).self, (A!).self,
      b, (B?).self, (B!).self
    ]
    _implementingTypes.appendContentsOf(types)
    return self
  }

  /// - seealso: `implements(_:)`
  public func implements<A, B, C>(a: A.Type, _ b: B.Type, _ c: C.Type) -> DefinitionOf {
    let types: [Any.Type] = [
      a, (A?).self, (A!).self,
      b, (B?).self, (B!).self,
      c, (C?).self, (C!).self
    ]
    _implementingTypes.appendContentsOf(types)
    return self
  }

  /// - seealso: `implements(_:)`
  public func implements<A, B, C, D>(a: A.Type, _ b: B.Type, _ c: C.Type, _ d: D.Type) -> DefinitionOf {
    let types: [Any.Type] = [
      a, (A?).self, (A!).self,
      b, (B?).self, (B!).self,
      c, (C?).self, (C!).self,
      d, (D?).self, (D!).self
    ]
    _implementingTypes.appendContentsOf(types)
    return self
  }

  private var _implementingTypes = [Any.Type]() {
    willSet {
      guard _implementingTypes.isEmpty else {
        fatalError("You can not change implementing types after they were set.")
      }
    }
  }

  var implementingTypes: [Any.Type] {
    return [(T?).self, (T!).self] + _implementingTypes
  }
  
  /// Calls `resolveDependencies` block if it was set.
  func resolveDependenciesOf(resolvedInstance: Any, withContainer container: DependencyContainer) throws {
    guard let resolvedInstance = resolvedInstance as? T else { return }
    try self.resolveDependenciesBlock?(container, resolvedInstance)
  }
  
}

///Dummy protocol to store definitions for different types in collection
public protocol Definition: class { }

protocol _Definition: Definition {
  var scope: ComponentScope { get }

  var weakFactory: (Any throws -> Any)! { get }

  var numberOfArguments: Int { get }
  var autoWiringFactory: ((DependencyContainer, DependencyContainer.Tag?) throws -> Any)? { get }
  var implementingTypes: [Any.Type] { get }
  
  func resolveDependenciesOf(resolvedInstance: Any, withContainer container: DependencyContainer) throws
}

extension _Definition {
  func supportsAutoWiring() -> Bool {
    return autoWiringFactory != nil && numberOfArguments > 0
  }
}

extension DefinitionOf: _Definition {
}

extension DefinitionOf: CustomStringConvertible {
  public var description: String {
    return "type: \(T.self), factory: \(F.self), scope: \(scope)"
  }
}

/// Internal class used to build definition
class DefinitionBuilder<T, U> {
  typealias F = U throws -> T
  
  var scope: ComponentScope!
  var factory: F!
  
  var numberOfArguments: Int = 0
  var autoWiringFactory: ((DependencyContainer, DependencyContainer.Tag?) throws -> T)?
  
  init(@noescape configure: (DefinitionBuilder -> ())) {
    configure(self)
  }
  
  func build() -> DefinitionOf<T, F> {
    let factory = self.factory
    let definition = DefinitionOf<T, F>(scope: scope, factory: factory)
    definition.numberOfArguments = numberOfArguments
    definition.autoWiringFactory = autoWiringFactory
    definition.weakFactory = {
      guard let args = $0 as? U else {
        let key = DefinitionKey(protocolType: T.self, argumentsType: U.self)
        throw DipError.DefinitionNotFound(key: key)
      }
      return try factory(args)
    }
    return definition
  }
}

