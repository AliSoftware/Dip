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
public final class Injected<T>: _InjectedPropertyBox {
  
  var _value: Any?
  
  public var value: T? {
    get {
      return _value as? T
    }
    set {
      _value = newValue
    }
  }

  public init() {}

}

/**
 Use this wrapper to identifiy weak properties of the instance that should be injected when you call
 `resolveDependencies()` on this instance. Type T should be a **class** type.
 Otherwise it will cause runtime exception when container will try to resolve the property.
 Use this wrapper to define one of two circular dependencies to avoid retain cycle.
 
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
 
 - note:
 The only difference between `InjectedWeak` and `Injected` is that `InjectedWeak` uses _weak_ reference
 to store underlying value, when `Injected` uses _strong_ reference.
 For that reason if you resolve instance that holds weakly injected property
 this property will be released when `resolve` returns 'cause no one else holds reference to it.
 
 - seealso: `Injected`, `DependencyContainer.resolveDependencies(_:)`
 
 */
public final class InjectedWeak<T>: _InjectedWeakPropertyBox {

  //Only classes (means AnyObject) can be used as `weak` properties
  //but we can not make <T: AnyObject> cause that will prevent using protocol as generic type
  //so we just rely on user reading documentation and passing AnyObject in runtime
  //also we will throw fatal error if type can not be casted to AnyObject during resolution

  weak var _value: AnyObject?
  
  public var value: T? {
    get {
      return _value as? T
    }
    set {
      _value = newValue as? AnyObject
    }
  }

  public init() {}

}

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
  public func resolveDependencies(instance: Any) {
    for child in Mirror(reflecting: instance).children {
      do {
        try (child.value as? _AnyInjectedPropertyBox)?.resolve(self)
      } catch {
        print(error)
      }
    }
  }

}

//MARK: - Private

typealias InjectedFactory = () throws -> Any
typealias InjectedWeakFactory = () throws -> AnyObject

extension DependencyContainer {
  
  func registerInjected(definition: AutoInjectedDefinition) {
    guard let key = definition.injectedKey,
      definition = definition.injectedDefinition else { return }
    definitions[key] = definition
  }
  
  func registerInjectedWeak(definition: AutoInjectedDefinition) {
    guard let key = definition.injectedWeakKey,
      definition = definition.injectedWeakDefinition else { return }
    definitions[key] = definition
  }
  
  func removeInjected(definition: AutoInjectedDefinition) {
    guard definition.injectedDefinition != nil else { return }
    definitions[definition.injectedKey] = nil
  }
  
  func removeInjectedWeak(definition: AutoInjectedDefinition) {
    guard definition.injectedWeakDefinition != nil else { return }
    definitions[definition.injectedWeakKey] = nil
  }

}

protocol _AnyInjectedPropertyBox: class {
  func resolve(container: DependencyContainer) throws
  static var tag: DependencyContainer.Tag { get }
}

extension _AnyInjectedPropertyBox {
  static var tag: DependencyContainer.Tag {
    return .String(String(self))
  }
  
  func _resolve<T>(container: DependencyContainer) throws -> T {
    return try container.resolve(tag: self.dynamicType.tag) as T
  }
}

protocol _InjectedPropertyBox: _AnyInjectedPropertyBox {
  var _value: Any? { get set }
}

extension _InjectedPropertyBox {
  func resolve(container: DependencyContainer) throws {
    self._value = try _resolve(container) as Any
  }
}

protocol _InjectedWeakPropertyBox: _AnyInjectedPropertyBox {
  weak var _value: AnyObject? { get set }
}

extension _InjectedWeakPropertyBox {
  func resolve(container: DependencyContainer) throws {
    self._value = try _resolve(container) as AnyObject
  }
}

func isInjectedTag(tag: DependencyContainer.Tag?) -> String? {
  guard let tag = tag else { return nil }
  guard case let .String(stringTag) = tag else { return nil }
  
  return try! stringTag.match("^Injected(?:Weak)?<(.+)>$")?.dropFirst().first
}

extension String {
  func match(pattern: String) throws -> [String]? {
    let expr = try NSRegularExpression(pattern: pattern, options: NSRegularExpressionOptions())
    let result = expr.firstMatchInString(self, options: NSMatchingOptions(), range: NSMakeRange(0, characters.count))
    return result?.allRanges.flatMap(safeSubstringWithRange)
  }
  
  func safeSubstringWithRange(range: NSRange) -> String? {
    if NSMaxRange(range) <= self.characters.count {
      return (self as NSString).substringWithRange(range)
    }
    return nil
  }
}

extension NSTextCheckingResult {
  var allRanges: [NSRange] {
    return (0..<numberOfRanges).map(rangeAtIndex)
  }
}

