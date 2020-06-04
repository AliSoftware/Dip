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

/**
`DependencyContainer` allows you to do _Dependency Injection_
by associating abstractions to concrete implementations.
*/
public final class DependencyContainer {
  
  /**
   Use a tag in case you need to register multiple factories fo the same type,
   to differentiate them. Tags can be either String or Int, to your convenience.
   
   - seealso: `DependencyTagConvertible`
   */
  public enum Tag {
    case String(StringLiteralType)
    case Int(IntegerLiteralType)
  }

  var autoInjectProperties: Bool
  internal(set) public var context: Context!
  let definitions = DefinitionsContainer()
  var resolvedInstances = ResolvedInstances()
  private let lock = RecursiveLock()
  
  let parent: DependencyContainer?
  var bootstrapped = false
  var bootstrapQueue: [() throws -> ()] = []
  
  private var _weakCollaborators: [WeakBox<DependencyContainer>] = []
  var _collaborators: [DependencyContainer] {
    get {
      return _weakCollaborators.compactMap({ $0.value })
    }
    set {
      _weakCollaborators = newValue.filter({ $0 !== self }).map(WeakBox.init)
    }
  }
  
  public static var enableAutoInjection: Bool? = nil;

  /**
   Designated initializer for a DependencyContainer

   - Parameters:
     - autoInjectProperties: Whether container should perform properties auto-injection. Default is `true`.
     - configBlock: A configuration block in which you typically put all you `register` calls.
   
   - note: The `configBlock` is simply called at the end of the `init` to let you configure everything. 
           It is only present for convenience to have a cleaner syntax when declaring and initializing
           your `DependencyContainer` instances. 
   
   - warning: If you use `configBlock` you need to make sure you don't create retain cycles. For example
              there will be a retain cycle between container and its definition if you reference container
              inside definition's factory. You can avoid that by using unowned reference to container:
   
   ```swift
   let container = DependencyContainer() { container in
     unowned let container = container
     //register definitions
   }
   ```
   
   - returns: A new DependencyContainer.
   */
  public init(parent: DependencyContainer? = nil, autoInjectProperties: Bool = true, configBlock: (DependencyContainer)->() = { _ in }) {
    self.autoInjectProperties = DependencyContainer.enableAutoInjection ?? autoInjectProperties
    self.parent = parent
    configBlock(self)
  }
  
  /**
   Call this method to complete container setup. After container is bootstrapped
   you can not add or remove definitions. Trying to do so will cause runtime exception.
   You can completely reset container, after reset you can bootstrap it again. 
   During bootsrap container will instantiate components registered with `EagerSingleton` scope.
   
   - throws: `DipError` if failed to instantiate any component
  */
  public func bootstrap() throws {
    try threadSafe {
      bootstrapped = true
      try bootstrapQueue.forEach({ try $0() })
      bootstrapQueue.removeAll()
    }
  }

  func threadSafe<T>(_ closure: () throws -> T) rethrows -> T {
    lock.lock()
    defer { lock.unlock() }
    return try closure()
  }
  
}

extension DependencyContainer {
  
  /**
   Context provides contextual information about resolution process.
   
   You can use the context for debugging or to pass through tag when you explicitly resolve dependencies.
   When auto-wiring or auto-injecting tag will be implicitly passed through by the container.
   For auto-injected properties you can disable that by providing tag (some value or `nil`) when defining property.
   
   **Example**:
   
   ```swift
   class SomeServiceImp: SomeService {
     //container will pass through the tag ("tag") used to resolve containing instance to resolve this property
     let injected = Injected<SomeDependency>()
   
     //container will use "someTag" tag to resolve this property
     let injectedTagged = Injected<SomeDependency>(tag: "someTag")
   
     //container will use `nil` tag to resolve this property
     let injectedNilTag = Injected<SomeDependency>(tag: nil)
   }
   
   container.register {
     //container will pass through the tag ("tag") used to resolve SomeService to resolve $0
     SomeServiceImp(dependency: $0) as SomeService
   }.resolvingProperties { container, service in
     //container will use `nil` tag to resolve this dependency
     self.dependency = try container.resolve() as SomeDependency
   
     //container will use current context tag ("tag") to resolve this dependency
     self.taggedDependency = try container.resolve(tag: container.context.tag) as SomeDependency
   }
   
   //container will use "tag" to resolve this instance
   let service = try! container.resolve(tag: "tag") as SomeService
   
   ```
   */
  public struct Context: CustomStringConvertible, CustomDebugStringConvertible {
    
