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
private class ServiceImp1: Service { }
private class ServiceImp2: Service { }

class DipTests: XCTestCase {

  let container = DependencyContainer()

  #if os(Linux)
  var allTests: [(String, () throws -> Void)] {
    return [
      ("testThatItResolvesInstanceRegisteredWithoutTag", testThatItResolvesInstanceRegisteredWithoutTag),
      ("testThatItResolvesInstanceRegisteredWithTag", testThatItResolvesInstanceRegisteredWithTag),
      ("testThatItResolvesDifferentInstancesRegisteredForDifferentTags", testThatItResolvesDifferentInstancesRegisteredForDifferentTags),
      ("testThatNewRegistrationOverridesPreviousRegistration", testThatNewRegistrationOverridesPreviousRegistration),
      ("testThatItCallsResolveDependenciesOnDefinition", testThatItCallsResolveDependenciesOnDefinition),
      ("testThatItThrowsErrorIfCanNotFindDefinitionForType", testThatItThrowsErrorIfCanNotFindDefinitionForType),
      ("testThatItThrowsErrorIfCanNotFindDefinitionForTag", testThatItThrowsErrorIfCanNotFindDefinitionForTag),
      ("testThatItThrowsErrorIfCanNotFindDefinitionForFactoryWithArguments", testThatItThrowsErrorIfCanNotFindDefinitionForFactoryWithArguments),
      ("testThatItThrowsErrorIfConstructorThrows", testThatItThrowsErrorIfConstructorThrows),
      ("testThatItThrowsErrorIfFailsToResolveDependency", testThatItThrowsErrorIfFailsToResolveDependency)
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

  func testThatItResolvesInstanceRegisteredWithoutTag() {
    //given
    container.register { ServiceImp1() as Service }
    
    //when
    let serviceInstance = try! container.resolve() as Service
    
    //then
    XCTAssertTrue(serviceInstance is ServiceImp1)
  }

  func testThatItResolvesInstanceRegisteredWithTag() {
    //given
    container.register(tag: "service") { ServiceImp1() as Service }
    
    //when
    let serviceInstance = try! container.resolve(tag: "service") as Service
    
    //then
    XCTAssertTrue(serviceInstance is ServiceImp1)
  }
  
  func testThatItResolvesDifferentInstancesRegisteredForDifferentTags() {
    //given
    container.register(tag: "service1") { ServiceImp1() as Service }
    container.register(tag: "service2") { ServiceImp2() as Service }
    
    //when
    let service1Instance = try! container.resolve(tag: "service1") as Service
    let service2Instance = try! container.resolve(tag: "service2") as Service
    
    //then
    XCTAssertTrue(service1Instance is ServiceImp1)
    XCTAssertTrue(service2Instance is ServiceImp2)
  }
  
  func testThatNewRegistrationOverridesPreviousRegistration() {
    //given
    container.register { ServiceImp1() as Service }
    let service1 = try! container.resolve() as Service
    
    //when
    container.register { ServiceImp2() as Service }
    let service2 = try! container.resolve() as Service
    
    //then
    XCTAssertTrue(service1 is ServiceImp1)
    XCTAssertTrue(service2 is ServiceImp2)
  }
  
  func testThatItCallsResolveDependenciesOnDefinition() {
    //given
    var resolveDependenciesCalled = false
    container.register { ServiceImp1() as Service }.resolveDependencies { (c, s) in
      resolveDependenciesCalled = true
    }
    
    //when
    try! container.resolve() as Service
    
    //then
    XCTAssertTrue(resolveDependenciesCalled)
  }
  
  func testThatItThrowsErrorIfCanNotFindDefinitionForType() {
    //given
    container.register { ServiceImp1() as ServiceImp1 }
    
    //when
    AssertThrows(expression: try container.resolve() as Service) { error in
      guard case let DipError.DefinitionNotFound(key) = error else { return false }
      
      //then
      typealias F = () throws -> Service
      let expectedKey = DefinitionKey(protocolType: Service.self, factoryType: F.self, associatedTag: nil)
      XCTAssertEqual(key, expectedKey)

      return true
    }
  }
  
  func testThatItThrowsErrorIfCanNotFindDefinitionForTag() {
    //given
    container.register(tag: "some tag") { ServiceImp1() as Service }
    
    //when
    AssertThrows(expression: try container.resolve(tag: "other tag") as Service) { error in
      guard case let DipError.DefinitionNotFound(key) = error else { return false }
      
      //then
      typealias F = () throws -> Service
      let expectedKey = DefinitionKey(protocolType: Service.self, factoryType: F.self, associatedTag: "other tag")
      XCTAssertEqual(key, expectedKey)
      
      return true
    }
  }
  
  func testThatItThrowsErrorIfCanNotFindDefinitionForFactoryWithArguments() {
    //given
    container.register { ServiceImp1() as Service }
    
    //when
    AssertThrows(expression: try container.resolve(withArguments: "some string") as Service) { error in
      guard case let DipError.DefinitionNotFound(key) = error else { return false }
      
      //then
      typealias F = (String) throws -> Service
      let expectedKey = DefinitionKey(protocolType: Service.self, factoryType: F.self, associatedTag: nil)
      XCTAssertEqual(key, expectedKey)

      return true
    }
  }
  
  func testThatItThrowsErrorIfConstructorThrows() {
    //given
    let failedKey = DefinitionKey(protocolType: Any.self, factoryType: Any.self)
    let expectedError = DipError.DefinitionNotFound(key: failedKey)
    container.register { () throws -> Service in throw expectedError }
    
    //when
    AssertThrows(expression: try container.resolve() as Service) { error in
      guard case let DipError.ResolutionFailed(key, error) = error else { return false }
      guard case let DipError.DefinitionNotFound(subKey) = error where subKey == failedKey else { return false }
      
      //then
      typealias F = () throws -> Service
      let expectedKey = DefinitionKey(protocolType: Service.self, factoryType: F.self)
      XCTAssertEqual(key, expectedKey)
      
      return true
    }
  }
  
  func testThatItThrowsErrorIfFailsToResolveDependency() {
    //given
    let failedKey = DefinitionKey(protocolType: Any.self, factoryType: Any.self)
    let expectedError = DipError.DefinitionNotFound(key: failedKey)
    container.register { ServiceImp1() as Service }
      .resolveDependencies { container, service in
        //simulate throwing error when resolving dependency
        throw expectedError
    }
    
    //when
    AssertThrows(expression: try container.resolve() as Service) { error in
      guard case let DipError.ResolutionFailed(key, error) = error else { return false }
      guard case let DipError.DefinitionNotFound(subKey) = error where subKey == failedKey else { return false }
      
      //then
      typealias F = () throws -> Service
      let expectedKey = DefinitionKey(protocolType: Service.self, factoryType: F.self)
      XCTAssertEqual(key, expectedKey)
      
      return true
    }
  }

}


