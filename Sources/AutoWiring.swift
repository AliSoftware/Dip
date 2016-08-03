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

protocol AutoWiringDefinition: Definition {
  var numberOfArguments: Int? { get }
  var autoWiringFactory: ((DependencyContainer, DependencyContainer.Tag?) throws -> Any)? { get }
}

extension AutoWiringDefinition {
  func supportsAutoWiring() -> Bool {
    return autoWiringFactory != nil && numberOfArguments > 0
  }
}

extension DependencyContainer {
  
  /// Tries to resolve instance using auto-wire factories
  func autowire<T>(_ key: DefinitionKey) throws -> T {
    let shouldLogErrors = context.logErrors
    defer { context.logErrors = shouldLogErrors }
    context.logErrors = false
    
    guard key.argumentsType == Void.self else {
      throw DipError.DefinitionNotFound(key: key)
    }
    
    let tag = key.associatedTag
    let type = key.protocolType
    let resolved: Any?
    do {
      let definitions = autoWiringDefinitions(type, tag: tag)
      resolved = try resolve(enumerating: definitions) { try resolveKey($0, tag: tag, type: type) }
    }
    catch {
      throw DipError.AutoWiringFailed(type: type, underlyingError: error)
    }
    
    if let resolved = resolved as? T  {
      return resolved
    }
    else {
      throw DipError.DefinitionNotFound(key: key)
    }
  }

  private func autoWiringDefinitions(_ type: Any.Type, tag: DependencyContainer.Tag?) -> [KeyDefinitionPair] {
    var definitions = self.definitions.map({ (key: $0.0, definition: $0.1) })
    
    //filter definitions
    definitions = definitions
      .filter({ $0.definition.supportsAutoWiring() })
      .sorted(by: { $0.definition.numberOfArguments > $1.definition.numberOfArguments })
    
    definitions = filter(definitions, type: type, tag: tag)
    definitions = order(definitions, tag: tag)

    return definitions
  }
  
  /// Enumerates definitions one by one until one of them succeeds, otherwise returns nil
  private func resolve(enumerating keyDefinitionPairs: [KeyDefinitionPair], block: @noescape (DefinitionKey) throws -> Any?) throws -> Any? {
    for (index, keyDefinitionPair) in keyDefinitionPairs.enumerated() {
      //If the next definition matches current definition then they are ambigous
      if let nextPair = keyDefinitionPairs[next: index], case keyDefinitionPair = nextPair {
          throw DipError.AmbiguousDefinitions(
            type: keyDefinitionPair.key.protocolType,
            definitions: [keyDefinitionPair.definition, nextPair.definition]
        )
      }
      
      if let resolved = try block(keyDefinitionPair.key) {
        return resolved
      }
    }
    return nil
  }
  
  private func resolveKey(_ key: DefinitionKey, tag: DependencyContainer.Tag?, type: Any.Type) throws -> Any {
    let key = key.tagged(tag ?? context.tag)
    let resolved: Any = try resolveKey(key, builder: { definition in
      try definition.autoWiringFactory!(self, tag)
    })
    return resolved
  }
  
}

typealias KeyDefinitionPair = (key: DefinitionKey, definition: _Definition)

/// Definitions are matched if they are registered for the same tag and thier factories accept the same number of runtime arguments.
private func ~=(lhs: KeyDefinitionPair, rhs: KeyDefinitionPair) -> Bool {
  guard lhs.key.protocolType == rhs.key.protocolType else { return false }
  guard lhs.key.associatedTag == rhs.key.associatedTag else { return false }
  guard lhs.definition.numberOfArguments == rhs.definition.numberOfArguments else { return false }
  return true
}

func filter(_ definitions: [KeyDefinitionPair], type: Any.Type, tag: DependencyContainer.Tag?, argumentsType: Any.Type? = nil) -> [KeyDefinitionPair] {
  let definitions =  definitions
    .filter({ $0.key.protocolType == type || $0.definition.doesImplements(type) })
    .filter({ $0.key.associatedTag == tag || $0.key.associatedTag == nil })
  
  if let argumentsType = argumentsType {
    return definitions.filter({ $0.key.argumentsType == argumentsType })
  }
  return definitions
}

func order(_ definitions: [KeyDefinitionPair], tag: DependencyContainer.Tag?) -> [KeyDefinitionPair] {
  return
    //first will try to use tagged definitions
    definitions.filter({ $0.key.associatedTag == tag }) +
    //then will use not tagged definitions
    definitions.filter({ $0.key.associatedTag != tag })
}
