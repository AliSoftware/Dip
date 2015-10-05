# CHANGELOG

## 0.0.2

* Switched from class methods to instance methods ([#1](https://github.com/AliSoftware/Dip/issues/1)). This allows you to have multiple `DependencyContainers`
* Renamed the class from `Dependency` to `DependencyContainer`
* Renamed the `instanceFactory:` parameter to `factory:`
* Made the `DependencyContainer` generic of the type of _tag_. We are no longer limited to tags of type `String`, we can now use anything that's `Equatable`.

## 0.0.1

Initial version to release the early proof of concept.

Ready to use, but API may change, documentation and unit tests are missing, and thread-safety is not guaranteed.
