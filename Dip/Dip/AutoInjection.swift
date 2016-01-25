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
    guard let injectedPropertyBox = child.value as? _AnyInjectedPropertyBox else { return }
    
    do {
      try injectedPropertyBox.resolve(self)
    }
    catch {
      throw DipError.AutoInjectionFailed(child.label, injectedPropertyBox.dynamicType.wrappedType, error)
    }
  }
  
}

private protocol _AnyInjectedPropertyBox: class {
  static var wrappedType: Any.Type { get }
  func resolve(container: DependencyContainer) throws
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
public final class Injected<T>: _InjectedPropertyBox<T>, _AnyInjectedPropertyBox {
  
  var _value: Any? = nil {
    didSet {
      if let value = value { didInject(value) }
    }
  }
  
  public var value: T? {
    return _value as? T
  }

  public override init(required: Bool = true, tag: DependencyContainer.Tag? = nil, didInject: T -> () = { _ in }) {
    super.init(required: required, tag: tag, didInject: didInject)
  }
  
  private func resolve(container: DependencyContainer) throws {
    let resolved: T? = try super.resolve(container)
    _value = resolved
  }
  
}

/**
 Use this wrapper to identify weak properties of the instance that should be injected when you call
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
public final class InjectedWeak<T>: _InjectedPropertyBox<T>, _AnyInjectedPropertyBox {

  //Only classes (means AnyObject) can be used as `weak` properties
  //but we can not make <T: AnyObject> because that will prevent using protocol as generic type
  //so we just rely on user reading documentation and passing AnyObject in runtime
  //also we will throw fatal error if type can not be casted to AnyObject during resolution.

  weak var _value: AnyObject? = nil {
    didSet {
      if let value = value { didInject(value) }
    }
  }
  
  public var value: T? {
    return _value as? T
  }

  public override init(required: Bool = true, tag: DependencyContainer.Tag? = nil, didInject: T -> () = { _ in }) {
    super.init(required: required, tag: tag, didInject: didInject)
  }
  
  private func resolve(container: DependencyContainer) throws {
    let resolved: T? = try super.resolve(container)
    guard let resolvedObject = resolved as? AnyObject else {
      fatalError("\(T.self) can not be casted to AnyObject. InjectedWeak wrapper should be used to wrap only classes.")
    }
    _value = resolvedObject
  }
  
}

private class _InjectedPropertyBox<T> {

  static var wrappedType: Any.Type {
    return T.self
  }

  let required: Bool
  let didInject: T -> ()
  let tag: DependencyContainer.Tag?

  init(required: Bool = true, tag: DependencyContainer.Tag?, didInject: T -> () = { _ in }) {
    self.required = required
    self.tag = tag
    self.didInject = didInject
  }

  private func resolve(container: DependencyContainer) throws -> T? {
    let resolved: T?
    if required {
      resolved = try container.resolve(tag: tag, builder: { (factory: () throws -> T) in try factory() }) as T
    }
    else {
      resolved = try? container.resolve(tag: tag, builder: { (factory: () throws -> T) in try factory() }) as T
    }
    return resolved
  }
  
}


