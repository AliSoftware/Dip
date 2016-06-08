# Dip

[![CI Status](http://img.shields.io/travis/AliSoftware/Dip.svg?style=flat)](https://travis-ci.org/AliSoftware/Dip)
[![Version](https://img.shields.io/cocoapods/v/Dip.svg?style=flat)](http://cocoapods.org/pods/Dip)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/cocoapods/l/Dip.svg?style=flat)](http://cocoapods.org/pods/Dip)
[![Platform](https://img.shields.io/cocoapods/p/Dip.svg?style=flat)](http://cocoapods.org/pods/Dip)
[![Swift Version](https://img.shields.io/badge/Linux-compatible-4BC51D.svg?style=flat)](https://developer.apple.com/swift)
[![Swift Version](https://img.shields.io/badge/Swift-2.2-F16D39.svg?style=flat)](https://developer.apple.com/swift)

![Animated Dipping GIF](cinnamon-pretzels-caramel-dipping.gif)  
_Photo courtesy of [www.kevinandamanda.com](http://www.kevinandamanda.com/recipes/appetizer/homemade-soft-cinnamon-sugar-pretzel-bites-with-salted-caramel-dipping-sauce.html)_

## Introduction

`Dip` is a simple **Dependency Injection Container**.

It's aimed to be as simple as possible yet provide rich functionality usual for DI containers on other platforms. It's inspired by `.NET`'s [Unity Container](https://msdn.microsoft.com/library/ff647202.aspx) and other DI containers.

* You start by creating `let container = DependencyContainer()` and **registering your dependencies, by associating a _protocol_ or _type_ to a `factory`**.
* Then you can call `container.resolve()` to **resolve an instance of _protocol_ or _type_** using that `DependencyContainer`.

> You can easily use Dip along with Storyboards and Nibs - checkout [Dip-UI](https://github.com/AliSoftware/Dip-UI) extensions. 

## Documentation & Usage Examples

Dip is completely [documented](http://cocoadocs.org/docsets/Dip/4.5.0/) and comes with a Playground that lets you try all its features and become familiar with API. You can find it in `Dip.xcworkspace`.

> Note: it may happen that you will need to build Dip framework before playground will be able to use it. For that select `Dip-iOS` scheme and build.

You can find bunch of usage examples in a [wiki](wiki).

There are also several blog posts that describe how to use Dip and some of its implementation details:

- [IoC container in Swift](http://ilya.puchka.me/ioc-container-in-swift/)
- [IoC container in Swift. Circular dependencies and auto-injection](http://ilya.puchka.me/ioc-container-in-swift-circular-dependencies-and-auto-injection/)
- [Dependency injection with Dip](http://ilya.puchka.me/dependency-injecinjection-with-dip/)

File an issue if you have any question.


## Features

- **[Scopes](wiki/scopes)**. Dip supports 4 different scopes (or life cycle strategies): _Prototype_, _ObjectGraph_, _Singleton_, _EagerSingleton_;
- **[Named definitions](wiki/named-definitions)**. You can register different factories for the same protocol or type by registering them with [tags]();
- **[Runtime arguments](wiki/runtime-arguments)**. You can register factories that accept up to 6 runtime arguments;
- **[Circular dependencies](wiki/circular-dependencies)**. Dip can resolve circular dependencies;
- **[Auto-wiring](wiki/auto-wiring)** & **[Auto-injection](wiki/auto-injection)**. Dip can infer your components' dependencies injected in constructor and automatically resolve them as well as dependencies injected with properties.
- **[Type forwarding](wiki/Type-forwarding)**. You can register the same factory to resolve different types.
- **[Storyboards integration](wiki/storyboards-integration)**. You can easily use Dip along with storyboards and Xibs without ever referencing container in your view controller's code;
- **Weakly typed components**. Dip can resolve weak types when they are unknown at compile time.
- **Easy configuration**. No complex container hierarchy, no unneeded functionality;
- **Thread safety**. Registering and resolving components is thread safe;
- **Helpful error messages and configuration validation**. You can validate your container configuration. If something can not be resolved at runtime Dip throws an error that completely describes the issue;

## Basic usage

```swift
import Dip

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // Create the container
    private let container = DependencyContainer { container in
    
        // Register some factory. ServiceImp here implements protocol Service
        container.register { ServiceImp() as Service }
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool { 
        
        // Resolve a concrete instance. Container will instantiate new instance of ServiceImp
        let service = try! container.resolve() as Service
    
        ...
    }
}

```

## More sophisticated example

```swift
import Dip

class AppDelegate: UIResponder, UIApplicationDelegate {
	private let container = DependencyContainer.configure()
	...
}

//CompositionRoot.swift
import Dip
import DipUI

extension DependencyContainer {

	static func configure() -> DependencyContainer {
		return DependencyContainer { container in 
			container.register(tag: "ViewController") { ViewController() }
			  .resolveDependencies { container, controller in
				  controller.animationsFactory = try container.resolve() as AnimatonsFactory
			}
    
			container.register { AuthFormBehaviourImp(apiClient: $0) as AuthFormBehaviour }
			container.register { container as AnimationsFactory }
			container.register { view in ShakeAnimationImp(view: view) as ShakeAnimation }
			container.register { APIClient(baseURL: NSURL(string: "http://localhost:2368")!) as ApiClient }
		}
	}

}

extension DependencyContainer: AnimationsFactory { 
    func shakeAnimation(view: UIView) -> ShakeAnimation {
        return try! self.resolve(withArguments: view)
    }
}

extension ViewController: StoryboardInstantiatable {}

//ViewController.swift

class ViewController {
    var animationsFactory: AnimationsFactory?

    private let _formBehaviour = Injected<AuthFormBehaviour>()
    
    var formBehaviour: AuthFormBehaviour? {
        return _formBehaviour.value
    }
	...
}

```

## Installation

Since version 4.3.1 Dip is built with Swift 2.2. The latest version built with Swift 2.1 is 4.3.0.

Dip is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Dip"
```

If you use [Carthage](https://github.com/Carthage/Carthage) add this line to your Cartfile:

```
github "AliSoftware/Dip"
```

If you use [Swift Package Manager](https://swift.org/package-manager/) add Dip as dependency to you `Package.swift`:

```swift
let package = Package(
  name: "MyPackage",
  dependencies: [
    .Package(url: "https://github.com/AliSoftware/Dip.git", "4.5.0")
  ]
)
```

## Running tests

On OSX you can run tests from Xcode. On Linux you need to have Swift Package Manager installed and use it to build and run tests:

```
cd Dip
swift build && swift test
```

> Note: Swift Package Manager is destributed with Swift development snapshots only, so it builds packages using Swift 3. To build Dip you will need to build it with Swift 2.2, for that you need to set [`$SWIFT_EXEC`](https://github.com/apple/swift-package-manager#choosing-swift-version) environment variable.

## Credits

This library has been created by [**Olivier Halligon**](olivier@halligon.net).  
I'd also like to thank [**Ilya Puchka**](https://twitter.com/ilyapuchka) for his big contribution to it, as he added a lot of great features to it.

**Dip** is available under the **MIT license**. See the `LICENSE` file for more info.

The animated GIF at the top of this `README.md` is from [this recipe](http://www.kevinandamanda.com/recipes/appetizer/homemade-soft-cinnamon-sugar-pretzel-bites-with-salted-caramel-dipping-sauce.html) on the yummy blog of [Kevin & Amanda](http://www.kevinandamanda.com/recipes/). Go try the recipe!

The image used as the SampleApp LaunchScreen and Icon is from [Matthew Hine](https://commons.wikimedia.org/wiki/File:Chocolate_con_churros_-_San_Ginés,_Madrid.jpg) and is under _CC-by-2.0_.
