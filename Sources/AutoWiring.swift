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
    return autoWiringFactory != nil && numberOfArguments != nil && numberOfArguments! > 0
  }
}

extension DependencyContainer {
  
  /// Tries to resolve instance using auto-wire factories
  func autowire<T>(_ key: DefinitionKey) throws -> T {
    let shouldLogErrors = context.logErrors
    defer { context.logErrors = shouldLogErrors }
    context.logErrors = false
    
    guard key.typeOfArguments == Void.self else {
      throw DipError.DefinitionNotFound(key: key)
    }
    
    let tag = key.tag
    let type = key.type
    let resolved: Any?
    do {
      let definitions = autoWiringDefinitions(byKey: key)
      resolved = try resolve(enumerating: definitions, tag: tag)
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

  private func autoWiringDefinitions(byKey key: DefinitionKey) -> [KeyDefinitionPair] {
    var definitions = self.definitions.map({ (key: $0.0, definition: $0.1) })
    
    //filter definitions
    definitions = definitions.filter({ $0.definition.supportsAutoWiring() })
    definitions = definitions.sorted(by: { $0.definition.numberOfArguments! > $1.definition.numberOfArguments! })
    
    definitions = filter(definitions, byKey: key)
    definitions = order(definitions, byTag: key.tag)

    return definitions
  }
  
  /// Enumerates definitions one by one until one of them succeeds, otherwise returns nil
  private func resolve(enumerating autoWiringDefinitions: [KeyDefinitionPair], tag: DependencyContainer.Tag?) throws -> Any? {
    for (index, autoWiringDefinition) in autoWiringDefinitions.enumerated() {
      //If the next definition matches current definition then they are ambigous
      if let nextPair = autoWiringDefinitions[next: index], case autoWiringDefinition = nextPair {
          throw DipError.AmbiguousDefinitions(
            type: autoWiringDefinition.key.type,
            definitions: [autoWiringDefinition.definition, nextPair.definition]
        )
      }
      
      let key = autoWiringDefinition.key.tagged(tag ?? context.tag)
      let resolved: Any? = try? resolveKey(key) { definition in
        try definition.autoWiringFactory!(self, tag)
      }
      if let resolved = resolved {
        return resolved
      }
    }
    return nil
  }
  
}

typealias KeyDefinitionPair = (key: DefinitionKey, definition: _Definition)

/// Definitions are matched if they are registered for the same tag and thier factories accept the same number of runtime arguments.
private func ~=(lhs: KeyDefinitionPair, rhs: KeyDefinitionPair) -> Bool {
  guard lhs.key.type == rhs.key.type else { return false }
  guard lhs.key.tag == rhs.key.tag else { return false }
  guard lhs.definition.numberOfArguments == rhs.definition.numberOfArguments else { return false }
  return true
}

func filter(_ definitions: [KeyDefinitionPair], byKey key: DefinitionKey) -> [KeyDefinitionPair] {
  return definitions
    .filter({ $0.key.type == key.type || $0.definition.doesImplements(key.type) })
    .filter({ $0.key.tag == key.tag || $0.key.tag == nil })
}

func filter(_ definitions: [KeyDefinitionPair], byKeyAndTypeOfArguments key: DefinitionKey) -> [KeyDefinitionPair] {
  return filter(definitions, byKey: key)
    .filter({ $0.key.typeOfArguments == key.typeOfArguments })
}

func order(_ definitions: [KeyDefinitionPair], byTag tag: DependencyContainer.Tag?) -> [KeyDefinitionPair] {
  return
    //first will try to use tagged definitions
    definitions.filter({ $0.key.tag == tag }) +
    //then will use not tagged definitions
    definitions.filter({ $0.key.tag != tag })
}
