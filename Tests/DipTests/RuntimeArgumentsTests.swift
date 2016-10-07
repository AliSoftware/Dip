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

private protocol Service {
  var name: String { get }
}

private class ServiceImp: Service {
  
  let name: String
  
  init(name: String, baseURL: String, port: Int) {
    self.name = name
  }
  
}

private class ServiceImp1: Service {
  let name: String = "ServiceImp1"
}

private class ServiceImp2: Service {
  let name: String = "ServiceImp2"
}

class RuntimeArgumentsTests: XCTestCase {
  
  let container = DependencyContainer()
 
  static var allTests = {
    return [
      ("testThatItResolvesInstanceWithOneArgument", testThatItResolvesInstanceWithOneArgument),
      ("testThatItResolvesInstanceWithTwoArguments", testThatItResolvesInstanceWithTwoArguments),
      ("testThatItResolvesInstanceWithThreeArguments", testThatItResolvesInstanceWithThreeArguments),
      ("testThatItResolvesInstanceWithFourArguments", testThatItResolvesInstanceWithFourArguments),
      ("testThatItResolvesInstanceWithFiveArguments", testThatItResolvesInstanceWithFiveArguments),
      ("testThatItResolvesInstanceWithSixArguments", testThatItResolvesInstanceWithSixArguments),
      ("testThatItRegistersDifferentFactoriesForDifferentNumberOfArguments", testThatItRegistersDifferentFactoriesForDifferentNumberOfArguments),
      ("testThatItRegistersDifferentFactoriesForDifferentTypesOfArguments", testThatItRegistersDifferentFactoriesForDifferentTypesOfArguments),
      ("testThatItRegistersDifferentFactoriesForDifferentOrderOfArguments", testThatItRegistersDifferentFactoriesForDifferentOrderOfArguments),
      ("testThatNewRegistrationWithSameArgumentsOverridesPreviousRegistration", testThatNewRegistrationWithSameArgumentsOverridesPreviousRegistration),
      ("testThatDifferentFactoriesRegisteredIfArgumentIsOptional", testThatDifferentFactoriesRegisteredIfArgumentIsOptional)
    ]
  }()

  override func setUp() {
    container.reset()
  }
  
  func testThatItResolvesInstanceWithOneArgument() {
    //given
    let arg1 = 1
    container.register(factory: { (a1: Int) -> Service in
      XCTAssertEqual(a1, arg1)
      return ServiceImp1()
    })
    
    //when
    let service = try! container.resolve(arguments: arg1) as Service
    
    //then
    XCTAssertTrue(service is ServiceImp1)
    
    //when
    let anyService = try! container.resolve(Service.self, arguments: arg1)
    
    //then
    XCTAssertTrue(anyService is ServiceImp1)
  }
  
  func testThatItResolvesInstanceWithTwoArguments() {
    //given
    let arg1 = 1, arg2 = 2
    container.register { (a1: Int, a2: Int) -> Service in
      XCTAssertEqual(a1, arg1)
      XCTAssertEqual(a2, arg2)
      return ServiceImp1()
    }
    
    //when
    let service = try! container.resolve(arguments: arg1, arg2) as Service
    
    //then
    XCTAssertTrue(service is ServiceImp1)

    //when
    let anyService = try! container.resolve(Service.self, arguments: arg1, arg2)
    
    //then
    XCTAssertTrue(anyService is ServiceImp1)
  }
  
  func testThatItResolvesInstanceWithThreeArguments() {
    let arg1 = 1, arg2 = 2, arg3 = 3
    container.register { (a1: Int, a2: Int, a3: Int) -> Service in
      XCTAssertEqual(a1, arg1)
      XCTAssertEqual(a2, arg2)
      XCTAssertEqual(a3, arg3)
      return ServiceImp1()
    }
    
    //when
    let service = try! container.resolve(arguments: arg1, arg2, arg3) as Service
    
    //then
    XCTAssertTrue(service is ServiceImp1)
    
    //when
    let anyService = try! container.resolve(Service.self, arguments: arg1, arg2, arg3)
    
    //then
    XCTAssertTrue(anyService is ServiceImp1)
  }
  
  func testThatItResolvesInstanceWithFourArguments() {
    let arg1 = 1, arg2 = 2, arg3 = 3, arg4 = 4
    container.register { (a1: Int, a2: Int, a3: Int, a4: Int) -> Service in
      XCTAssertEqual(a1, arg1)
      XCTAssertEqual(a2, arg2)
      XCTAssertEqual(a3, arg3)
      XCTAssertEqual(a4, arg4)
      return ServiceImp1()
    }
    
    //when
    let service = try! container.resolve(arguments: arg1, arg2, arg3, arg4) as Service
    
    //then
    XCTAssertTrue(service is ServiceImp1)
    
    //when
    let anyService = try! container.resolve(Service.self, arguments: arg1, arg2, arg3, arg4)
    
    //then
    XCTAssertTrue(anyService is ServiceImp1)
  }
  
