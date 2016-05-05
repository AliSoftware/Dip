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

extension DependencyContainer {
  
  /// Tries to resolve instance using auto-wire factories
  func _resolveByAutoWiring<T>(key: DefinitionKey) throws -> T {
    guard key.argumentsType == Void.self else {
      throw DipError.DefinitionNotFound(key: key)
    }
    
    let tag = key.associatedTag
    let type = key.protocolType
    let autoWiringDefinitions = self.autoWiringDefinitionsFor(type: type, tag: tag)
    let resolved: Any?
    do {
      resolved = try _resolveEnumeratingKeys(definitions: autoWiringDefinitions) { try _resolveKey(key: $0, tag: tag, type: type) }
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

  private func autoWiringDefinitionsFor(type: Any.Type, tag: DependencyContainer.Tag?) -> [(DefinitionKey, _Definition)] {
    var definitions = self.definitions.map({ ($0.0, $0.1) })
    
    //filter definitions
    definitions = definitions.filter({ $0.1.supportsAutoWiring() })
      .filter({ $0.0.protocolType == type || $0.1.implementingTypes.contains({ $0 == type }) })
      .filter({ $0.0.associatedTag == tag || $0.0.associatedTag == nil })
    
    //order definitions
    definitions = definitions
      .sorted(isOrderedBefore: { $0.1.numberOfArguments > $1.1.numberOfArguments })

    definitions =
      //first will try to use tagged definitions
      definitions.filter({ $0.0.associatedTag == tag }) +
      //then will use not tagged definitions
      definitions.filter({ $0.0.associatedTag != tag })

    return definitions
  }
  
  /// Tries definitions one by one until one of them succeeds, otherwise returns nil
  private func _resolveEnumeratingKeys(definitions: [(DefinitionKey, _Definition)], block: @noescape(DefinitionKey) throws -> Any?) throws -> Any? {
    for (index, definition) in definitions.enumerated() {
      //If the next definition matches current definition then they are ambigous
      if case definition? = definitions[next: index] {
          throw DipError.AmbiguousDefinitions(
            type: definition.0.protocolType,
            definitions: [definition.1, definitions[next: index]!.1]
        )
      }
      
      if let resolved = try block(definition.0) {
        return resolved
      }
    }
    return nil
  }
  
  private func _resolveKey(key: DefinitionKey, tag: DependencyContainer.Tag?, type: Any.Type) throws -> Any {
    let key = DefinitionKey(protocolType: key.protocolType, argumentsType: key.argumentsType, associatedTag: tag ?? context.tag)
    
    return try _resolveKey(key: key, builder: { definition in
      try definition.autoWiringFactory!(self, tag)
    })
  }
  
}

/// Definitions are matched if they are registered for the same tag and thier factories accept the same number of runtime arguments.
private func ~=(lhs: (DefinitionKey, _Definition), rhs: (DefinitionKey, _Definition)) -> Bool {
  return
    lhs.0.protocolType == rhs.0.protocolType &&
      lhs.0.associatedTag == rhs.0.associatedTag &&
      lhs.1.numberOfArguments == rhs.1.numberOfArguments
}
