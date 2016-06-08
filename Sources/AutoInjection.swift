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

extension DependencyContainer {
  
  /**
   Resolves properties of passed object wrapped with `Injected<T>` or `InjectedWeak<T>`
   */
  func autoInjectProperties(instance: Any) throws {
    try Mirror(reflecting: instance).children.forEach(_resolveChild)
  }
  
  private func _resolveChild(child: Mirror.Child) throws {
    guard let injectedPropertyBox = child.value as? AutoInjectedPropertyBox else { return }
    
    try inContext(
      context.tag,
      resolvingType: injectedPropertyBox.dynamicType.wrappedType,
      injectedInProperty: child.label)
    {
      do {
        try injectedPropertyBox.resolve(self)
      }
      catch {
        throw DipError.AutoInjectionFailed(label: child.label, type: injectedPropertyBox.dynamicType.wrappedType, underlyingError: error)
      }
    }
  }
  
}

/**
 Implement this protocol if you want to use your own type to wrap auto-injected properties
 instead of using `Injected<T>` or `InjectedWeak<T>` types.
 
 **Example**:
 
 ```swift
 class MyCustomBox<T> {
   private(set) var value: T?
   init() {}
 }
 
 extension MyCustomBox: AutoInjectedPropertyBox {
   static var wrappedType: Any.Type { return T.self }
 
   func resolve(container: DependencyContainer) throws {
     value = try container.resolve() as T
   }
 }
 ```

*/
public protocol AutoInjectedPropertyBox: class {
  ///The type of wrapped property.
  static var wrappedType: Any.Type { get }
  
  /**
   This method will be called by `DependencyContainer` during processing resolved instance properties.
   In this method you should resolve an instance for wrapped property and store a reference to it.
   
   - parameter container: A container to be used to resolve an instance
   
   - note: This method is not intended to be called manually, `DependencyContainer` will call it by itself.
   */
  func resolve(container: DependencyContainer) throws
}

/**
 Use this wrapper to identify _strong_ properties of the instance that should be
 auto-injected by `DependencyContainer`. Type T can be any type.

 - warning: Do not define this property as optional or container will not be able to inject it.
            Instead define it with initial value of `Injected<T>()`.

 **Example**:

 ```swift
 class ClientImp: Client {
   var service = Injected<Service>()
 }
 ```
 - seealso: `InjectedWeak`

*/
public final class Injected<T>: _InjectedPropertyBox<T>, AutoInjectedPropertyBox {
  
  ///The type of wrapped property.
  public static var wrappedType: Any.Type {
    return T.self
  }

  ///Wrapped value.
  public private(set) var value: T? {
    didSet {
      if let value = value { didInject(value) }
    }
  }

  /**
   Creates a new wrapper for auto-injected property.
   
   - parameters:
      - required: Defines if the property is required or not. 
                  If container fails to inject required property it will als fail to resolve 
                  the instance that defines that property. Default is `true`.
      - tag: An optional tag to use to lookup definitions when injecting this property. Default is `nil`.
      - didInject: block that will be called when concrete instance is injected in this property. 
                   Similar to `didSet` property observer. Default value does nothing.
  */
  public convenience init(required: Bool = true, didInject: T -> () = { _ in }) {
    self.init(value: nil, required: required, tag: nil, overrideTag: false, didInject: didInject)
  }

  public convenience init(required: Bool = true, tag: DependencyTagConvertible?, didInject: T -> () = { _ in }) {
    self.init(value: nil, required: required, tag: tag, overrideTag: true, didInject: didInject)
  }

  private init(value: T?, required: Bool = true, tag: DependencyTagConvertible?, overrideTag: Bool, didInject: T -> ()) {
    self.value = value
    super.init(required: required, tag: tag, overrideTag: overrideTag, didInject: didInject)
  }

  public func resolve(container: DependencyContainer) throws {
    let resolved: T? = try super.resolve(container)
    value = resolved
  }
  
  /// Returns a new wrapper with provided value.
  public func setValue(value: T?) -> Injected {
    guard (required && value != nil) || !required else {
      fatalError("Can not set required property to nil.")
    }
    
    return Injected(value: value, required: required, tag: tag, overrideTag: overrideTag, didInject: didInject)
  }
  
}

