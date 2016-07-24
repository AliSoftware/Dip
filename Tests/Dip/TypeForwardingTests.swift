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

private protocol Service: class { }
private protocol ForwardedType: class { }
private class ServiceImp1: NSObject, Service, ForwardedType { }
private class ServiceImp2: NSObject, Service, ForwardedType { }

class TypeForwardingTests: XCTestCase {
  
  let container = DependencyContainer()

  #if os(Linux)
  static var allTests: [(String, TypeForwardingTests -> () throws -> Void)] {
    return [
      ("testThatItResolvesInstanceByTypeForwarding", testThatItResolvesInstanceByTypeForwarding),
      ("testThatItReusesInstanceResolvedByTypeForwarding", testThatItReusesInstanceResolvedByTypeForwarding),
      ("testThatItDoesNotResolveByTypeForwardingIfRegisteredForAnotherTag", testThatItDoesNotResolveByTypeForwardingIfRegisteredForAnotherTag),
      ("testThatItDoesNotReuseInstanceResolvedByTypeForwardingRegisteredForAnotherTag",  testThatItDoesNotReuseInstanceResolvedByTypeForwardingRegisteredForAnotherTag),
      ("testThatItCallsResolvedDependenciesBlockWhenResolvingByTypeForwarding", testThatItCallsResolvedDependenciesBlockWhenResolvingByTypeForwarding),
      ("testThatItFallbackToDefinitionWithNoTagWhenResolvingInstanceByTypeForwarding", testThatItFallbackToDefinitionWithNoTagWhenResolvingInstanceByTypeForwarding),
      ("testThatItThrowsErrorWhenResolvingNotImplementedTypeWithTypeForwarding", testThatItThrowsErrorWhenResolvingNotImplementedTypeWithTypeForwarding),
      ("testThatItOverridesIfSeveralDefinitionsWithTheSameTagForwardTheSameType", testThatItOverridesIfSeveralDefinitionsWithTheSameTagForwardTheSameType)
    ]
  }
  
  func setUp() {
    container.reset()
  }
  #else
  override func setUp() {
    container.reset()
  }
  #endif

  func testThatItResolvesInstanceByTypeForwarding() {
    //given
    let def = container.register { ServiceImp1() as Service }
    container.register(def, type: ForwardedType.self)
    container.register(def, type: NSObject.self)
    
    //when
    let anotherService = try! container.resolve() as ForwardedType
    let anyOtherService = try! container.resolve(ForwardedType.self)
    let object = try! container.resolve() as NSObject
    let anyObject = try! container.resolve(NSObject.self)
    
    //then
    XCTAssertTrue(anotherService is ServiceImp1)
    XCTAssertTrue(object is ServiceImp1)
    XCTAssertTrue(anyOtherService is ServiceImp1)
    XCTAssertTrue(anyObject is ServiceImp1)
  }
  
  func testThatItReusesInstanceResolvedByTypeForwarding() {
    //given
    let def = container.register(.ObjectGraph) { ServiceImp1() as Service }
      .resolveDependencies { container, service in
        //when
        let forwardType = try container.resolve() as ForwardedType
        let anyForwardType = try container.resolve(ForwardedType.self) as! ForwardedType
        let object = try container.resolve() as NSObject
        let anyObject = try container.resolve(NSObject.self) as! NSObject
        
        //then
        XCTAssertTrue(forwardType === service as! ForwardedType)
        XCTAssertTrue(anyForwardType === service as! ForwardedType)
        XCTAssertTrue(object === service as! NSObject)
        XCTAssertTrue(anyObject === service as! NSObject)
    }
    container.register(def, type: ForwardedType.self)
    container.register(def, type: NSObject.self)
    
    let _ = try! container.resolve() as Service
  }
  
  func testThatItDoesNotResolveByTypeForwardingIfRegisteredForAnotherTag() {
    //given
    let def = container.register(tag: "tag") { ServiceImp1() as Service }
    container.register(def, type: ForwardedType.self, tag: "otherTag")
    
    //then
    AssertThrows(expression: try container.resolve(tag: "tag") as ForwardedType)
    AssertThrows(expression: try container.resolve(ForwardedType.self, tag: "tag"))
    
    //and given
    container.register(def, type: ForwardedType.self, tag: "tag")
    
    //then
    AssertNoThrow(expression: try container.resolve(tag: "tag") as ForwardedType)
    AssertNoThrow(expression: try container.resolve(ForwardedType.self, tag: "tag"))
  }
  