    internal(set) public var key: DefinitionKey
    
    /// Currently resolving type.
    public var resolvingType: Any.Type {
      return key.type
    }

    /// The tag used to resolve currently resolving type.
    public var tag: Tag? {
      return key.tag
    }
    
    /// The type that caused currently resolving type to be resolved.
    /// `nil` for root object in a dependencies graph.
    private(set) public var injectedInType: Any.Type?
    
    /// The label of the property where resolved instance will be auto-injected.
    private(set) public var injectedInProperty: String?

    /// The Container that triggered the initial resolve
    private(set) public var container: DependencyContainer
    
    let inCollaboration: Bool
    
    var logErrors: Bool = true
    
    init(key: DefinitionKey, injectedInType: Any.Type?, injectedInProperty: String?, inCollaboration: Bool, container: DependencyContainer) {
      self.key = key
      self.injectedInType = injectedInType
      self.injectedInProperty = injectedInProperty
      self.inCollaboration = inCollaboration
      self.container = container
    }
    
    public var debugDescription: String {
      return "Context(key: \(key), injectedInType: \(injectedInType.desc), injectedInProperty: \(injectedInProperty.desc) logErrors: \(logErrors))"
    }
    
    public var description: String {
      let resolvingDescription = "Resolving type \(key.type) with arguments \(key.typeOfArguments) \(key.tag != nil ? "tagged with \(key.tag!)" : "")"
      if injectedInProperty != nil {
        return "\(resolvingDescription) while auto-injecting property \(injectedInProperty.desc) of \(injectedInType.desc)"
      }
      else if injectedInType != nil {
        return "\(resolvingDescription) while injecting in type \(injectedInType.desc)"
      }
      else {
        return resolvingDescription
      }
    }
    
  }

  /// Pushes new context created with provided values and calls block. When block returns previous context is restored.
  /// When popped to initial (root) context will release all references to resolved instances and call `Resolvable` callbacks.
  func inContext<T>(key aKey: DefinitionKey, injectedInType: Any.Type?, injectedInProperty: String? = nil, inCollaboration: Bool = false, container: DependencyContainer, logErrors: Bool! = nil, block: () throws -> T) rethrows -> T {
    let key = aKey
    return try threadSafe {
      let currentContext = self.context
      
      defer {
        context = currentContext
        
        //clean instances pool if it is owned not by other container
        if context == nil {
          resolvedInstances.resolvedInstances.removeAll()
          for (key, instance) in resolvedInstances.sharedWeakSingletons {
            if resolvedInstances.sharedWeakSingletons[key] is WeakBoxType { continue }
            resolvedInstances.sharedWeakSingletons[key] = WeakBox(instance)
          }
          for (key, instance) in resolvedInstances.weakSingletons {
            if resolvedInstances.weakSingletons[key] is WeakBoxType { continue }
            resolvedInstances.weakSingletons[key] = WeakBox(instance)
          }
          
          for resolvedInstance in resolvedInstances.resolvableInstances.reversed() {
            resolvedInstance.didResolveDependencies()
          }
          resolvedInstances.resolvableInstances.removeAll()
        }
      }
      
      context = Context(
        key: key,
        injectedInType: injectedInType,
        injectedInProperty: injectedInProperty,
        inCollaboration: inCollaboration,
        container: container
      )
      context.logErrors = logErrors ?? currentContext?.logErrors ?? true
      
      do {
        return try block()
      }
      catch {
        if context.logErrors { log(level: .Errors, error) }
        throw error
      }
    }
  }

}

//MARK: - Collaborating containers

extension DependencyContainer {
  
  /**
   Adds collaborating containers as weak references. Circular references are allowed.
   References to the container itself are ignored.
   */
  public func collaborate(with containers: DependencyContainer...) {
    collaborate(with: containers)
  }
  
