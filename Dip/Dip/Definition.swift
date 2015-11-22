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

import Foundation

///Internal representation of a key used to associate definitons and factories by tag, type and factory.
struct DefinitionKey : Hashable, Equatable, CustomDebugStringConvertible {
  var protocolType: Any.Type
  var factoryType: Any.Type
  var associatedTag: DependencyContainer.Tag?
  
  var hashValue: Int {
    return "\(protocolType)-\(factoryType)-\(associatedTag)".hashValue
  }
  
  var debugDescription: String {
    return "type: \(protocolType), factory: \(factoryType), tag: \(associatedTag)"
  }
}

func ==(lhs: DefinitionKey, rhs: DefinitionKey) -> Bool {
  return
    lhs.protocolType == rhs.protocolType &&
      lhs.factoryType == rhs.factoryType &&
      lhs.associatedTag == rhs.associatedTag
}

///Describes the lifecycle of instances created by container.
public enum ComponentScope {
  /// Indicates that a new instance of the component will be created each time it's resolved.
  case Prototype
  /// Indicates that resolved component should be retained by container and always reused.
  case Singleton
}

///Definition of type T describes how instances of this type should be created when they are resolved by container.
public final class DefinitionOf<T>: Definition {
  let factory: Any
  let scope: ComponentScope
  
  init(factory: Any, scope: ComponentScope = .Prototype) {
    self.factory = factory
    self.scope = scope
  }
  
  var resolvedInstance: T? {
    get {
      guard scope == .Singleton else { return nil }
      return _resolvedInstance
    }
    set {
      guard scope == .Singleton else { return }
      _resolvedInstance = newValue
    }
  }
  
  private var _resolvedInstance: T?
}

///Dummy protocol to store definitions for different types in collection
protocol Definition {}