  func testThatItDoesNotReuseInstanceResolvedByTypeForwardingRegisteredForAnotherTag() {
    var resolveDependenciesCalled = false
    //given
    let def = container.register(.ObjectGraph) { ServiceImp1() as Service }
      .resolveDependencies { container, service in
        guard resolveDependenciesCalled == false else { return }
        resolveDependenciesCalled = true

        let forwardType = try container.resolve(tag: "tag") as ForwardedType
        let anyForwardType = try container.resolve(ForwardedType.self, tag: "tag") as! ForwardedType

        let object = try container.resolve() as NSObject
        let anyObject = try container.resolve(NSObject.self) as! NSObject
        
        //then
        XCTAssertFalse(forwardType === service as! ForwardedType)
        XCTAssertFalse(anyForwardType === service as! ForwardedType)
        XCTAssertTrue(object === service as! NSObject)
        XCTAssertTrue(anyObject === service as! NSObject)
    }
    container.register(def, type: ForwardedType.self, tag: "tag")
    container.register(def, type: NSObject.self)
    
    //when
    let _ = try! container.resolve() as Service
  }
  
  func testThatItCallsResolvedDependenciesBlockWhenResolvingByTypeForwarding() {
    //given
    var resolveDependenciesCalled = false
    let def = container.register { ServiceImp1() as Service }
      .resolveDependencies { container, service in
        resolveDependenciesCalled = true
    }
    
    container.register(def, type: NSObject.self)
    
    //when
    let _ = try! container.resolve() as NSObject
    
    //then
    XCTAssertTrue(resolveDependenciesCalled)

    //and when
    resolveDependenciesCalled = false
    let _ = try! container.resolve(NSObject.self)
    
    //then
    XCTAssertTrue(resolveDependenciesCalled)
    
  }
  
  func testThatItFallbackToDefinitionWithNoTagWhenResolvingInstanceByTypeForwarding() {
    let def = container.register { ServiceImp1() as Service }
    container.register { ServiceImp2() as Service }
    container.register(def, type: NSObject.self)
    
    //when
    let service = try! container.resolve(tag: "tag") as NSObject
    let anyService = try! container.resolve(NSObject.self, tag: "tag")
    
    //then
    XCTAssertTrue(service is ServiceImp1)
    XCTAssertTrue(anyService is ServiceImp1)
  }
  
  func testThatItThrowsErrorWhenResolvingNotImplementedTypeWithTypeForwarding() {
    //given
    let def = container.register { ServiceImp1() as Service }
    container.register(def, type: NSCoder.self)
    
    //then
    AssertThrows(expression: try container.resolve() as NSCoder)
    AssertThrows(expression: try container.resolve(NSCoder.self))
  }
  
  func testThatItOverridesIfSeveralDefinitionsWithTheSameTagForwardTheSameType() {
    let def1 = container.register { ServiceImp1() as Service }
    let def2 = container.register { ServiceImp2() as Service }
    container.register(def1, type: NSObject.self)

    XCTAssertTrue(try! container.resolve() as NSObject is ServiceImp1)
    XCTAssertTrue(try! container.resolve(NSObject.self) is ServiceImp1)

    //when
    container.register(def2, type: NSObject.self)
    
    //then
    XCTAssertTrue(try! container.resolve() as NSObject is ServiceImp2)
    XCTAssertTrue(try! container.resolve(NSObject.self) is ServiceImp2)
    
    //and given
    container.register(def2, type: NSObject.self, tag: "tag")

    XCTAssertTrue(try! container.resolve(tag: "tag") as NSObject is ServiceImp2)
    XCTAssertTrue(try! container.resolve(NSObject.self, tag: "tag") is ServiceImp2)

    //when
    container.register(def1, type: NSObject.self, tag: "tag")
    
    //then
    XCTAssertTrue(try! container.resolve(tag: "tag") as NSObject is ServiceImp1)
    XCTAssertTrue(try! container.resolve(NSObject.self, tag: "tag") is ServiceImp1)
  }
  
}
