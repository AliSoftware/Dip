# Dip

[![CI Status](http://img.shields.io/travis/AliSoftware/Dip.svg?style=flat)](https://travis-ci.org/AliSoftware/Dip)
[![Version](https://img.shields.io/cocoapods/v/Dip.svg?style=flat)](http://cocoapods.org/pods/Dip)
[![License](https://img.shields.io/cocoapods/l/Dip.svg?style=flat)](http://cocoapods.org/pods/Dip)
[![Platform](https://img.shields.io/cocoapods/p/Dip.svg?style=flat)](http://cocoapods.org/pods/Dip)

![Chocolate con churros - San Ginés, Madrid](https://upload.wikimedia.org/wikipedia/commons/thumb/1/15/Chocolate_con_churros_-_San_Ginés%2C_Madrid.jpg/160px-Chocolate_con_churros_-_San_Ginés%2C_Madrid.jpg)  
_Photo by [Matthew Hine](http://www.flickr.com/photos/75771631@N00), cc-by-2.0_

## Introduction

`Dip` is a simple **Dependency Injection Container**.

It's not true Dependency Injection, but it's damn close, and aimed to be as simple as possible.  
It's inspired by `C#`'s [Unity Container](https://msdn.microsoft.com/library/ff647202.aspx).

* You start by **registering all your dependencies, by associating a `protocol` to an `instance` or to an `instanceFactory`**. So for example you'll register an association between the `protocol WebServiceAPI` and an instance or type of `MyRealWebService`.
* Then anywhere in your application, you can call `Dependency.resolve()` to **resolve a `protocol` into an instance of a concrete type**.

This allows you to define the real, concrete types only in one place (typically in your `AppDelegate` for your app, in your `setup` for your Unit Tests)
and **then only work with `protocols` in your code** (which only define an API contract), without worrying about the real implementation.

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

## Usage

### Register instances and instance factories

At the beginning of your app's life-cycle, you register instances and instance factories with protocols.

* `register(instance: _)` will register a singleton instance with a given protocol.
* `register(instanceFactory: _)` will register an instance factory — which generates a new instance each time you `resolve()`.
* You need _cast the instance to the protocol type_ you want to register it with (e.g. `register(instance: PlistUsersProvider() as UsersListProviderType)`).
* if you give a `tag` in the parameter to `register()`, it will associate that instance or instance factory with this tag, which can be used later during `resolve` (see below).

Typically, to register your dependencies as early as possible in your app life-cycle, you can do that either:

* in `@objc class func initialize() {}` declared in an `extension Dependency`, so it's called automatically before the first call to `Dependency.resolve()`
* or using a `private let _dependencies: Void = { … }()` (for example at the top of your `AppDelegate.swift`) as a trick to have code called as soon as the app in loaded
* In your (non-hosted, standalone) unit tests, you'll probably declare them in your `func setup()` for example

### Resolve dependencies

* `Dependency.resolve()` will return a new instance matching the requested protocol.
* Explicitly specify the return type of `resolve` so that Swift's type inference knows which protocol you're trying to resolve.
* If that protocol was registered as a singleton instance (using `register(instance: …)`, the same instance will be returned each time you call `resolve()` for this protocol type. Otherwise, the instance factory will generate a new instance each time.
* `Dependency.resolve(tag)` will try to find an instance (or instance factory) that match both the requested protocol _and_ the tag. If it doesn't find any, it will fallback to an instance (or instance factory) that only match the requested protocol.


### Example

Somewhere in your App target, register the dependencies. Best place to do that is probably in `Dependency.initialize()`:

```swift
extension Dependency {
    @objc class func initialize() {
        let env = ProductionEnvironment(analytics: true)
        Dependency.register(instance: env as EnvironmentType)
        Dependency.register(instance: WebService() as WebServiceType)
        Dependency.register() { DummyFriendsProvider(user: $0 ?? "Jane Doe") as FriendsProviderType }
        Dependency.register("me") { PlistFriendsProvider(plist: "myfriends") as FriendsProviderType }
    }
}
```

> Do the same in your Unit Tests target & test cases, but obviously with different Dependencies registered, depending on what you want to test and what instances you need to inject to provide dummy implementations for your tests.


Then to use dependencies throughout your app, use `Dependency.resolve()`, like this:

```swift
struct WebService {
  let env: EnvironmentType = Dependency.resolve()
  func sendRequest(path: String, …) {
    // ... use stuff like env.baseURL here
  }
}

struct SomeViewModel {
  let ws: WebServiceType = Dependency.resolve()
  var friendsProvider: FriendsProviderType
  init(userName: String) {
    friendsProvider = Dependency.resolve(userName)
  }
  func foo() {
    ws.someMethodDeclaredOnWebServiceType()
    let friends = friendsProvider.someFriendsProviderTypeMethod()
    print("friends: \(friends)")
  }
```

This way, when running your app target:

* `ws` will be resolved as your singleton instance `WebService` registered before.
* `friendsProvider` will be resolved as a new instance each time, which will be an instance created via `PlistFriendsProvider(plist: "myfriends")` if `userName` is `me` and created via `DummyFriendsProvider(userName)` for any other `userName` value (because `resolve(userName)` will fallback to `resolve(nil)` in that case, using the instance factory which was registered without a tag).

But when running your Unit tests target, it will probably resolve to other instances, depending on how you registered your dependencies in your Test Case.


## Work In Progress

* [x] Example project
* [ ] Unit Tests
* [x] README
* [ ] Source Documentation
* [ ] Thread-Safety


## Author

Olivier Halligon, olivier@halligon.net

## License

Dip is available under the MIT license. See the LICENSE file for more info.
