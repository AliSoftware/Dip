//
// DipUI
//
// Copyright (c) 2016 Ilya Puchka <ilyapuchka@gmail.com>
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

#if (canImport(UIKit) || canImport(AppKit) || canImport(WatchKit))

extension DependencyContainer {
  ///Containers that will be used to resolve dependencies of instances, created by stroyboards.
  static public var uiContainers: [DependencyContainer] = {
    #if os(watchOS)
      swizzleAwakeWithContext
    #endif
    return []
  }()
  
  /**
   Resolves dependencies of passed in instance.
   Use this method to resolve dependencies of object created by storyboard.
   The type of the instance should be registered in the container.
   
   You should call this method only from implementation of `didInstantiateFromStoryboard(_:tag:)`
   of `StoryboardInstantiatable` protocol if you override its default implementation.
   
   This method will do the same as `resolve(tag:) as T`, but instead of creating 
   a new intance with a registered factory it will use passed in instance as a resolved instance.
   
   - parameters:
      - instance: The object which dependencies should be resolved
      - tag: An optional tag used to register the type (`T`) in the container
   
   **Example**:
   
   ```swift
   class ViewController: UIViewController, ServiceDelegate, StoryboardInstantiatable {
     var service: Service?

     func didInstantiateFromStoryboard(_ container: DependencyContainer, tag: DependencyContainer.Tag?) throws {
       try container.resolveDependencies(of: self as ServiceDelegate, tag: "vc")
     }
   }
   
   class ServiceImp: Service {
     weak var delegate: ServiceDelegate?
   }
   
   container.register(tag: "vc") { ViewController() }
     .resolvingProperties { container, controller in
       controller.service = try container.resolve() as Service
       controller.service.delegate = controller
     }
   
   container.register { ServiceImp() as Service }
   ```
   
   - seealso: `register(_:type:tag:factory:)`, `didInstantiateFromStoryboard(_:tag:)`
   
   */
  public func resolveDependencies<T>(of instance: T, tag: Tag? = nil) throws {
    _ = try resolve(tag: tag) { (_: () throws -> T) in instance }
  }
  
  /**
   Register storyboard type `T` which has to conform to `StoryboardInstantiatable` and associate it with an optional tag.
   
   - parameters:
      - type: Storyboard type to register definition for.
      - tag: The arbitrary tag to associate this factory with. Pass `nil` to associate with any tag. Default value is `nil`.
   
   - returns: A registered definition.
   
   - note: This method will register concrete types. If you need to register 
           as abstract types you should use standard `register` method from Dip.
           You should cast the factory return type to the protocol you want to 
           register it for (unless you want to register concrete type) or 
           provide `type` parameter.
   
   - seealso: `Definition`, `ComponentScope`, `DependencyTagConvertible`
   
   **Example**:
   ```swift
   // Register MyViewController
   container.register(storyboardType: MyViewController.self)
   // or
   container.register(tag: "myVC") { MyViewController() as MyViewControllerType }
   ```
   */
  public func register<T: NSObject>(storyboardType type: T.Type, tag: DependencyTagConvertible? = nil) -> Dip.Definition<T, ()> where T: StoryboardInstantiatable {
    return register(.unique, type: type, tag: tag, factory: { T() })
  }

}

#if os(watchOS)
  public protocol StoryboardInstantiatableType {}
#else
  public typealias StoryboardInstantiatableType = NSObjectProtocol
#endif

public protocol StoryboardInstantiatable: StoryboardInstantiatableType {

