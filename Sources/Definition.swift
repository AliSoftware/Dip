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
  public let factoryType: Any.Type
  public let associatedTag: DependencyContainer.Tag?
  
  init(protocolType: Any.Type, factoryType: Any.Type, associatedTag: DependencyContainer.Tag? = nil) {
    self.protocolType = protocolType
    self.factoryType = factoryType
    self.associatedTag = associatedTag
  }
  
  public var hashValue: Int {
    return "\(protocolType)-\(factoryType)-\(associatedTag)".hashValue
  }
  
  public var description: String {
    return "type: \(protocolType), factory: \(factoryType), tag: \(associatedTag.desc)"
  }
}

/// Check two definition keys on equality by comparing their `protocolType`, `factoryType` and `associatedTag` properties.
public func ==(lhs: DefinitionKey, rhs: DefinitionKey) -> Bool {
  return
    lhs.protocolType == rhs.protocolType &&
      lhs.factoryType == rhs.factoryType &&
      lhs.associatedTag == rhs.associatedTag
}

///Component scope defines a strategy used by the `DependencyContainer` to manage resolved instances life cycle.
public enum ComponentScope {
  /// A new instance will be created each time it's resolved.
  case Prototype
  /// Resolved instances will be reused until topmost `resolve(tag:)` method returns.
  case ObjectGraph
  /// Resolved instance will be retained by the container and always reused. Do not mix this lifecycle with _singleton pattern_. Instance will be not shared between defferent containers.
  case Singleton
}

/**
 `DefinitionOf<T, F>` describes how instances of type `T` should be created when this type is resolved by the `DependencyContainer`.
 
 - `T` is the type of the instance to resolve
 - `F` is the type of the factory that will create an instance of T.
 
 For example `DefinitionOf<Service, (String) -> Service>` is the type of definition that will create an instance of type `Service` using factory that accepts `String` argument.
*/
public final class DefinitionOf<T, F>: Definition {
  
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
  public func resolveDependencies(block: (DependencyContainer, T) throws -> ()) -> DefinitionOf<T, F> {
    guard resolveDependenciesBlock == nil else {
      fatalError("You can not change resolveDependencies block after it was set.")
    }
    self.resolveDependenciesBlock = block
    return self
  }
  
  /// Calls `resolveDependencies` block if it was set.
  func resolveDependenciesOf(resolvedInstance: Any, withContainer container: DependencyContainer) throws {
    guard let resolvedInstance = resolvedInstance as? T else { return }
    try self.resolveDependenciesBlock?(container, resolvedInstance)
  }
  
  let factory: F
  private(set) var scope: ComponentScope = .Prototype
  
  private(set) var resolveDependenciesBlock: ((DependencyContainer, T) throws -> ())?
  
  public init(scope: ComponentScope, factory: F) {
    self.factory = factory
    self.scope = scope
  }
  
  private var _resolvedInstance: T?
  
}

///Dummy protocol to store definitions for different types in collection
public protocol Definition: class { }

protocol _Definition: Definition {

  var scope: ComponentScope { get }
  func resolveDependenciesOf(resolvedInstance: Any, withContainer container: DependencyContainer) throws
}

extension DefinitionOf: _Definition { }

extension DefinitionOf: CustomStringConvertible {
  public var description: String {
    return "type: \(T.self), factory: \(F.self), scope: \(scope)"
  }
}

