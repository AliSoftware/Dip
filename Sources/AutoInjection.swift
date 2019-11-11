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
  func autoInjectProperties(in instance: Any) throws {
    let mirror = Mirror(reflecting: instance)
    
    //mirror only contains class own properties
    //so we need to walk through super class mirrors
    //to resolve super class auto-injected properties
    var superClassMirror = mirror.superclassMirror
    while superClassMirror != nil {
      try superClassMirror?.children.forEach(resolveChild)
      superClassMirror = superClassMirror?.superclassMirror
    }
    
    try mirror.children.forEach(resolveChild)
  }
  
  private func resolveChild(child: Mirror.Child) throws {
    //HOTFIX for https://bugs.swift.org/browse/SR-2282
    guard !String(describing: type(of: child.value)).has(prefix: "ImplicitlyUnwrappedOptional") else { return }
    guard let injectedPropertyBox = child.value as? AutoInjectedPropertyBox else { return }
    
    let wrappedType = type(of: injectedPropertyBox).wrappedType
    let contextKey = DefinitionKey(type: wrappedType, typeOfArguments: Void.self, tag: context.tag)
    try inContext(key:contextKey, injectedInType: context?.resolvingType, injectedInProperty: child.label, logErrors: false) {
      try injectedPropertyBox.resolve(self)
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
public protocol AutoInjectedPropertyBox {
  ///The type of wrapped property.
  static var wrappedType: Any.Type { get }
  
  /**
   This method will be called by `DependencyContainer` during processing resolved instance properties.
   In this method you should resolve an instance for wrapped property and store a reference to it.
   
   - parameter container: A container to be used to resolve an instance
   
   - note: This method is not intended to be called manually, `DependencyContainer` will call it by itself.
   */
  func resolve(_ container: DependencyContainer) throws
}

#if swift(>=5.1)
/**
 Use this wrapper to identify _strong_ properties of the instance that should be
 auto-injected by `DependencyContainer`. Type T can be any type.
 
 **Example**:
 
 ```swift
 class ClientImp: Client {
   @Injected var service: Service?
 }
 ```
 
 - seealso: `InjectedWeak`
 
 */
@propertyWrapper
public struct Injected<T>: _InjectedPropertyBox, AutoInjectedPropertyBox {
  let valueBox: NullableBox<T> = NullableBox(nil)
  
  ///Wrapped value.
  public var wrappedValue: T? {
    get {
      return valueBox.unboxed
    }
    set {
      guard (required && newValue != nil) || !required else {
        fatalError("Can not set required property to nil.")
      }
      valueBox.unboxed = newValue
    }
  }
  

  let required: Bool
  let didInject: (T) -> ()
  let tag: DependencyContainer.Tag?
  let overrideTag: Bool

  public init(wrappedValue initialValue: T?) {
    self.init()
  }
}
#else
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
public struct Injected<T>: _InjectedPropertyBox, AutoInjectedPropertyBox {
  let valueBox: NullableBox<T> = NullableBox(nil)
  
  ///Wrapped value.
  public var value: T? {
    return valueBox.unboxed
  }

  let required: Bool
  let didInject: (T) -> ()
  let tag: DependencyContainer.Tag?
  let overrideTag: Bool
  
  /// Returns a new wrapper with provided value.
  func setValue(_ value: T?) -> Injected {
    guard (required && value != nil) || !required else {
      fatalError("Can not set required property to nil.")
    }
    
    return Injected(value: value, required: required, tag: tag, overrideTag: overrideTag, didInject: didInject)
  }
}
#endif

public extension Injected {
  ///The type of wrapped property.
  static var wrappedType: Any.Type {
    return T.self
  }
  
  init(value: T?, required: Bool = true, tag: DependencyTagConvertible?, overrideTag: Bool, didInject: @escaping (T) -> ()) {
    self.init(required: required, tag: tag, overrideTag: overrideTag, didInject: didInject)
    self.valueBox.unboxed = value
  }
  
  init(required: Bool = true, tag: DependencyTagConvertible?, overrideTag: Bool, didInject: @escaping (T) -> () = { _ in }) {
    self.required = required
    self.tag = tag?.dependencyTag
    self.overrideTag = overrideTag
    self.didInject = didInject
  }

  /**
   Creates a new wrapper for auto-injected property.
   
   - parameters:
      - required: Defines if the property is required or not.
                  If container fails to inject required property it will als fail to resolve
                  the instance that defines that property. Default is `true`.
      - tag: An optional tag to use to lookup definitions when injecting this property. Default is `nil`.
      - didInject: Block that will be called when concrete instance is injected in this property.
                   Similar to `didSet` property observer. Default value does nothing.
   */
  init(required: Bool = true, didInject: @escaping (T) -> () = { _ in }) {
    self.init(value: nil, required: required, tag: nil, overrideTag: false, didInject: didInject)
  }
  
  init(required: Bool = true, tag: DependencyTagConvertible?, didInject: @escaping (T) -> () = { _ in }) {
    self.init(value: nil, required: required, tag: tag, overrideTag: true, didInject: didInject)
  }

  func resolve(_ container: DependencyContainer) throws {
    let resolved: T? = try self.resolve(with: container, tag: tag, overrideTag: overrideTag, required: required)
    valueBox.unboxed = resolved
    if let resolved = resolved  {
      didInject(resolved)
    }
  }
}

#if swift(>=5.1)
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
   @InjectedWeak var client: Client?
 }
 ```
 
 - seealso: `Injected`
 
 */
@propertyWrapper
public struct InjectedWeak<T>: _InjectedPropertyBox, AutoInjectedPropertyBox {

  //Only classes (means AnyObject) can be used as `weak` properties
  //but we can not make <T: AnyObject> because that will prevent using protocol as generic type
  //so we just rely on user reading documentation and passing AnyObject in runtime
  //also we will throw fatal error if type can not be casted to AnyObject during resolution.
  
  let valueBox: WeakBox<T> = WeakBox(nil)
  
  ///Wrapped value.
  public var wrappedValue: T? {
    get {
      return valueBox.value
    }
    set {
      guard (required && newValue != nil) || !required else {
        fatalError("Can not set required property to nil.")
      }
      
      valueBox.unboxed = newValue as AnyObject
    }
  }
  
  let required: Bool
  let didInject: (T) -> ()
  let tag: DependencyContainer.Tag?
  let overrideTag: Bool
  
  public init(wrappedValue initialValue: T?) {
    self.init()
  }
}
#else
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
public struct InjectedWeak<T>: _InjectedPropertyBox, AutoInjectedPropertyBox {
  
  //Only classes (means AnyObject) can be used as `weak` properties
  //but we can not make <T: AnyObject> because that will prevent using protocol as generic type
  //so we just rely on user reading documentation and passing AnyObject in runtime
  //also we will throw fatal error if type can not be casted to AnyObject during resolution.
  
  let valueBox: WeakBox<T> = WeakBox(nil)
  
  ///Wrapped value.
  public var value: T? {
    return valueBox.value
  }

  let required: Bool
  let didInject: (T) -> ()
  let tag: DependencyContainer.Tag?
  let overrideTag: Bool
  
  
  /// Returns a new wrapper with provided value.
  func setValue(_ value: T?) -> InjectedWeak {
    guard (required && value != nil) || !required else {
      fatalError("Can not set required property to nil.")
    }
    
    return InjectedWeak(value: value, required: required, tag: tag, overrideTag: overrideTag, didInject: didInject)
  }
}
#endif

public extension InjectedWeak {
  ///The type of wrapped property.
  static var wrappedType: Any.Type {
    return T.self
  }
  
  init(value: T?, required: Bool = true, tag: DependencyTagConvertible?, overrideTag: Bool, didInject: @escaping (T) -> ()) {
    self.init(required: required, tag: tag, overrideTag: overrideTag, didInject: didInject)
    self.valueBox.unboxed = value as AnyObject
  }
  
  init(required: Bool = true, tag: DependencyTagConvertible?, overrideTag: Bool, didInject: @escaping (T) -> () = { _ in }) {
    self.required = required
    self.tag = tag?.dependencyTag
    self.overrideTag = overrideTag
    self.didInject = didInject
  }

  /**
   Creates a new wrapper for weak auto-injected property.
   
   - parameters:
      - required: Defines if the property is required or not.
                  If container fails to inject required property it will als fail to resolve
                  the instance that defines that property. Default is `true`.
      - tag: An optional tag to use to lookup definitions when injecting this property. Default is `nil`.
      - didInject: Block that will be called when concrete instance is injected in this property.
                   Similar to `didSet` property observer. Default value does nothing.
   */
  init(required: Bool = true, didInject: @escaping (T) -> () = { _ in }) {
    self.init(value: nil, required: required, tag: nil, overrideTag: false, didInject: didInject)
  }
  
  init(required: Bool = true, tag: DependencyTagConvertible?, didInject: @escaping (T) -> () = { _ in }) {
    self.init(value: nil, required: required, tag: tag, overrideTag: true, didInject: didInject)
  }
  
  func resolve(_ container: DependencyContainer) throws {
    let resolved: T? = try self.resolve(with: container, tag: tag, overrideTag: overrideTag, required: required)
    valueBox.unboxed = resolved as AnyObject
    if let resolved = resolved  {
      didInject(resolved)
    }
  }
}

protocol _InjectedPropertyBox {}

extension _InjectedPropertyBox {
  func resolve<T>(with container: DependencyContainer, tag: DependencyContainer.Tag?, overrideTag: Bool, required: Bool) throws -> T? {
    let tag = overrideTag ? tag : container.context.tag
    do {
      container.context.key = container.context.key.tagged(with: tag)
      let key = DefinitionKey(type: T.self, typeOfArguments: Void.self, tag: tag?.dependencyTag)
      return try resolve(with: container, key: key, builder: { (factory: (Any) throws -> Any) in try factory(()) }) as? T
    }
    catch {
        let error = DipError.autoInjectionFailed(label: container.context.injectedInProperty, type: container.context.resolvingType, underlyingError: error)
      if required {
        throw error
      }
      else {
        log(level: .Errors, error)
        return nil
      }
    }
  }
  
  func resolve<U>(with container: DependencyContainer, key: DefinitionKey, builder: ((U) throws -> Any) throws -> Any) throws -> Any {
    return try container._resolve(key: key, builder: { definition throws -> Any in
      try builder(definition.weakFactory)
    })
  }
  
}
