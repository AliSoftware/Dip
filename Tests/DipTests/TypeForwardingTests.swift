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

  static var allTests = {
    return [
      ("testThatItResolvesInstanceByTypeForwarding", testThatItResolvesInstanceByTypeForwarding),
      ("testThatItReusesInstanceResolvedByTypeForwarding", testThatItReusesInstanceResolvedByTypeForwarding),
      ("testThatItDoesNotResolveByTypeForwardingIfRegisteredForAnotherTag", testThatItDoesNotResolveByTypeForwardingIfRegisteredForAnotherTag),
      ("testThatItDoesNotReuseInstanceResolvedByTypeForwardingRegisteredForAnotherTag",  testThatItDoesNotReuseInstanceResolvedByTypeForwardingRegisteredForAnotherTag),
      ("testThatItCallsResolvedDependenciesBlockWhenResolvingByTypeForwarding", testThatItCallsResolvedDependenciesBlockWhenResolvingByTypeForwarding),
      ("testThatItCallsResolvedDependenciesBlockProvidedAfterRegistrationWhenResolvingByTypeForwarding",testThatItCallsResolvedDependenciesBlockProvidedAfterRegistrationWhenResolvingByTypeForwarding),
      ("testThatItFallbackToDefinitionWithNoTagWhenResolvingInstanceByTypeForwarding", testThatItFallbackToDefinitionWithNoTagWhenResolvingInstanceByTypeForwarding),
      ("testThatItCanResolveOptional", testThatItCanResolveOptional),
      ("testThatItFirstUsesTaggedDefinitionWhenResolvingOptional", testThatItFirstUsesTaggedDefinitionWhenResolvingOptional),
      ("testThatItThrowsErrorWhenResolvingNotImplementedTypeWithTypeForwarding", testThatItThrowsErrorWhenResolvingNotImplementedTypeWithTypeForwarding),
      ("testThatItOverridesIfSeveralDefinitionsWithTheSameTagForwardTheSameType", testThatItOverridesIfSeveralDefinitionsWithTheSameTagForwardTheSameType),
      ("testThatItDoesNotOverrideIfDefinitionForwardsTheSameTypeWithDifferentTag", testThatItDoesNotOverrideIfDefinitionForwardsTheSameTypeWithDifferentTag)
    ]
  }()
  
  override func setUp() {
    container.reset()
  }
  
  func testThatItResolvesInstanceByTypeForwarding() {
    //given
    container.register { ServiceImp1() as Service }
      .implements(ForwardedType.self)
      .implements(NSObject.self)
    
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
    container.register() { ServiceImp1() as Service }
      .resolvingProperties { container, resolved in
        //when
        //resolving forwarded type
        let forwardType = try container.resolve() as ForwardedType
        let anyForwardType = try container.resolve(ForwardedType.self) as! ForwardedType
        let object = try container.resolve() as NSObject
        let anyObject = try container.resolve(NSObject.self) as! NSObject
        let service = try container.resolve() as Service
        let anyService = try container.resolve(Service.self) as! Service

        //then
        XCTAssertTrue(forwardType === resolved as! ForwardedType)
        XCTAssertTrue(anyForwardType === resolved as! ForwardedType)
        XCTAssertTrue(object === resolved as! NSObject)
        XCTAssertTrue(anyObject === resolved as! NSObject)
        XCTAssertTrue(service === resolved)
        XCTAssertTrue(anyService === resolved)
      }
      .implements(ForwardedType.self)
      .implements(NSObject.self)
    
    let _ = try! container.resolve() as Service
    let _ = try! container.resolve() as ForwardedType
//    let _ = try! container.resolve() as NSObject
  }
  
  func testThatItDoesNotResolveByTypeForwardingIfRegisteredForAnotherTag() {
    //given
    let def = container.register(tag: "tag") { ServiceImp1() as Service }
    def.implements(ForwardedType.self, tag: "otherTag")
    
    //then
    AssertThrows(expression: try container.resolve(tag: "tag") as ForwardedType)
    AssertThrows(expression: try container.resolve(ForwardedType.self, tag: "tag"))
    
    //and given
    def.implements(ForwardedType.self, tag: "tag")
    
    //then
    AssertNoThrow(expression: try container.resolve(tag: "tag") as ForwardedType)
    AssertNoThrow(expression: try container.resolve(ForwardedType.self, tag: "tag"))
  }
  
  func testThatItDoesNotReuseInstanceResolvedByTypeForwardingRegisteredForAnotherTag() {
    var resolveDependenciesCalled = false
    //given
    container.register() { ServiceImp1() as Service }
      .resolvingProperties { container, service in
        guard resolveDependenciesCalled == false else { return }
        resolveDependenciesCalled = true

        //when
        //resolving via type-forawrding for tag different then tag for original definition
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
      .implements(ForwardedType.self, tag: "tag")
      .implements(NSObject.self)
    
    //when
    let _ = try! container.resolve() as Service
  }
  
  func testThatItCallsResolvedDependenciesBlockWhenResolvingByTypeForwarding() {
    //given
    var originalResolvingPropertiesCalled = false
    var resolvingPropertiesCalled = false
    container.register { ServiceImp1() }
      .resolvingProperties { _ in
        originalResolvingPropertiesCalled = true
      }.implements(Service.self) { _ in
        resolvingPropertiesCalled = true
      }
    
    //when
    let _ = try! container.resolve() as Service
    
    //then
    XCTAssertTrue(resolvingPropertiesCalled)
    XCTAssertTrue(originalResolvingPropertiesCalled)

    //and when
    resolvingPropertiesCalled = false
    originalResolvingPropertiesCalled = false
    let _ = try! container.resolve(Service.self)
    
    //then
    XCTAssertTrue(resolvingPropertiesCalled)
    XCTAssertTrue(originalResolvingPropertiesCalled)
  }
  
  func testThatItCallsResolvedDependenciesBlockProvidedAfterRegistrationWhenResolvingByTypeForwarding() {
    //given
    //resolvingProperties provided after registering definition
    var originalResolvingPropertiesCalled = false
    var resolvingPropertiesCalled = false
    container.reset()
    let definition = container.register { ServiceImp1() }
      .implements(Service.self) { container, object in
        resolvingPropertiesCalled = true
    }
    
    definition.resolvingProperties { _ in
      originalResolvingPropertiesCalled = true
    }
    
    //when
    let _ = try! container.resolve() as Service
    
    //then
    XCTAssertTrue(resolvingPropertiesCalled)
    XCTAssertTrue(originalResolvingPropertiesCalled)

    //and when
    resolvingPropertiesCalled = false
    originalResolvingPropertiesCalled = false
    let _ = try! container.resolve(Service.self)
    
    //then
    XCTAssertTrue(resolvingPropertiesCalled)
    XCTAssertTrue(originalResolvingPropertiesCalled)
  }
  
  func testThatItFallbackToDefinitionWithNoTagWhenResolvingInstanceByTypeForwarding() {
    //given
    container.register { ServiceImp1() as Service }
      .implements(ForwardedType.self)
    
    //when
    let service = try! container.resolve(tag: "tag") as ForwardedType
    let anyService = try! container.resolve(ForwardedType.self, tag: "tag")
    
    //then
    XCTAssertTrue(service is ServiceImp1)
    XCTAssertTrue(anyService is ServiceImp1)
  }
  
  func testThatItCanResolveOptional() {
    container.register { ServiceImp1() as Service }
      .implements(ForwardedType.self)
      .implements(NSObject.self)
    
    //when
    let service = try! container.resolve() as Service?
    let anyService = try! container.resolve((Service?).self)
    
    //then
    XCTAssertTrue(service is ServiceImp1)
    XCTAssertTrue(anyService is ServiceImp1)

    //when
    let forwardedType = try! container.resolve() as ForwardedType?
    let anyForwardedType = try! container.resolve((ForwardedType?).self)
    
    //then
    XCTAssertTrue(forwardedType is ServiceImp1)
    XCTAssertTrue(anyForwardedType is ServiceImp1)
  
    //when
    let object = try! container.resolve() as NSObject?
    let anyObject = try! container.resolve((NSObject?).self)
    
    //then
    XCTAssertTrue(object is ServiceImp1)
    XCTAssertTrue(anyObject is ServiceImp1)
  }
  
  func testThatItFirstUsesTaggedDefinitionWhenResolvingOptional() {
    let expectedTag: DependencyContainer.Tag = .String("tag")
    container.register(tag: expectedTag) { ServiceImp1() as Service }
      .resolvingProperties { container, resolved in
        XCTAssertEqual(container.context.tag, expectedTag)
    }
    container.register { ServiceImp2() as Service }
    
    //when
    let service = try! container.resolve(tag: "tag") as Service?
    let anyService = try! container.resolve((Service?).self, tag: "tag")
    
    //then
    XCTAssertTrue(service is ServiceImp1)
    XCTAssertTrue(anyService is ServiceImp1)
  }
  
  func testThatItThrowsErrorWhenResolvingNotImplementedTypeWithTypeForwarding() {
    //given
    container.register { ServiceImp1() as Service }
      .implements(ServiceImp2.self)
    
    //then
    AssertThrows(expression: try container.resolve() as ServiceImp2) { error in
      guard case let DipError.invalidType(_, key) = error else { return false }
      
      let expectedKey = DefinitionKey(type: ServiceImp2.self, typeOfArguments: Void.self, tag: nil)
      XCTAssertEqual(key, expectedKey)
      return true
    }
    AssertThrows(expression: try container.resolve(ServiceImp2.self)) { error in
      guard case let DipError.invalidType(_, key) = error else { return false }
      
      let expectedKey = DefinitionKey(type: ServiceImp2.self, typeOfArguments: Void.self, tag: nil)
      XCTAssertEqual(key, expectedKey)
      return true
    }
  }
  
  func testThatItOverridesIfSeveralDefinitionsWithTheSameTagForwardTheSameType() {
    let def1 = container.register { ServiceImp1() }
    let def2 = container.register { ServiceImp2() }
    
    //when
    def1.implements(ForwardedType.self)

    //then
    XCTAssertTrue(try! container.resolve() as ForwardedType is ServiceImp1)
    XCTAssertTrue(try! container.resolve(ForwardedType.self) is ServiceImp1)

    //when
    //another definition implements the same type
    def2.implements(ForwardedType.self)
    
    //then
    XCTAssertTrue(try! container.resolve() as ForwardedType is ServiceImp2)
    XCTAssertTrue(try! container.resolve(ForwardedType.self) is ServiceImp2)
    
    //when
    def1.implements(ForwardedType.self, tag: "tag")

    //then
    XCTAssertTrue(try! container.resolve(tag: "tag") as ForwardedType is ServiceImp1)
    XCTAssertTrue(try! container.resolve(ForwardedType.self, tag: "tag") is ServiceImp1)

    //when
    //another definition implements the same type for the same tag
    def2.implements(ForwardedType.self, tag: "tag")
    
    //then
    XCTAssertTrue(try! container.resolve(tag: "tag") as ForwardedType is ServiceImp2)
    XCTAssertTrue(try! container.resolve(ForwardedType.self, tag: "tag") is ServiceImp2)
    
  }
  
  func testThatItDoesNotOverrideIfDefinitionForwardsTheSameTypeWithDifferentTag() {
    let def1 = container.register { ServiceImp1() }
    let def2 = container.register { ServiceImp2() }

    //when
    def1.implements(ForwardedType.self, tag: "tag")
    //another definition implements the same type for a different tag
    def2.implements(ForwardedType.self, tag: "anotherTag")
    
    //then
    XCTAssertTrue(try! container.resolve(tag: "tag") as ForwardedType is ServiceImp1)
    XCTAssertTrue(try! container.resolve(ForwardedType.self, tag: "tag") is ServiceImp1)
  }
  
}
