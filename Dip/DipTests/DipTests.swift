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

protocol Service: class {
  func getServiceName() -> String
}

extension Service {
  func getServiceName() -> String {
    return "\(self.dynamicType)"
  }
}

class ServiceImp1: Service {
}

class ServiceImp2: Service {
}

class DipTests: XCTestCase {
  
  let container = DependencyContainer()
  
  override func setUp() {
    super.setUp()
    container.reset()
  }
  
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
    do {
      try container.resolve() as Service
      XCTFail("Unexpectedly resolved protocol")
    }
    catch DipError.DefinitionNotFound(let key) {
      typealias F = () throws -> Service
      let expectedKey = DefinitionKey(protocolType: Service.self, factoryType: F.self, associatedTag: nil)
      XCTAssertEqual(key, expectedKey)
    }
    catch {
      XCTFail("Thrown unexpected error")
    }
  }
  
  func testThatItThrowsErrorIfCanNotFindDefinitionForTag() {
    //given
    container.register(tag: "some tag") { ServiceImp1() as Service }
    
    //when
    do {
      try container.resolve(tag: "other tag") as Service
      XCTFail("Unexpectedly resolved protocol")
    }
    catch DipError.DefinitionNotFound(let key) {
      typealias F = () throws -> Service
      let expectedKey = DefinitionKey(protocolType: Service.self, factoryType: F.self, associatedTag: "other tag")
      XCTAssertEqual(key, expectedKey)
    }
    catch {
      XCTFail("Thrown unexpected error")
    }
  }
  
  func testThatItThrowsErrorIfCanNotFindDefinitionForFactory() {
    //given
    container.register { ServiceImp1() as Service }
    
    //when
    do {
      try container.resolve(withArguments: "some string") as Service
      XCTFail("Unexpectedly resolved protocol")
    }
    catch DipError.DefinitionNotFound(let key) {
      typealias F = (String) throws -> Service
      let expectedKey = DefinitionKey(protocolType: Service.self, factoryType: F.self, associatedTag: nil)
      XCTAssertEqual(key, expectedKey)
    }
    catch {
      XCTFail("Thrown unexpected error")
    }
  }
  
  func testThatItCanResolveAllImplementationsAsArray() {
    container.register() { ServiceImp1() as Service }
    container.register(tag: "service1") { ServiceImp1() as Service }
    container.register(tag: "service2") { ServiceImp2() as Service }

    let allServices = try! container.resolveAll() as [Service]
    
    XCTAssertEqual(allServices.count, 3)
    XCTAssertTrue(allServices[0] is ServiceImp1)
    XCTAssertTrue(allServices[1] is ServiceImp1)
    XCTAssertTrue(allServices[2] is ServiceImp2)
    
    XCTAssertFalse(allServices[2] === allServices[1])
  }

  func testThatItDoesNotReusesInstancesInObjectGraphScopeWhenResolvingAsArray() {
    container.register(.ObjectGraph) { ServiceImp1() as Service }
    container.register(tag: "service1", .ObjectGraph) { ServiceImp1() as Service }
    container.register(tag: "service1_1") { ServiceImp1() as Service }
    
    let allServices = try! container.resolveAll() as [Service]
    
    XCTAssertEqual(allServices.count, 3)
    
    XCTAssertFalse(allServices[2] === allServices[1])
    XCTAssertFalse(allServices[0] === allServices[1])
  }

  func testThatItCanRemoveAndReAddDefinition() {
    let def1 = container.register() { ServiceImp1() as Service }
    container.register(tag: "service2") { ServiceImp2() as Service }

    container.remove(def1)
    
    let allServices = try! container.resolveAll() as [Service]
    XCTAssertEqual(allServices.count, 1)
    XCTAssertTrue(allServices.last is ServiceImp2)
    
    container.register() { ServiceImp1() as Service }

    let newAllServices = try! container.resolveAll() as [Service]
    XCTAssertEqual(newAllServices.count, 2)
    XCTAssertTrue(newAllServices.first is ServiceImp1)
    XCTAssertTrue(newAllServices.last is ServiceImp2)
  }
  
  func testTagsEquality() {
    XCTAssertEqual(DependencyContainer.Tag.String("a"), DependencyContainer.Tag.String("a"))
    XCTAssertNotEqual(DependencyContainer.Tag.String("a"), DependencyContainer.Tag.String("b"))

    XCTAssertEqual(DependencyContainer.Tag.Int(0), DependencyContainer.Tag.Int(0))
    XCTAssertNotEqual(DependencyContainer.Tag.Int(0), DependencyContainer.Tag.Int(1))
    
    XCTAssertEqual(DependencyContainer.Tag.String("0"), DependencyContainer.Tag.Int(0))
    XCTAssertEqual(DependencyContainer.Tag.Int(0), DependencyContainer.Tag.String("0"))
    
    XCTAssertNotEqual(DependencyContainer.Tag.String("0"), DependencyContainer.Tag.Int(1))
    XCTAssertNotEqual(DependencyContainer.Tag.Int(1), DependencyContainer.Tag.String("0"))
  }
  
  func testTagsComparison() {
    XCTAssertLessThan(DependencyContainer.Tag.String("a"), DependencyContainer.Tag.String("b"))
    XCTAssertLessThan(DependencyContainer.Tag.Int(0), DependencyContainer.Tag.Int(1))
    XCTAssertLessThan(DependencyContainer.Tag.Int(0), DependencyContainer.Tag.String("1"))
    XCTAssertLessThan(DependencyContainer.Tag.String("0"), DependencyContainer.Tag.Int(1))
  }
  
}