  /**
   Adds collaborating containers as weak references. Circular references are allowed.
   References to the container itself are ignored.
   */
  public func collaborate(with containers: [DependencyContainer]) {
    _collaborators += containers
    for container in containers {
      container._collaborators += [self]
      container.resolvedInstances.sharedSingletonsBox = self.resolvedInstances.sharedSingletonsBox
      container.resolvedInstances.sharedWeakSingletonsBox = self.resolvedInstances.sharedWeakSingletonsBox
      updateCollaborationReferences(between: container, and: self)
    }
  }
  
  private func updateCollaborationReferences(between container: DependencyContainer, and collaborator: DependencyContainer) {
    for container in container._collaborators {
      guard container.resolvedInstances.sharedSingletonsBox !== collaborator.resolvedInstances.sharedSingletonsBox else { continue }
      container.resolvedInstances.sharedSingletonsBox = collaborator.resolvedInstances.sharedSingletonsBox
      container.resolvedInstances.sharedWeakSingletonsBox = collaborator.resolvedInstances.sharedWeakSingletonsBox
      updateCollaborationReferences(between: container, and: collaborator)
    }
  }
  
  /// Tries to resolve key using collaborating containers
  func collaboratingResolve<T>(key aKey: DefinitionKey, builder: (_Definition) throws -> T) -> T? {
    let key = aKey
    for collaborator in _collaborators {
      //if container is already in a context resolving this type
      //it means that it has been already called to resolve this type,
      //so there is probably a cercular reference between containers.
      //To break it skip this container
      if let context = collaborator.context, context.resolvingType == key.type && context.tag == key.tag { continue }
      
      do {
        //Pass current container's instances pool to collect instances resolved by collaborator
        let resolvedInstances = collaborator.resolvedInstances
        collaborator.resolvedInstances = self.resolvedInstances
        //Set collaborator context to preserve current container context
        let context = collaborator.context
        collaborator.context = self.context
        defer {
          collaborator.context = context
          collaborator.resolvedInstances = resolvedInstances
          
          for (key, resolvedSingleton) in self.resolvedInstances.singletons {
            collaborator.resolvedInstances.singletons[key] = resolvedSingleton
          }
          for (key, resolvedSingleton) in self.resolvedInstances.weakSingletons {
            guard collaborator.definition(matching: key) == nil else { continue }
            collaborator.resolvedInstances.weakSingletons[key] = resolvedSingleton is WeakBoxType ? resolvedSingleton :  WeakBox(resolvedSingleton)
          }
          for (key, resolved) in self.resolvedInstances.resolvedInstances {
            guard collaborator.definition(matching: key) == nil else { continue }
            collaborator.resolvedInstances.resolvedInstances[key] = resolved
          }
        }

        let resolved = try collaborator.inContext(key:key, injectedInType: self.context.injectedInType, injectedInProperty: self.context.injectedInProperty, inCollaboration: true, container: self.context.container, logErrors: false) {
          try collaborator._resolve(key: key, builder: builder)
        }

        return resolved
      }
      catch { }
    }
    return nil
  }

}

// MARK: - Parent Child resolving 

extension DependencyContainer {

  //Attempt to resolve the dependency by searching through the parents registry
  func parentResolve<T>(key aKey: DefinitionKey, builder: (_Definition) throws -> T) -> T? {

    guard let parent = self.parent else {
      return nil
    }

    let resolved = try? parent.inContext(key:aKey,
                                         injectedInType: self.context.injectedInType,
                                         injectedInProperty: self.context.injectedInProperty,
                                         inCollaboration: self.context.inCollaboration,
                                         container: self.context.container,
                                         logErrors: false,
                                         block: { () throws -> T in


          //Merge the parent and the childs resolved instances together before attempting to resolve in the parent
          let parentResolvedInstances = parent.resolvedInstances.resolvedInstances
          var childResolvedInstances = self.context.container.resolvedInstances.resolvedInstances
          parentResolvedInstances.forEach({ (key: DefinitionKey, value: Any) in
            childResolvedInstances[key] = value
          })

          parent.resolvedInstances.resolvedInstances = childResolvedInstances
          defer {
            //Restore parents reolved instances.
            parent.resolvedInstances.resolvedInstances = parentResolvedInstances
          }
          do {
            let resolved = try parent._resolve(key: aKey, builder: builder)

            //Store the resulting resolved instances of this call back into our working context instances.
            parent.resolvedInstances.resolvedInstances.forEach({ (key: DefinitionKey, value: Any) in
                self.context.container.resolvedInstances.resolvedInstances[key] = value
            })

            return resolved
          } catch {
            throw error
          }
      })

      return resolved
    }
}

