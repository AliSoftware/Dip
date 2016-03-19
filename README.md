# Dip

[![CI Status](http://img.shields.io/travis/AliSoftware/Dip.svg?style=flat)](https://travis-ci.org/AliSoftware/Dip)
[![Version](https://img.shields.io/cocoapods/v/Dip.svg?style=flat)](http://cocoapods.org/pods/Dip)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/cocoapods/l/Dip.svg?style=flat)](http://cocoapods.org/pods/Dip)
[![Platform](https://img.shields.io/cocoapods/p/Dip.svg?style=flat)](http://cocoapods.org/pods/Dip)

![Animated Dipping GIF](cinnamon-pretzels-caramel-dipping.gif)  
_Photo courtesy of [www.kevinandamanda.com](http://www.kevinandamanda.com/recipes/appetizer/homemade-soft-cinnamon-sugar-pretzel-bites-with-salted-caramel-dipping-sauce.html)_

## Introduction

`Dip` is a simple **Dependency Injection Container**.

It's aimed to be as simple as possible yet provide rich functionality usual for DI containers on other platforms. It's inspired by `.NET`'s [Unity Container](https://msdn.microsoft.com/library/ff647202.aspx) and other DI containers.

* You start by creating `let dc = DependencyContainer()` and **register all your dependencies, by associating a `protocol` to a `factory`**.
* Then you can call `dc.resolve()` to **resolve a `protocol` into an instance of a concrete type** using that `DependencyContainer`.

This allows you to define the real, concrete types only in one place ([e.g. like this in your app](SampleApp/DipSampleApp/DependencyContainers.swift#L22-L27), and [resetting it in your `setUp` for each Unit Tests](SampleApp/Tests/SWAPIPersonProviderTests.swift#L17-L21)) and then [only work with `protocols` in your code](SampleApp/DipSampleApp/Providers/SWAPIStarshipProvider.swift#L12) (which only define an API contract), without worrying about the real implementation.

> You can easily use Dip along with Storyboards and Nibs - checkout [Dip-UI](https://github.com/AliSoftware/Dip-UI) extensions. 

## Advantages of DI and loose coupling

* Define clear API contracts before even thinking about implementation, and make your code loosly coupled with the real implementation.
* Easily switch between implementations — as long as they respect the same API contact (the `protocol`), making your app modular and scalable.
* Greatly improve testability, as you can register a real instance in your app but a fake instance in your tests dedicated for testing / mocking the fonctionnality
* Enable parallel development in your team. You and your teammates can work independently on different parts of the app after you agree on the interfaces.
* As a bonus get rid of those `sharedInstances` and avoid the singleton pattern at all costs.


If you want to know more about Dependency Injection in general we recomend you to read ["Dependency Injection in .Net"](https://www.manning.com/books/dependency-injection-in-dot-net) by Mark Seemann. Dip was inspired particularly by implementations of some DI containers for .Net platform and shares core principles described in that book (even if you are not familiar with .Net platform the prenciples described in that book are platform agnostic).

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

If you use [_Swift Package Manager_](https://swift.org/package-manager/) add Dip as dependency to you `Package.swift`:

```
let package = Package(
  name: "MyPackage",
  dependencies: [
    .Package(url: "https://github.com/AliSoftware/Dip.git", "4.3.0")
  ]
)
```

## Running tests

On OSX you can run tests from Xcode. On Linux you need to have Swift Package Manager installed and use it to build test executable:

```
cd Dip/DipTests
swift build
./.build/debug/DipTests
```

## Playground

Dip comes with a **Playground** to introduce you to Inversion of Control, Dependency Injection, and how to use Dip in practice.

To play with it, [open `Dip.xcworkspace`](Dip/Dip.xcworkspace), then click on the `DipPlayground` entry in Xcode's Project Navigator and let it be your guide.

_Note: Do not open the `DipPlayground.playground` file directly, as it needs to be part of the workspace to access the Dip framework so that the demo code it contains can work._

The next paragraphs give you an overview of the Usage of _Dip_ directly, but if you're new to Dependency Injection, the Playground is probably a better start.

## Usage

### Register instance factories

First, create a `DependencyContainer` and use it to register instance factories with protocols, using those methods:

* `register() { … as SomeType }` will register provided factory with a given type.
* if you want to register an concrete implementation for some abstraction (protocol) you need **cast the instance to that protocol type** (e.g. `register { PlistUsersProvider() as UsersListProviderType }`).
* if you want just to register concrete type in container you may not need a type cast

Typically, to register your dependencies as early as possible in your app life-cycle, you will declare a `let dip: DependencyContainer = { … }()` somewhere, most likely in your `AppDelegate`. In unit tests you may configure container in each test method specifically and then reset it in `tearDown()`.

### Resolve dependencies

* `try resolve() as SomeType` will return a new instance matching the requested type (protocol or concrete type).
* `resolve()` is a generic method so you need to explicitly specify the return type (using `as` or explicitly providing type of a variable that will hold the resulting value) so that Swift's type inference knows which type you're trying to resolve.

```swift
container.register { ServiceImp() as Service }
let service = try! container.resolve() as Service
```

Ususally you will use _abstractions_ for your dependencies, but container can also resolve concrete types, if you register them. You can use that in cases where abstraction is not really required.

```swift
container.register { ServiceImp() }
let service: ServiceImp = try! container.resolve()
```


### Scopes

Dip provides three _scopes_ that you can use to register dependencies:

* The `.Prototype` scope will make the `DependencyContainer` resolve your type as __a new instance every time__ you call `resolve`. It's a default scope.
* The `.ObjectGraph` scope is like `.Prototype` scope but it will make the `DependencyContainer` to reuse resolved instances during one call to `resolve` method. When this call returns all resolved insances will be discarded and next call to `resolve` will produce new instances. This scope _must_ be used to properly resolve circular dependencies.
* The `.Singleton` scope will make the `DependencyContainer` retain the instance once resolved the first time, and reuse it in the next calls to `resolve` during the container lifetime.

You specify scope when you register dependency like that:

```swift
container.register() { ServiceImp() as Service } //.Prototype is a default
container.register(.ObjectGraph) { ServiceImp() as Service }
container.register(.Singleton) { ServiceImp() as Service }
```


### Using block-based initialization

When calling the initializer of `DependencyContainer()`, you can pass a block that will be called right after the initialization. This allows you to have a nice syntax to do all your `register(…)` calls in there, instead of having to do them separately.

It may not seem to provide much, but it gets very useful, because instead of having to do setup the container like this:

```swift
let dip: DependencyContainer = {
    let dip = DependencyContainer()

    dip.register { ProductionEnvironment(analytics: true) as EnvironmentType }
    dip.register { WebService() as WebServiceAPI }

    return dip
    }()
```

you can instead write this exact equivalent code, which is more compact, and indent better in Xcode (as the final closing brack is properly aligned):

```swift
let dip = DependencyContainer { dip in
    dip.register { ProductionEnvironment(analytics: true) as EnvironmentType }
    dip.register { WebService() as WebServiceAPI }
}
```

### Using tags to associate various factories to one type

* If you give a `tag` in the parameter to `register()`, it will associate that instance or factory with this tag, which can be used later during `resolve` (see below).
* `resolve(tag: tag)` will try to find a factory that match both the requested protocol _and_ the tag. If it doesn't find any, it will fallback to the factory that only match the requested type.
* The tags can be `StringLiteralType` or `IntegerLiteralType`. That said you can use plain strings or integers as tags.


```swift
enum WebService: String {
    case Production
    case Development
    
    var tag: DependencyContainer.Tag { return DependencyContainer.Tag.String(self.rawValue) }
}

let wsDependencies = DependencyContainer() { dip in
    dip.register(tag: WebService.Production.tag) { URLSessionNetworkLayer(baseURL: "http://prod.myapi.com/api/")! as NetworkLayer }
    dip.register(tag: WebService.Development.tag) { URLSessionNetworkLayer(baseURL: "http://dev.myapi.com/api/")! as NetworkLayer }
}

let networkLayer = try! dip.resolve(tag: WebService.PersonWS.tag) as NetworkLayer
```

### Runtime arguments

You can register factories that accept up to six arguments. When you resolve dependency you can pass those arguments to `resolve()` method and they will be passed to the factory. Note that _number_, _types_ and _order_ of parameters matters (see _Runtime arguments_ page of the Playground).

```swift
let webServices = DependencyContainer() { webServices in
	webServices.register { (url: NSURL, port: Int) in WebServiceImp1(url, port: port) as WebServiceAPI }
}

let service = try! webServices.resolve(withArguments: NSURL(string: "http://example.url")!, 80) as WebServiceAPI

```
Though Dip provides support for up to six runtime arguments out of the box you can extend that.

### Circular dependencies

_Dip_ supports circular dependencies. For that you need to register your components with `ObjectGraph` scope and use `resolveDependencies` method of `DefinitionOf` returned by `register` method like this:

```swift
container.register(.ObjectGraph) {
    ClientImp(server: try container.resolve() as Server) as Client 
}

container.register(.ObjectGraph) { ServerImp() as Server }
    .resolveDependencies { container, server in 
        server.client = try container.resolve() as Client
    }
```
More information about circular dependencies you can find in the Playground.

### Auto-wiring

When you use constructor injection to inject dependencies in your component auto-wiring enables you to resolve it just with one call to `resolve` method without carying about how to resolve all constructor arguments - container will resolve them for you.

```swift
class PresenterImp: Presenter {
    init(view: ViewOutput, interactor: Interactor, router: Router) { ... }
    ...
}

container.register { RouterImp() as Router }
container.register { View() as ViewOutput }
container.register { InteractorImp() as Interactor }
container.register { PresenterImp(view: $0, interactor: $1, router: $2) as Presenter }

let presenter = try! container.resolve() as Presenter
```

### Auto-injection

Auto-injection lets your resolve all property dependencies of the instance resolved by container with just one call, also allowing a simpler syntax to register circular dependencies.

```swift
protocol Server {
    weak var client: Client? { get }
}

protocol Client: class {
    var server: Server? { get }
}

class ServerImp: Server {
    private var injectedClient = InjectedWeak<Client>()
    var client: Client? { return injectedClient.value }
}

class ClientImp: Client {
    private var injectedServer = Injected<Server>()
    var server: Server? { get { return injectedServer.value} }
}

container.register(.ObjectGraph) { ServerImp() as Server }
container.register(.ObjectGraph) { ClientImp() as Client }

let client = try! container.resolve() as Client

```
You can find more use cases for auto-injection in the Playground available in this repository.

> Tip: You can use either `Injected<T>` and `InjectedWeak<T>` wrappers provided by Dip, or your own wrappers (even plain `Box<T>`) that conform to `AutoInjectedPropertyBox` protocol.

### Thread safety

`DependencyContainer` is thread safe, you can register and resolve components from different threads. 
Still we encourage you to register components in the main thread early in the application lifecycle to prevent race conditions 
when you try to resolve component from one thread while it was not yet registered in container by another thread.

### Errors

The resolve operation has a potential to fail because you can use the wrong type, factory or a wrong tag. For that reason Dip throws a `DipError` if it fails to resolve a type. Thus when calling `resolve` you need to use a `try` operator. 
There are very rare use cases when your application can recover from this kind of error. In most of the cases you can use `try!` to cause an exception at runtime if error was thrown or `try?` if a dependency is optional. This way `try!` serves as an additional mark for developers that resolution can fail. 
Dip also provides helpful descriptions for errors that can occur when you call `resolve`. See the source code documentation to know more about that.

### Concrete Example

Let's say you have some view model that depends on some data provider and web service:

```swift
struct WebService {
  let env: EnvironmentType
  
  init(env: EnvironmentType) {
    self.env = env
  }
  
  func sendRequest(path: String, …) {
    // … use stuff like env.baseURL here
  }
}

struct SomeViewModel {
  let ws: WebServiceType
  let friendsProvider: FriendsProviderType
  
  init(friendsProvider: FriendsProviderType, webService: WebServiceType) {
    self.friendsProvider = friendsProvider
    self.ws = webService
  }
  
  func foo() {
    ws.someMethodDeclaredOnWebServiceType()
    let friends = friendsProvider.someFriendsProviderTypeMethod()
    print("friends: \(friends)")
  }
}
```

As you can see we have few layers of dependencies here. All of them together represent _dependency graph_.
To be able to resolve this graph with Dip we need to make it aware of those types.
For that we register the dependencies somewhere early in app life cycle (most likely in AppDelegate):

```swift
let dip: DependencyContainer = {
    let dip = DependencyContainer()
    let enableAnalytics = … //i.e. read the setting from plist
    dip.register(.Singleton) { ProductionEnvironment(analytics: enableAnalytics) as EnvironmentType }
    dip.register(.Singleton) { WebService(env: try dip.resolve()) as WebServiceType }

    dip.register() { userName in DummyFriendsProvider(user: name) as FriendsProviderType }
    dip.register(tag: "me") { (_: String) in PlistFriendsProvider(plist: "myfriends") as FriendsProviderType }

    dip.register() { userName in
      let webService = try dip.resolve() as WebServiceType
      let friendsProvider = try dip.resolve(tag: userName, withArguments: userName) as 
      return SomeViewModel(friendsProvider: freindsProvider, webService: webService) 
    }
    return dip
}
```

> Do the same in your Unit Tests target & test cases, but obviously with different _implementations_ (test doubles) registered.

Then to resolve the graph use `dip.resolve()`, like this:

```swift
let viewModel = try! dip.resolve(withArguments: userName) as SomeViewModel
//now you can use view model or pass it to it's consumer

```

This way with just one call to `resolve()` you will have the whole graph of your dependencies resolved and ready to use:

* environmet will be resolved as a singleton instance of `ProductionEnvironment` with enabled analitycs;
* `ws` will be resolved as a singleton instance of `WebService` and will have it's `env` property set to `ProductionEnvironment`, already resolved (and reatined) by container.
* `friendsProvider` will be resolved as a new instance each time you create a view model, which will be an instance created via 
`PlistFriendsProvider(plist: "myfriends")` if `userName` is `me` and created via `DummyFriendsProvider(userName)` for any other 
`userName` value (because `resolve(tag: userName, withArguments: userName)` will fallback to `resolve(tag: nil, withArguments: userName)` in that case, using 
the instance factory which was registered without a tag, but will pass `userName` as an argument).
* view model will be created using `init(friendsProvider:webService:)` with `friendsProvider` and `webService` that have been 
already resolved by container.

When running your Unit tests target, it may be resolved with other instances, depending on how you registered your dependencies in your Test Case.

> Try to constrain calls to `resolve()` method to one place and try to use one call to `resolve()` to instantiate the whole graph of the dependencies. 
The same should be applied to dependencies registration - it should be performed with one call and should be done in one place. 
Don't scatter calls to container all around your code. Using `resolve` inside your implementations will be equal to creating dependencies directly and is actually against DI. Moreover it will drag the dependency on Dip everywhere and will make requirements of your types implicit instead of explicit. 
Instead you should combine use of container with DI patterns like _Constructor Injection_ and _Property Injection_. Any DI container is just a tool, not a goal.
You should aplly DI patterns in your code first and only then think about using DI container as a tool to make dependencies management easier. 
You will find some other advices on how to use the container in the Playground.
We hope that after reading this README and going through the Playground you will admit the benifits of DI and loose coupling that it enables whether you use Dip or not.

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