  /**
   This method will be called if you set a `dipTag` attirbute on the object in a storyboard
   that conforms to `StoryboardInstantiatable` protocol.
   
   - parameters:
      - tag: The tag value, that was set on the object in a storyboard
      - container: The `DependencyContainer` associated with storyboards
   
   The type that implements `StoryboardInstantiatable` protocol should be registered in `UIStoryboard.container`.
   Default implementation of that method calls `resolveDependenciesOf(_:tag:)`
   and pass it `self` instance and the tag.
   
   Usually you will not need to override the default implementation of this method
   if you registered the type of the instance as a concrete type in the container.
   Then you only need to add conformance to `StoryboardInstantiatable`.
   
   You may want to override it if you want to add custom logic before/after resolving dependencies
   or you want to resolve the instance as implementation of some protocol which it conforms to.
   
   - warning: This method will be called after `init?(coder:)` but before `awakeFromNib` method of `NSObject`.
              On watchOS this method will be called before `awakeWithContext(_:)`.
   
   **Example**:
   
   ```swift
   extension MyViewController: SomeProtocol { ... }
   
   extension MyViewController: StoryboardInstantiatable {
     func didInstantiateFromStoryboard(_ container: DependencyContainer, tag: DependencyContainer.Tag) throws {
       //resolve dependencies of the instance as SomeProtocol type
       try container.resolveDependencies(of: self as SomeProtocol, tag: tag)
       //do some additional setup here
     }
   }
   ```
  */
  func didInstantiateFromStoryboard(_ container: DependencyContainer, tag: DependencyContainer.Tag?) throws
  
}

extension StoryboardInstantiatable {
  public func didInstantiateFromStoryboard(_ container: DependencyContainer, tag: DependencyContainer.Tag?) throws {
    try container.resolveDependencies(of: self, tag: tag)
  }
}

#if os(iOS) || os(tvOS) || os(OSX)
  
#if os(iOS) || os(tvOS)
  import UIKit
#elseif os(OSX)
  import AppKit
#endif
  
let DipTagAssociatedObjectKey = UnsafeMutablePointer<Int8>.allocate(capacity: 1)

extension NSObject {
  
  ///A string tag that will be used to resolve dependencies of this instance
  ///if it implements `StoryboardInstantiatable` protocol.
  @objc private(set) public var dipTag: String? {
    get {
      return objc_getAssociatedObject(self, DipTagAssociatedObjectKey) as? String
    }
    set {
      objc_setAssociatedObject(self, DipTagAssociatedObjectKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
      guard let instantiatable = self as? StoryboardInstantiatable else { return }
      
      let tag = dipTag.map(DependencyContainer.Tag.String)
      
      for (index, container) in DependencyContainer.uiContainers.enumerated() {
        do {
          log("Trying to resolve \(type(of: self)) with UI container at index \(index)")
          try instantiatable.didInstantiateFromStoryboard(container, tag: tag)
          log("Resolved \(type(of: self))")
          return
        } catch { }
      }
    }
  }
  
}
  
func log(_ message: Any) {
  if Dip.LogLevel.Errors.rawValue <= Dip.logLevel.rawValue {
    Dip.logger(logLevel, message)
  }
}

#else
import WatchKit
  
let swizzleAwakeWithContext: Void = {
  let originalSelector = #selector(WKInterfaceController.awake(withContext:))
  let swizzledSelector = #selector(WKInterfaceController.dip_awake(withContext:))
  
  guard let originalMethod = class_getInstanceMethod(WKInterfaceController.self, originalSelector),
    let swizzledMethod = class_getInstanceMethod(WKInterfaceController.self, swizzledSelector) else { return }
  
  let didAddMethod = class_addMethod(WKInterfaceController.self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
  
  if didAddMethod {
    class_replaceMethod(WKInterfaceController.self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
  } else {
    method_exchangeImplementations(originalMethod, swizzledMethod)
  }
}()
  
extension WKInterfaceController: StoryboardInstantiatableType {

  @objc func dip_awake(withContext context: AnyObject?) {
    defer { self.dip_awake(withContext: context) }
    guard let instantiatable = self as? StoryboardInstantiatable else { return }
    
    for container in DependencyContainer.uiContainers {
      guard let _ = try? instantiatable.didInstantiateFromStoryboard(container, tag: nil) else { continue }
      break
    }
  }
  
}

#endif

#endif