// MARK: - Removing definitions

extension DependencyContainer {
  
  /**
   Removes definition registered in the container.
   
   - parameters:
      - tag: The tag used to register definition.
      - definition: The definition to remove
   */
  public func remove<T, U>(_ definition: Definition<T, U>, tag: DependencyTagConvertible? = nil) {
    _remove(definition: definition, tag: tag)
  }
  
  func _remove<T, U>(definition aDefinition: Definition<T, U>, tag: DependencyTagConvertible? = nil) {
    let key = DefinitionKey(type: T.self, typeOfArguments: U.self, tag: tag?.dependencyTag)
    _remove(definitionForKey: key)
  }
  
  func _remove(definitionForKey key: DefinitionKey) {
    precondition(!bootstrapped, "You can not modify container's definitions after it was bootstrapped.")
    
    threadSafe {
      definitions[key]?.container = nil
      definitions.remove(key: key)
      resolvedInstances.singletons[key] = nil
      resolvedInstances.weakSingletons[key] = nil
      resolvedInstances.sharedSingletons[key] = nil
      resolvedInstances.sharedWeakSingletons[key] = nil
    }
  }

  /**
   Removes all definitions registered in the container.
   */
  public func reset() {
    threadSafe {
      definitions.all.forEach { $0.1.container = nil }
      definitions.removeAll()
      resolvedInstances.singletons.removeAll()
      resolvedInstances.weakSingletons.removeAll()
      resolvedInstances.sharedSingletons.removeAll()
      resolvedInstances.sharedWeakSingletons.removeAll()
      bootstrapped = false
    }
  }

}

// MARK: - Validation

extension DependencyContainer {
  
  /**
   Validates container configuration trying to resolve each registered definition one by one.
   If definition fails to be resolved without arguments will search provided arguments array
   for arguments matched by type and try to resolve this definition using these arguments.
   If there are no matching arguments will rethrow original error.
   
   - parameter arguments: set of arguments to use to resolve registered definitions.
                          Use a tuple for registered factories that accept several runtime arguments.
   */
  public func validate(_ arguments: Any...) throws {
    try _validate(arguments: arguments)
  }
  
  func _validate(arguments _arguments: [Any]) throws {
    let arguments = _arguments
    validateNextDefinition: for (key, _) in definitions.all {
      do {
        //try to resolve key using provided arguments
        for argumentsSet in arguments {
          guard type(of: argumentsSet) == key.typeOfArguments else { continue }
          do {
            let _ = try inContext(key:key, injectedInType: nil, container: self) {
              try self._resolve(key: key, builder: { definition throws -> Any in
                try definition.weakFactory(argumentsSet)
              })
            }
            continue validateNextDefinition
          }
          catch let error as DipError {
            throw error
          }
            //ignore other errors
          catch { log(level: .Errors, error) }
        }
        
        //try to resolve key using auto-wiring
        do {
          let _ = try self.resolve(key.type, tag: key.tag)
        }
        catch let error as DipError {
          throw error
        }
          //ignore other errors
        catch { log(level: .Errors, error) }
      }
    }
  }
}

extension DependencyContainer: CustomStringConvertible {
  
  public var description: String {
    return "Definitions: \(definitions.all.count)\n" + definitions.all.map({ "\($0.0)" }).joined(separator: "\n")
  }
  
}

//MARK: - DependencyTagConvertible

/// Implement this protocol on your type if you want to use its instances as `DependencyContainer`'s tags.
/// `DependencyContainer.Tag`, `String`, `Int` and any `RawRepresentable` with `RawType` of `String` or `Int` by default confrom to this protocol.
public protocol DependencyTagConvertible {
  var dependencyTag: DependencyContainer.Tag { get }
}

