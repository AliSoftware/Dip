//
//  DipTests.swift
//  DipTests
//
//  This code is under MIT Licence. See the LICENCE file for more info.
//

import XCTest
@testable import Dip

protocol Service {
  func getServiceName() -> String
}

extension Service {
  func getServiceName() -> String {
    return "\(self.dynamicType)"
  }
}

class ServiceImp1: Service {}

class ServiceImp2: Service {}

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
    let serviceInstance = container.resolve() as Service
    
    //then
    XCTAssertTrue(serviceInstance is ServiceImp1)
  }
  
  func testThatItResolvesInstanceRegisteredWithTag() {
    //given
    container.register(tag: "service") { ServiceImp1() as Service }
    
    //when
    let serviceInstance = container.resolve(tag: "service") as Service
    
    //then
    XCTAssertTrue(serviceInstance is ServiceImp1)
  }
  
  func testThatItResolvesDifferentInstancesRegisteredForDifferentTags() {
    //given
    container.register(tag: "service1") { ServiceImp1() as Service }
    container.register(tag: "service2") { ServiceImp2() as Service }
    
    //when
    let service1Instance = container.resolve(tag: "service1") as Service
    let service2Instance = container.resolve(tag: "service2") as Service
    
    //then
    XCTAssertTrue(service1Instance is ServiceImp1)
    XCTAssertTrue(service2Instance is ServiceImp2)
  }
  
  func testThatNewRegistrationOverridesPreviousRegistration() {
    //given
    container.register { ServiceImp1() as Service }
    let service1 = container.resolve() as Service
    
    //when
    container.register { ServiceImp2() as Service }
    let service2 = container.resolve() as Service
    
    //then
    XCTAssertTrue(service1 is ServiceImp1)
    XCTAssertTrue(service2 is ServiceImp2)
  }
  
  func testThatItCallsResolveDependenciesOnDefinition() {
    //given
    var resolveDependenciesCalled = false
    container.register { ServiceImp1() as Service }.resolveDependencies(container) { (c, s) in
      resolveDependenciesCalled = true
    }
    
    //when
    container.resolve() as Service
    
    //then
    XCTAssertTrue(resolveDependenciesCalled)
  }
  
}
