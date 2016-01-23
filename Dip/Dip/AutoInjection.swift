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

//MARK: Public

extension DependencyContainer {
  
  /**
   Resolves dependencies of passed object. Properties that should be injected must be of type `Injected<T>` or `InjectedWeak<T>`. This method will also recursively resolve their dependencies, building full object graph.
   
   - parameter instance: object whose dependecies should be resolved
   
   - Note:
   Use `InjectedWeak<T>` to define one of two circular dependecies if another dependency is defined as `Injected<U>`.
   This will prevent a retain cycle between resolved instances.
   
   - Warning: If you resolve dependencies of the object created not by container and it has auto-injected circular dependency, container will be not able to resolve it correctly because container does not have this object in it's resolved instances stack. Thus it will create another instance of that type to satisfy circular dependency.
   
   **Example**:
   ```swift
   class ClientImp: Client {
   var service = Injected<Service>()
   }
   
   class ServiceImp: Service {
   var client = InjectedWeak<Client>()
   }
   
   //when resolved client will have service injected
   let client = try! container.resolve() as Client
   
   ```
   
   */
  public func resolveDependencies(instance: Any) throws {
    try Mirror(reflecting: instance).children.forEach(resolveChild)
  }
  
  private func resolveChild(child: Mirror.Child) throws {
    try (child.value as? _AnyInjectedPropertyBox)?.resolve(self)
  }
  
}

/**
Use this wrapper to identifiy strong properties of the instance that should be injected when you call
`resolveDependencies()` on this instance. Type T can be any type.

- warning:
Do not define this property as optional or container will not be able to inject it.
Instead define it with initial value of `Injected<T>()`.
If you need to nilify wrapped value, assing property to `Injected<T>()`.

**Example**:

```swift
class ClientImp: Client {
  var service = Injected<Service>()
}

```
- seealso: `InjectedWeak`, `DependencyContainer.resolveDependencies(_:)`

*/
public final class Injected<T>: _AnyInjectedPropertyBox {
  
  var _value: Any? = nil {
    didSet {
      if let value = value { didInject(value) }
    }
  }
  
  private let required: Bool
  private let didInject: T -> ()
  
  public var value: T? {
    return _value as? T
  }

  public init(required: Bool = true, didInject: T -> () = { _ in }) {
    self.required = required
    self.didInject = didInject
  }
  
  static var tag: DependencyContainer.Tag {
    return .String(String(Injected<T>))
  }

  private func resolve(container: DependencyContainer) throws {
    if required {
      self._value = try container._resolve(self) as Any
    }
    else {
      self._value = try? container._resolve(self) as Any
    }
  }

}

/**
 Use this wrapper to identifiy weak properties of the instance that should be injected when you call
 `resolveDependencies()` on this instance. Type T should be a **class** type.
 Otherwise it will cause runtime exception when container will try to resolve the property.
 Use this wrapper to define one of two circular dependencies to avoid retain cycle.
 
 - note:
 The only difference between `InjectedWeak` and `Injected` is that `InjectedWeak` uses _weak_ reference
 to store underlying value, when `Injected` uses _strong_ reference. For that reason if you resolve instance
 that has _weak_ auto-injected property this property will be released when `resolve` returns because no one else
 holds reference to it except the container during dependency graph resolution.
 
 Use `InjectedWeak<T>` to define one of two circular dependecies if another dependency is defined as `Injected<U>`.
 This will prevent a retain cycle between resolved instances.

 - warning:
 Do not define this property as optional or container will not be able to inject it.
 Instead define it with initial value of `InjectedWeak<T>()`.
If you need to nilify wrapped value, assing property to `InjectedWeak<T>()`.

 **Example**:
 
 ```swift
 class ServiceImp: Service {
   var client = InjectedWeak<Client>()
 }

 ```
 
 - seealso: `Injected`, `DependencyContainer.resolveDependencies(_:)`
 
 */
public final class InjectedWeak<T>: _AnyInjectedPropertyBox {

  //Only classes (means AnyObject) can be used as `weak` properties
  //but we can not make <T: AnyObject> cause that will prevent using protocol as generic type
  //so we just rely on user reading documentation and passing AnyObject in runtime
  //also we will throw fatal error if type can not be casted to AnyObject during resolution

  weak var _value: AnyObject? = nil {
    didSet {
      if let value = value { didInject(value) }
    }
  }
  
  private let required: Bool
  private let didInject: T -> ()
  
  public var value: T? {
    return _value as? T
  }

  public init(required: Bool = true, didInject: T -> () = { _ in }) {
    self.required = required
    self.didInject = didInject
  }
  
  static var tag: DependencyContainer.Tag {
    return .String(String(InjectedWeak<T>))
  }

  private func resolve(container: DependencyContainer) throws {
    if required {
      self._value = try container._resolve(self) as AnyObject
    }
    else {
      self._value = try? container._resolve(self) as AnyObject
    }
  }

}

//MARK: - Private

typealias InjectedFactory = () throws -> Any
typealias InjectedWeakFactory = () throws -> AnyObject

private protocol _AnyInjectedPropertyBox: class {
  static var tag: DependencyContainer.Tag { get }
  func resolve(container: DependencyContainer) throws
}

extension DependencyContainer {
  private func _resolve<T>(injectedPropertyBox: _AnyInjectedPropertyBox) throws -> T {
    return try resolve(tag: injectedPropertyBox.dynamicType.tag) as T
  }
}

func autoInjectedType(tag: DependencyContainer.Tag?) -> String? {
  guard let tag = tag else { return nil }
  guard case let .String(stringTag) = tag else { return nil }
  
  return try! stringTag.match("^Injected(?:Weak)?<(.+)>$")?.dropFirst().first
}