/**
 Use this wrapper to identify _weak_ properties of the instance that should be
 auto-injected by `DependencyContainer`. Type T should be a **class** type.
 Otherwise it will cause runtime exception when container will try to resolve the property.
 Use this wrapper to define one of two circular dependencies to avoid retain cycle.
 
 - note: The only difference between `InjectedWeak` and `Injected` is that `InjectedWeak` uses 
         _weak_ reference to store underlying value, when `Injected` uses _strong_ reference. 
         For that reason if you resolve instance that has a _weak_ auto-injected property this property
         will be released when `resolve` will complete.
 
 Use `InjectedWeak<T>` to define one of two circular dependecies if another dependency is defined as `Injected<U>`.
 This will prevent a retain cycle between resolved instances.

 - warning: Do not define this property as optional or container will not be able to inject it.
            Instead define it with initial value of `InjectedWeak<T>()`.

 **Example**:
 
 ```swift
 class ServiceImp: Service {
   var client = InjectedWeak<Client>()
 }

 ```
 
 - seealso: `Injected`
 
 */
public final class InjectedWeak<T>: _InjectedPropertyBox<T>, AutoInjectedPropertyBox {

  //Only classes (means AnyObject) can be used as `weak` properties
  //but we can not make <T: AnyObject> because that will prevent using protocol as generic type
  //so we just rely on user reading documentation and passing AnyObject in runtime
  //also we will throw fatal error if type can not be casted to AnyObject during resolution.

  ///The type of wrapped property.
  public static var wrappedType: Any.Type {
    return T.self
  }

  private weak var _value: AnyObject? = nil {
    didSet {
      if let value = value { didInject(value) }
    }
  }
  
  ///Wrapped value.
  public var value: T? {
    return _value as? T
  }

  /**
   Creates a new wrapper for weak auto-injected property.
   
   - parameters:
      - required: Defines if the property is required or not.
                  If container fails to inject required property it will als fail to resolve
                  the instance that defines that property. Default is `true`.
      - tag: An optional tag to use to lookup definitions when injecting this property. Default is `nil`.
      - didInject: block that will be called when concrete instance is injected in this property.
                   Similar to `didSet` property observer. Default value does nothing.
   */
  public convenience init(required: Bool = true, didInject: T -> () = { _ in }) {
    self.init(value: nil, required: required, tag: nil, overrideTag: false, didInject: didInject)
  }

  public convenience init(required: Bool = true, tag: DependencyTagConvertible?, didInject: T -> () = { _ in }) {
    self.init(value: nil, required: required, tag: tag, overrideTag: true, didInject: didInject)
  }

  private init(value: T?, required: Bool = true, tag: DependencyTagConvertible?, overrideTag: Bool, didInject: T -> ()) {
    self._value = value as? AnyObject
    super.init(required: required, tag: tag, overrideTag: overrideTag, didInject: didInject)
  }

  public func resolve(container: DependencyContainer) throws {
    let resolved: T? = try super.resolve(container)
    if required && !(resolved is AnyObject) {
      fatalError("\(T.self) can not be casted to AnyObject. InjectedWeak wrapper should be used to wrap only classes.")
    }
    _value = resolved as? AnyObject
  }
  
  /// Returns a new wrapper with provided value.
  public func setValue(value: T?) -> InjectedWeak {
    let _value = value as? AnyObject
    if value != nil && _value == nil {
      fatalError("\(T.self) can not be casted to AnyObject. InjectedWeak wrapper should be used to wrap only classes.")
    }
    guard (required && _value != nil) || !required else {
      fatalError("Can not set required property to nil.")
    }

    return InjectedWeak(value: value, required: required, tag: tag, overrideTag: overrideTag, didInject: didInject)
  }

}

private class _InjectedPropertyBox<T> {

  let required: Bool
  let didInject: T -> ()
  let tag: DependencyContainer.Tag?
  let overrideTag: Bool

  init(required: Bool = true, tag: DependencyTagConvertible?, overrideTag: Bool, didInject: T -> () = { _ in }) {
    self.required = required
    self.tag = tag?.dependencyTag
    self.overrideTag = overrideTag
    self.didInject = didInject
  }

  private func resolve(container: DependencyContainer) throws -> T? {
    let resolved: T?
    let tag = overrideTag ? self.tag : container.context.tag
    if required {
      resolved = try container.resolve(tag: tag) as T
    }
    else {
      resolved = try? container.resolve(tag: tag) as T
    }
    return resolved
  }
  
}


