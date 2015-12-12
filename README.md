# Dip

[![CI Status](http://img.shields.io/travis/AliSoftware/Dip.svg?style=flat)](https://travis-ci.org/AliSoftware/Dip)
[![Version](https://img.shields.io/cocoapods/v/Dip.svg?style=flat)](http://cocoapods.org/pods/Dip)
[![License](https://img.shields.io/cocoapods/l/Dip.svg?style=flat)](http://cocoapods.org/pods/Dip)
[![Platform](https://img.shields.io/cocoapods/p/Dip.svg?style=flat)](http://cocoapods.org/pods/Dip)

![Animated Dipping GIF](cinnamon-pretzels-caramel-dipping.gif)  
_Photo courtesy of [www.kevinandamanda.com](http://www.kevinandamanda.com/recipes/appetizer/homemade-soft-cinnamon-sugar-pretzel-bites-with-salted-caramel-dipping-sauce.html)_

## Introduction

`Dip` is a simple **Dependency Injection Container**.

It's not true Dependency Injection, but it's damn close, and aimed to be as simple as possible.  
It's inspired by `.NET`'s [Unity Container](https://msdn.microsoft.com/library/ff647202.aspx).

* You start by creating `let dc = DependencyContainer()` and **register all your dependencies, by associating a `protocol` to an `instance` or a `factory`**.
* Then anywhere in your application, you can call `dc.resolve()` to **resolve a `protocol` into an instance of a concrete type** using that `DependencyContainer`.

This allows you to define the real, concrete types only in one place ([e.g. like this in your app](https://github.com/AliSoftware/Dip/blob/master/Example/DipSampleApp/DependencyContainers.swift#L22-L27), and [resetting it in your `setUp` for each Unit Tests](https://github.com/AliSoftware/Dip/blob/master/Example/Tests/SWAPIPersonProviderTests.swift#L17-L21)) and then [only work with `protocols` in your code](https://github.com/AliSoftware/Dip/blob/master/Example/DipSampleApp/Providers/SWAPIStarshipProvider.swift#L12) (which only define an API contract), without worrying about the real implementation.

## Advantages of DI and loose coupling

* Define clear API contracts before even thinking about implementation, and make your code loosly coupled with the real implementation.
* Easily switch between implementations — as long as they respect the same API contact (the `protocol`
* Greatly improve testability, as you can register a real instance in your app but a fake instance in your tests dedicated for testing / mocking the fonctionnality
* Get rid of those `sharedInstances` and avoid the singleton pattern at all costs

## Installation

Dip is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Dip"
```

If you use _Carthage_ add this line to your Cartfile:

```
github "AliSoftware/Dip"
```

## Playground

Dip comes with a **Playground** to introduce you to Inversion of Control, Dependency Injection, and how to use Dip in practice.

To play with it, [open `Dip.xcworkspace`](Dip/Dip.xcworkspace), then click on the `DipPlayground` entry in Xcode's Project Navigator and let it be your guide.

_Note: Do not open the `DipPlayground.playground` file directly, as it needs to be part of the workspace to access the Dip framework so that the demo code it contains can work._

The next paragraphs give you an overview of the Usage of _Dip_ directly, but if you're new to Dependency Injection, the Playground is probably a better start.

## Usage

*See [CHANGELOG.md](https://github.com/AliSoftware/Dip/blob/master/CHANGELOG.md) for instructions to migrate from 2.0.0 to 3.0.0*

### Register instance factories

First, create a `DependencyContainer` and use it to register instance factories with protocols, using those methods:

* `register(.Singleton) { … }` will register a singleton instance with a given protocol.
* `register(.Prototype) { … }` or `register(.ObjectGraph) { … }` will register an instance factory which generates a new instance each time you `resolve()`.
* You need **cast the instance to the protocol type** you want to register it with (e.g. `register { PlistUsersProvider() as UsersListProviderType }`).

Typically, to register your dependencies as early as possible in your app life-cycle, you will declare a `let dip: DependencyContainer = { … }()` somewhere (for example [in a dedicated `.swift` file](https://github.com/AliSoftware/Dip/blob/master/Example/DipSampleApp/DependencyContainers.swift#L22-L27)). In your (non-hosted, standalone) unit tests, you'll probably [reset them in your `func setUp()`](https://github.com/AliSoftware/Dip/blob/master/Example/Tests/SWAPIPersonProviderTests.swift#L17-L21) instead.

### Resolve dependencies

* `resolve()` will return a new instance matching the requested protocol.
* Explicitly specify the return type of `resolve` so that Swift's type inference knows which protocol you're trying to resolve.

```swift
container.register { ServiceImp() as Service }
let service = try! container.resolve() as Service
```

### Scopes

Dip provides three _scopes_ that you can use to register dependencies:

* The `.Prototype` scope will make the `DependencyContainer` resolve your type as __a new instance every time__ you call `resolve`. It's a default scope.
* The `.ObjectGraph` scope is like `.Prototype` scope but it will make the `DependencyContainer` to reuse resolved instances during one call to `resolve` method. When this call returns all resolved insances will be discarded and next call to `resolve` will produce new instances. This scope should be used to resolve circular dependencies.
* The `.Singleton` scope will make the `DependencyContainer` retain the instance once resolved the first time, and reuse it in the next calls to `resolve` during the container lifetime.


### Using block-based initialization

When calling the initializer of `DependencyContainer()`, you can pass a block that will be called right after the initialization. This allows you to have a nice syntax to do all your `register(…)` calls in there, instead of having to do them separately.

It may not seem to provide much, but given the fact that `DependencyContainers` are typically declared as global constants using a top-level `let`, it gets very useful, because instead of having to do it like this:

```swift
let dip: DependencyContainer = {
    let dip = DependencyContainer()

    dip.register { ProductionEnvironment(analytics: true) as EnvironmentType }
    dip.register { WebService() as WebServiceAPI }

    return dip
    }()
```

You can instead write this exact equivalent code, which is more compact, and indent better in Xcode (as the final closing brack is properly aligned):

```swift
let dip = DependencyContainer { dip in
    dip.register { ProductionEnvironment(analytics: true) as EnvironmentType }
    dip.register { WebService() as WebServiceAPI }
}
```

### Using tags to associate various factories to one protocol

* If you give a `tag` in the parameter to `register()`, it will associate that instance or factory with this tag, which can be used later during `resolve` (see below).
* `resolve(tag: tag)` will try to find an instance (or instance factory) that match both the requested protocol _and_ the tag. If it doesn't find any, it will fallback to an instance (or instance factory) that only match the requested protocol.
* The tags can be StringLiteralType or IntegerLiteralType. That said you can use plain strings or integers as tags.


```swift
enum WebService: String {
    case PersonWS
    case StarshipWS
    var tag: Tag { return Tag.String(self.rawValue) }
}

let wsDependencies = DependencyContainer() { dip in
    dip.register(tag: WebService.PersonWS.tag) { URLSessionNetworkLayer(baseURL: "http://prod.myapi.com/api/")! as NetworkLayer }
    dip.register(tag: WebService.StashipWS.tag) { URLSessionNetworkLayer(baseURL: "http://dev.myapi.com/api/")! as NetworkLayer }
}

let networkLayer = try! dip.resolve(tag: WebService.PersonWS.tag) as NetworkLayer
```

### Runtime arguments

You can register factories that accept up to six arguments. When you resolve dependency you can pass those arguments to `resolve()` method and they will be passed to the factory. Note that _number_, _types_ and _order_ of parameters matters. Also use of optional parameter and not optional parameter will result in two factories registered in container.

```swift
let webServices = DependencyContainer() { webServices in
	webServices.register { (url: NSURL, port: Int) in WebServiceImp1(url, port: port) as WebServiceAPI }
	webServices.register { (port: Int, url: NSURL) in WebServiceImp2(url, port: port) as WebServiceAPI }
	webServices.register { (port: Int, url: NSURL?) in WebServiceImp3(url!, port: port) as WebServiceAPI }
}

let service1 = try! webServices.resolve(withArguments: NSURL(string: "http://example.url")!, 80) as WebServiceAPI // service1 is WebServiceImp1
let service2 = try! webServices.resolve(withArguments: 80, NSURL(string: "http://example.url")!) as WebServiceAPI // service2 is WebServiceImp2
let service3 = try! webServices.resolve(withArguments: 80, NSURL(string: "http://example.url")) as WebServiceAPI // service3 is WebServiceImp3

```
Though Dip provides support for up to six runtime arguments out of the box you can extend this number using following code snippet for seven arguments:

```
func register<T, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7>(tag: Tag? = nil, scope: ComponentScope = .Prototype, factory: (Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7) -> T) -> DefinitionOf<T, (Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7) -> T)> {
	return registerFactory(tag, scope: .Prototype, factory: factory) as DefinitionOf<T, (Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7) -> T)>
}
	
func resolve<T, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7>(tag tag: Tag? = nil, withArguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5, _ arg6: Arg6, _ arg7: Arg7) throws -> T {
	return try resolve(tag) { (factory: (Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7) -> T) in factory(arg1, arg2, arg3, arg4, arg5, arg6, arg7) }
}

```

### Circular dependencies

_Dip_ supports circular dependencies. To resolve them use `ObjectGraph` scope and `resolveDependencies` method of `DefinitionOf` returned by `register` method.

```swift
container.register(.ObjectGraph) {
    ClientImp(server: try! container.resolve() as Server) as Client 
}

container.register(.ObjectGraph) { ServerImp() as Server }
    .resolveDependencies { container, server in 
        server.client = try! container.resolve() as Client
    }
```
More infromation about circular dependencies you can find in a playground.

### Thread safety

_Dip_ does not provide thread safety, so you need to make sure you always call `resolve` method of `DependencyContainer` from the single thread. 
Otherwise if two threads try to resolve the same type they can get different instances where the same instance is expected.

### Errors
Resolve operation is potentially dangerous cause you can use the wrong type, factory or a wrong tag. For that reason Dip throws an error
 `DefinitionNotFond(DefinitionKey)` if it failed to resolve type. When calling `resolve` you need to use `try` operator. 
 There are rare use cases where your application can recover from this kind of errors (for example you can register new types 
 when user unlocks some content). In most of the cases you can use `try!` to casue an exception at runtime if error was thrown
  or `try?` if it is appropriate in your case to have `nil`. This way `try!` surves as an additional mark for developers that resolution can fail.

### Concrete Example

Somewhere in your App target, register the dependencies:

```swift
let dip: DependencyContainer = {
    let dip = DependencyContainer()
    let env = ProductionEnvironment(analytics: true)
    dip.register(.Singleton) { env as EnvironmentType }
    dip.register(.Singleton) { WebService() as WebServiceType }
    dip.register() { (name: String) in DummyFriendsProvider(user: name) as FriendsProviderType }
    dip.register(tag: "me") { (_: String) in PlistFriendsProvider(plist: "myfriends") as FriendsProviderType }
    return dip
}
```

> Do the same in your Unit Tests target & test cases, but obviously with different Dependencies registered, depending on what you want to test and what instances you need to inject to provide dummy implementations for your tests.


Then to use dependencies throughout your app, use `dip.resolve()`, like this:

```swift
struct WebService {
  let env: EnvironmentType = try! dip.resolve()
  func sendRequest(path: String, …) {
    // ... use stuff like env.baseURL here
  }
}

struct SomeViewModel {
  let ws: WebServiceType = try! dip.resolve()
  var friendsProvider: FriendsProviderType
  init(userName: String) {
    friendsProvider = try! dip.resolve(tag: userName, userName)
  }
  func foo() {
    ws.someMethodDeclaredOnWebServiceType()
    let friends = friendsProvider.someFriendsProviderTypeMethod()
    print("friends: \(friends)")
  }
```

This way, when running your app target:

* `ws` will be resolved as your singleton instance `WebService` registered before.
* `friendsProvider` will be resolved as a new instance each time, which will be an instance created via `PlistFriendsProvider(plist: "myfriends")` if `userName` is `me` and created via `DummyFriendsProvider(userName)` for any other `userName` value (because `resolve(tag: userName, userName)` will fallback to `resolve(tag: nil, userName)` in that case, using the instance factory which was registered without a tag, but will pass `userName` as argument).

But when running your Unit tests target, it will probably resolve to other instances, depending on how you registered your dependencies in your Test Case.

### Complete Example Project

In addition to this Usage overview and to the aforementioned playground, you can also find a complete example in the `SampleApp/DipSampleApp` project provided in this repository.

This sample project is a bit more complex, but closer to real-world applications (even if this sample is all about StarWars!),
by declaring protocols like `NetworkLayer` which can be resolved to a `URLSessionNetworkLayer` in the real app, but to a dummy
network layer returning fixture data during the Unit Tests.

This sample uses the Star Wars API provided by swapi.co to fetch Star Wars characters and starships info and display them in TableViews.


## Credits

This library has been created by [**Olivier Halligon**](olivier@halligon.net).  
I'd also like to thank [**Ilya Puchka**](https://twitter.com/ilyapuchka) for his big contribution to it, as he added a lot of great features to it.

**Dip** is available under the **MIT license**. See the `LICENSE` file for more info.

The animated GIF at the top of this `README.md` is from [this recipe](http://www.kevinandamanda.com/recipes/appetizer/homemade-soft-cinnamon-sugar-pretzel-bites-with-salted-caramel-dipping-sauce.html) on the yummy blog of [Kevin & Amanda](http://www.kevinandamanda.com/recipes/). Go try the recipe!

The image used as the SampleApp LaunchScreen and Icon is from [Matthew Hine](https://commons.wikimedia.org/wiki/File:Chocolate_con_churros_-_San_Ginés,_Madrid.jpg) and is under _CC-by-2.0_.
