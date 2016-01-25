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

///Internal representation of a key used to associate definitons and factories by tag, type and factory.
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

public func ==(lhs: DefinitionKey, rhs: DefinitionKey) -> Bool {
  return
    lhs.protocolType == rhs.protocolType &&
      lhs.factoryType == rhs.factoryType &&
      lhs.associatedTag == rhs.associatedTag
}

///Describes the lifecycle of instances created by container.
public enum ComponentScope {
  
  /// Indicates that a new instance of the component will be created each time it's resolved.
  case Prototype
  
  /// Indicates that resolved instance should be reused during object graph resolution but
  /// should be discurded when topmost `resolve` method returns.
  /// Always use this scope do define circular dependencies.
  case ObjectGraph
  
  /// Indicates that resolved instance should be retained and always reused.
  /// Instance will be released as soon as definition is removed from all containers 
  /// where it was registered or all these containers are deallocated.
  case Singleton
}

/**
 Definition of type T describes how instances of this type should be created when this type is resolved by container.
 
 - Generic parameter `T` is the type of the instance to resolve 
 - Generic parameter `F` is the type of block-factory that creates an instance of T.
 
 For example `DefinitionOf<Service,(String)->Service>` is the type of definition that during resolution will produce instance of type `Service` using closure that accepts `String` argument.
*/
public final class DefinitionOf<T, F>: Definition {
  
  /**
   Sets the block that will be used to resolve dependencies of the component. 
   This block will be called before `resolve` returns.
   
   - parameter block: block to use to resolve dependencies
   
   - note:  
   If you have circular dependencies at least one of them should use this block
   to resolve it's dependencies. Otherwise code enter infinite loop.
   
   **Example**
   
   ```swift
   container.register { ClientImp(service: container.resolve() as Service) as Client }

   var definition = container.register { ServiceImp() as Service }
   definition.resolveDependencies { container, service in
      service.delegate = try container.resolve() as Client
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
  
  func resolveDependencies(container: DependencyContainer, resolvedInstance: Any) throws {
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
  
  ///Will be stored only if scope is `Singleton`
  var resolvedInstance: T? {
    get {
      guard scope == .Singleton else { return nil }
      return _resolvedInstance
    }
    set {
      guard scope == .Singleton else { return }
      _resolvedInstance = newValue
    }
  }
  
  private var _resolvedInstance: T?
  
}

///Dummy protocol to store definitions for different types in collection
public protocol Definition: class { }

protocol _Definition: Definition {

  var scope: ComponentScope { get }

}

extension DefinitionOf: _Definition { }

extension DefinitionOf: CustomStringConvertible {
  public var description: String {
    return "type: \(T.self), factory: \(F.self), scope: \(scope), resolved instance: \(resolvedInstance.desc)"
  }
}

