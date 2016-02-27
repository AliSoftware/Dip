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

import XCTest
@testable import Dip

private protocol Service {}
private class ServiceImp: Service {}

class DefinitionTests: XCTestCase {

  private typealias F1 = () -> Service
  private typealias F2 = (String) -> Service
  
  let tag1 = DependencyContainer.Tag.String("tag1")
  let tag2 = DependencyContainer.Tag.String("tag2")
  
  #if os(Linux)
  var allTests: [(String, () throws -> Void)] {
    return [
      ("testThatDefinitionKeyIsEqualBy_Type_Factory_Tag", testThatDefinitionKeyIsEqualBy_Type_Factory_Tag),
      ("testThatDefinitionKeysWithDifferentTypesAreNotEqual", testThatDefinitionKeysWithDifferentTypesAreNotEqual),
      ("testThatDefinitionKeysWithDifferentFactoriesAreNotEqual", testThatDefinitionKeysWithDifferentFactoriesAreNotEqual),
      ("testThatDefinitionKeysWithDifferentTagsAreNotEqual", testThatDefinitionKeysWithDifferentTagsAreNotEqual),
      ("testThatResolveDependenciesCallsResolveDependenciesBlock", testThatResolveDependenciesCallsResolveDependenciesBlock),
      ("testThatResolveDependenciesBlockIsNotCalledWhenPassedWrongInstance", testThatResolveDependenciesBlockIsNotCalledWhenPassedWrongInstance)
    ]
  }
  #endif

  func testThatDefinitionKeyIsEqualBy_Type_Factory_Tag() {
    let equalKey1 = DefinitionKey(protocolType: Service.self, factoryType: F1.self, associatedTag: tag1)
    let equalKey2 = DefinitionKey(protocolType: Service.self, factoryType: F1.self, associatedTag: tag1)
    
    XCTAssertEqual(equalKey1, equalKey2)
    XCTAssertEqual(equalKey1.hashValue, equalKey2.hashValue)
  }
  
  func testThatDefinitionKeysWithDifferentTypesAreNotEqual() {
    let keyWithDifferentType1 = DefinitionKey(protocolType: Service.self, factoryType: F1.self, associatedTag: nil)
    let keyWithDifferentType2 = DefinitionKey(protocolType: AnyObject.self, factoryType: F1.self, associatedTag: nil)
    
    XCTAssertNotEqual(keyWithDifferentType1, keyWithDifferentType2)
    XCTAssertNotEqual(keyWithDifferentType1.hashValue, keyWithDifferentType2.hashValue)
  }
  
  func testThatDefinitionKeysWithDifferentFactoriesAreNotEqual() {
    let keyWithDifferentFactory1 = DefinitionKey(protocolType: Service.self, factoryType: F1.self, associatedTag: nil)
    let keyWithDifferentFactory2 = DefinitionKey(protocolType: Service.self, factoryType: F2.self, associatedTag: nil)
    
    XCTAssertNotEqual(keyWithDifferentFactory1, keyWithDifferentFactory2)
    XCTAssertNotEqual(keyWithDifferentFactory1.hashValue, keyWithDifferentFactory2.hashValue)
  }
  
  func testThatDefinitionKeysWithDifferentTagsAreNotEqual() {
    let keyWithDifferentTag1 = DefinitionKey(protocolType: Service.self, factoryType: F1.self, associatedTag: tag1)
    let keyWithDifferentTag2 = DefinitionKey(protocolType: Service.self, factoryType: F1.self, associatedTag: tag2)
    
    XCTAssertNotEqual(keyWithDifferentTag1, keyWithDifferentTag2)
    XCTAssertNotEqual(keyWithDifferentTag1.hashValue, keyWithDifferentTag2.hashValue)
  }

  func testThatResolveDependenciesCallsResolveDependenciesBlock() {
    var blockCalled = false
    
    //given
    let def = DefinitionOf<Service, () -> Service>(scope: .Prototype) { ServiceImp() as Service }.resolveDependencies { container, service in
      blockCalled = true
    }
    
    //when
    try! def.resolveDependenciesOf(ServiceImp(), withContainer: DependencyContainer())
    
    //then
    XCTAssertTrue(blockCalled)
  }
  
  func testThatResolveDependenciesBlockIsNotCalledWhenPassedWrongInstance() {
    var blockCalled = false
    
    //given
    let def = DefinitionOf<Service, () -> Service>(scope: .Prototype) { ServiceImp() as Service }.resolveDependencies { container, service in
      blockCalled = true
    }
    
    //when
    try! def.resolveDependenciesOf(String(), withContainer: DependencyContainer())
    
    //then
    XCTAssertFalse(blockCalled)
  }
}

