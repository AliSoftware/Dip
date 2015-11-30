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
  
  func testThatItReusesInstanceRegisteredAsSingleton() {
    //given
    container.register(.Singleton) { ServiceImp1() as Service }
    
    //when
    let service1 = container.resolve() as Service
    let service2 = container.resolve() as Service
    
    //then
    XCTAssertTrue((service1 as! ServiceImp1) === (service2 as! ServiceImp1))
  }
  
}