  func testThatItResolvesInstanceWithFiveArguments() {
    let arg1 = 1, arg2 = 2, arg3 = 3, arg4 = 4, arg5 = 5
    container.register { (a1: Int, a2: Int, a3: Int, a4: Int, a5: Int) -> Service in
      XCTAssertEqual(a1, arg1)
      XCTAssertEqual(a2, arg2)
      XCTAssertEqual(a3, arg3)
      XCTAssertEqual(a4, arg4)
      XCTAssertEqual(a5, arg5)
      return ServiceImp1()
    }
    
    //when
    let service = try! container.resolve(arguments: arg1, arg2, arg3, arg4, arg5) as Service
    
    //then
    XCTAssertTrue(service is ServiceImp1)
    
    //when
    let anyService = try! container.resolve(Service.self, arguments: arg1, arg2, arg3, arg4, arg5)
    
    //then
    XCTAssertTrue(anyService is ServiceImp1)
  }
  
  func testThatItResolvesInstanceWithSixArguments() {
    let arg1 = 1, arg2 = 2, arg3 = 3, arg4 = 4, arg5 = 5, arg6 = 6
    container.register { (a1: Int, a2: Int, a3: Int, a4: Int, a5: Int, a6: Int) -> Service in
      XCTAssertEqual(a1, arg1)
      XCTAssertEqual(a2, arg2)
      XCTAssertEqual(a3, arg3)
      XCTAssertEqual(a4, arg4)
      XCTAssertEqual(a5, arg5)
      XCTAssertEqual(a6, arg6)
      return ServiceImp1()
    }
    
    //when
    let service = try! container.resolve(arguments: arg1, arg2, arg3, arg4, arg5, arg6) as Service
    
    //then
    XCTAssertTrue(service is ServiceImp1)
    
    //when
    let anyService = try! container.resolve(Service.self, arguments: arg1, arg2, arg3, arg4, arg5, arg6)
    
    //then
    XCTAssertTrue(anyService is ServiceImp1)
  }
  
  func testThatItRegistersDifferentFactoriesForDifferentNumberOfArguments() {
    //given
    let arg1 = 1, arg2 = 2
    container.register { (a1: Int) in ServiceImp1() as Service }
    container.register { (a1: Int, a2: Int) in ServiceImp2() as Service }
    
    //when
    let service1 = try! container.resolve(arguments: arg1) as Service
    let service2 = try! container.resolve(arguments: arg1, arg2) as Service
    
    //then
    XCTAssertTrue(service1 is ServiceImp1)
    XCTAssertTrue(service2 is ServiceImp2)
  }
  
  func testThatItRegistersDifferentFactoriesForDifferentTypesOfArguments() {
    //given
    let arg1 = 1, arg2 = "string"
    container.register(factory: { (a1: Int) in ServiceImp1() as Service })
    container.register(factory: { (a1: String) in ServiceImp2() as Service })
    
    //when
    let service1 = try! container.resolve(arguments: arg1) as Service
    let service2 = try! container.resolve(arguments: arg2) as Service
    
    //then
    XCTAssertTrue(service1 is ServiceImp1)
    XCTAssertTrue(service2 is ServiceImp2)
  }
  
  func testThatItRegistersDifferentFactoriesForDifferentOrderOfArguments() {
    //given
    let arg1 = 1, arg2 = "string"
    container.register { (a1: Int, a2: String) in ServiceImp1() as Service }
    container.register { (a1: String, a2: Int) in ServiceImp2() as Service }
    
    //when
    let service1 = try! container.resolve(arguments: arg1, arg2) as Service
    let service2 = try! container.resolve(arguments: arg2, arg1) as Service
    
    //then
    XCTAssertTrue(service1 is ServiceImp1)
    XCTAssertTrue(service2 is ServiceImp2)
  }
  
  func testThatNewRegistrationWithSameArgumentsOverridesPreviousRegistration() {
    //given
    let arg1 = 1, arg2 = 2
    container.register { (a1: Int, a2: Int) in ServiceImp1() as Service }
    let service1 = try! container.resolve(arguments: arg1, arg2) as Service
    
    //when
    container.register { (a1: Int, a2: Int) in ServiceImp2() as Service }
    let service2 = try! container.resolve(arguments: arg1, arg2) as Service
    
    //then
    XCTAssertTrue(service1 is ServiceImp1)
    XCTAssertTrue(service2 is ServiceImp2)
  }
  
  func testThatDifferentFactoriesRegisteredIfArgumentIsOptional() {
    //given
    let name1 = "1", name2 = "2"
    container.register { (port: Int, url: String) in ServiceImp(name: name1, baseURL: url, port: port) as Service }
    container.register { (port: Int, url: String?) in ServiceImp(name: name2, baseURL: url!, port: port) as Service }
    
    //when
    let service1 = try! container.resolve(arguments: 80, "http://example.com") as Service
    let service2 = try! container.resolve(arguments: 80, "http://example.com" as String?) as Service
    
    //then
    XCTAssertEqual(service1.name, name1)
    XCTAssertEqual(service2.name, name2)
    
    //Due to incomplete implementation of SE-0054 (bug: https://bugs.swift.org/browse/SR-2143)
    //registering definition with T? and T! arguments types will produce two different definitions
    //but when argement of T! will be passed to `resolve` method it will be transformed to T?
    //and wrong definition will be used
    //When fixed using T? and T! should not register two different definitions

//    let name3 = "3"
//    container.register { (port: Int, url: String!) in ServiceImp(name: name3, baseURL: url, port: port) as Service }
//    let service3 = try! container.resolve(arguments: 80, "http://example.com" as String!) as Service
//    XCTAssertEqual(service3.name, name3)
  }
  
}