extension DependencyContainer.Tag: DependencyTagConvertible {
  public var dependencyTag: DependencyContainer.Tag {
    return self
  }
}

extension String: DependencyTagConvertible {
  public var dependencyTag: DependencyContainer.Tag {
    return .String(self)
  }
}

extension Int: DependencyTagConvertible {
  public var dependencyTag: DependencyContainer.Tag {
    return .Int(self)
  }
}

extension DependencyTagConvertible where Self: RawRepresentable, Self.RawValue == Int {
  public var dependencyTag: DependencyContainer.Tag {
    return .Int(rawValue)
  }
}

extension DependencyTagConvertible where Self: RawRepresentable, Self.RawValue == String {
  public var dependencyTag: DependencyContainer.Tag {
    return .String(rawValue)
  }
}

extension DependencyContainer.Tag: ExpressibleByStringLiteral {
  
  public init(stringLiteral value: StringLiteralType) {
    self = .String(value)
  }
  
  public init(unicodeScalarLiteral value: StringLiteralType) {
    self.init(stringLiteral: value)
  }
  
  public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
    self.init(stringLiteral: value)
  }
  
}

extension DependencyContainer.Tag: ExpressibleByIntegerLiteral {
  
  public init(integerLiteral value: IntegerLiteralType) {
    self = .Int(value)
  }
  
}

extension DependencyContainer.Tag: Equatable {

  public static func ==(lhs: DependencyContainer.Tag, rhs: DependencyContainer.Tag) -> Bool {
    switch (lhs, rhs) {
    case let (.String(lhsString), .String(rhsString)):
      return lhsString == rhsString
    case let (.Int(lhsInt), .Int(rhsInt)):
      return lhsInt == rhsInt
    default:
      return false
    }
  }

}

final class DefinitionsContainer {
  // Backing data structure. Its a map of
  // [Type.hashValue: [DefinitionKey: _Definition]]
  // so we have fast lookup of by Type for the definitions that handle it.
  private var definitionsByType = [Int: [DefinitionKey: _Definition]]()
  
  typealias DefinitionKeyValuePair = (DefinitionKey, _Definition)
  
  var all: [DefinitionKeyValuePair] {
    return definitionsByType.reduce(into: [DefinitionKeyValuePair]()) { (acc, arg1) in
      let (_, value) = arg1
      acc.append(contentsOf: value.map { ($0, $1)})
    }
  }
  
  func removeAll() {
      definitionsByType.removeAll()
  }
  
  func add<T, U>(key: DefinitionKey, definition: Definition<T, U>) {
    do {
      let typeKey = ObjectIdentifier(T.self).hashValue
      var definitionMap = definitionsByType[typeKey] ?? [:]
      definitionMap[key] = definition
      definitionsByType[typeKey] = definitionMap
    }
    
    // Definitions automatically store T? so so does our table
    do {
      let typeKey = ObjectIdentifier(T?.self).hashValue
      var definitionMap = definitionsByType[typeKey] ?? [:]
      definitionMap[key] = definition
      definitionsByType[typeKey] = definitionMap
    }
  }
  
  // Removes a DefinitionKey, and if the there's no more definitions under that Type, the whole entry is removed.
  func remove(key: DefinitionKey) {
    definitionsByType = definitionsByType.compactMapValues { (definitionMap) -> [DefinitionKey: _Definition]? in
      var definitionMap = definitionMap
      definitionMap.removeValue(forKey: key)
      if definitionMap.isEmpty {
        return nil
      }
      return definitionMap
    }
  }
  
  subscript(_ key: DefinitionKey) -> _Definition? {
    get {
        let typeKey = ObjectIdentifier(key.type).hashValue
        return definitionsByType[typeKey]?[key]
    }
  }
  
  subscript(type type: Any.Type) -> [DefinitionKey: _Definition] {
    get {
        let typeKey = ObjectIdentifier(type).hashValue
        return definitionsByType[typeKey] ?? [:]
    }
  }
}
