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
private class ServiceImp3 {}

private protocol AutoWiredClient: class {
  var service1: Service! { get set }
  var service2: Service! { get set }
}

private class AutoWiredClientImp: AutoWiredClient {
  var service1: Service!
  var service2: Service!
  
  init(service1: Service?, service2: ServiceImp2) {
    self.service1 = service1
    self.service2 = service2
  }
  init() {}
}

class AutoWiringTests: XCTestCase {
  
  let container = DependencyContainer()

  static var allTests = {
    return [
      ("testThatItCanResolveWithAutoWiring", testThatItCanResolveWithAutoWiring),
      ("testThatItUsesAutoWireFactoryWithMostNumberOfArguments", testThatItUsesAutoWireFactoryWithMostNumberOfArguments),
      ("testThatItThrowsAmbiguityErrorWhenUsingAutoWire", testThatItThrowsAmbiguityErrorWhenUsingAutoWire),
      ("testThatItFirstTriesToUseTaggedFactoriesWhenUsingAutoWire", testThatItFirstTriesToUseTaggedFactoriesWhenUsingAutoWire),
      ("testThatItFallbackToNotTaggedFactoryWhenUsingAutoWire", testThatItFallbackToNotTaggedFactoryWhenUsingAutoWire),
      ("testThatItDoesNotTryToUseAutoWiringWhenCallingResolveWithArguments", testThatItDoesNotTryToUseAutoWiringWhenCallingResolveWithArguments),
      ("testThatItDoesNotUseAutoWiringWhenFailedToResolveLowLevelDependency", testThatItDoesNotUseAutoWiringWhenFailedToResolveLowLevelDependency),
      ("testThatItReusesInstancesResolvedWithAutoWiringWhenUsingAutoWiringAgain", testThatItReusesInstancesResolvedWithAutoWiringWhenUsingAutoWiringAgain),
      ("testThatItReusesInstancesResolvedWithAutoWiringWhenUsingAutoWiringAgainWithTheSameTag", testThatItReusesInstancesResolvedWithAutoWiringWhenUsingAutoWiringAgainWithTheSameTag),
      ("testThatItDoesNotReuseInstancesResolvedWithAutoWiringWhenUsingAutoWiringAgainWithAnotherTag", testThatItDoesNotReuseInstancesResolvedWithAutoWiringWhenUsingAutoWiringAgainWithAnotherTag),
      ("testThatItUsesTagToResolveDependenciesWithAutoWiringWith1Argument", testThatItUsesTagToResolveDependenciesWithAutoWiringWith1Argument),
      ("testThatItUsesTagToResolveDependenciesWithAutoWiringWith2Arguments", testThatItUsesTagToResolveDependenciesWithAutoWiringWith2Arguments),
      ("testThatItUsesTagToResolveDependenciesWithAutoWiringWith3Arguments", testThatItUsesTagToResolveDependenciesWithAutoWiringWith3Arguments),
      ("testThatItUsesTagToResolveDependenciesWithAutoWiringWith4Arguments", testThatItUsesTagToResolveDependenciesWithAutoWiringWith4Arguments),
      ("testThatItUsesTagToResolveDependenciesWithAutoWiringWith5Arguments", testThatItUsesTagToResolveDependenciesWithAutoWiringWith5Arguments),
      ("testThatItUsesTagToResolveDependenciesWithAutoWiringWith6Arguments", testThatItUsesTagToResolveDependenciesWithAutoWiringWith6Arguments),
      ("testThatItCanAutoWireOptional", testThatItCanAutoWireOptional)
    ]
  }()

  override func setUp() {
    container.reset()
  }

  func testThatItCanResolveWithAutoWiring() {
    //given
    container.register { ServiceImp1() as Service }
    container.register { ServiceImp2() }
    
    container.register { AutoWiredClientImp(service1: $0, service2: $1) as AutoWiredClient }
    
    //when
    let client = try! container.resolve() as AutoWiredClient
    
    //then
    let service1 = client.service1
    XCTAssertTrue(service1 is ServiceImp1)
    let service2 = client.service2
    XCTAssertTrue(service2 is ServiceImp2)
    
    //when
    let anyClient = try! container.resolve(AutoWiredClient.self)
    
    //then
    XCTAssertTrue(anyClient is AutoWiredClientImp)
  }
  
  func testThatItUsesAutoWireFactoryWithMostNumberOfArguments() {
    //given
    
    //1 arg
    container.register { AutoWiredClientImp(service1: $0, service2: try self.container.resolve()) as AutoWiredClient }
    //1 arg
    container.register { AutoWiredClientImp(service1: try self.container.resolve(), service2: $0) as AutoWiredClient }
    
    //2 args
    var factoryWithMostNumberOfArgumentsCalled = false
    container.register { AutoWiredClientImp(service1: $0, service2: $1) as AutoWiredClient }
      .resolvingProperties { _ in
        factoryWithMostNumberOfArgumentsCalled = true
    }
    
    container.register { ServiceImp1() as Service }
    container.register { ServiceImp2() }
    
    //when
    let _ = try! container.resolve() as AutoWiredClient
    
    //then
    XCTAssertTrue(factoryWithMostNumberOfArgumentsCalled)
  }
  
  func testThatItThrowsAmbiguityErrorWhenUsingAutoWire() {
    //given
    
    //1 arg
    container.register { AutoWiredClientImp(service1: $0, service2: try self.container.resolve()) as AutoWiredClient }
    //1 arg
    container.register { AutoWiredClientImp(service1: try self.container.resolve(), service2: $0) as AutoWiredClient }
    
    container.register { ServiceImp1() as Service }
    container.register { ServiceImp2() }
    
    //when
    AssertThrows(expression: try container.resolve() as AutoWiredClient) { error -> Bool in
      switch error {
      case let DipError.autoWiringFailed(_, error):
        if case DipError.ambiguousDefinitions = error { return true }
        else { return false }
      default: return false
      }
    }
  }
  
  func testThatItFirstTriesToUseTaggedFactoriesWhenUsingAutoWire() {
    //given
    
    //1 arg
    container.register { AutoWiredClientImp(service1: $0, service2: try self.container.resolve()) as AutoWiredClient }
    //1 arg
    container.register { AutoWiredClientImp(service1: try self.container.resolve(), service2: $0) as AutoWiredClient }
    
    //2 args
    container.register { AutoWiredClientImp(service1: $0, service2: $1) as AutoWiredClient }
    
    //1 arg tagged
    var taggedFactoryWithMostNumberOfArgumentsCalled = false
    container.register(tag: "tag") { AutoWiredClientImp(service1: $0, service2: try self.container.resolve()) as AutoWiredClient }
    
    //2 arg tagged
    container.register(tag: "tag") { AutoWiredClientImp(service1: $0, service2: $1) as AutoWiredClient }.resolvingProperties { _ in
      taggedFactoryWithMostNumberOfArgumentsCalled = true
    }

    container.register() { ServiceImp1() as Service }
    container.register { ServiceImp2() }
    
    //when
    let _ = try! container.resolve(tag: "tag") as AutoWiredClient
    
    //then
    XCTAssertTrue(taggedFactoryWithMostNumberOfArgumentsCalled)
  }
  
  func testThatItFallbackToNotTaggedFactoryWhenUsingAutoWire() {
    //given
    
    //1 arg
    var notTaggedFactoryWithMostNumberOfArgumentsCalled = false
    container.register { AutoWiredClientImp(service1: $0, service2: try self.container.resolve()) as AutoWiredClient }.resolvingProperties { _ in
      notTaggedFactoryWithMostNumberOfArgumentsCalled = true
    }
    
    //1 arg tagged
    container.register(tag: "tag") { AutoWiredClientImp(service1: $0, service2: try self.container.resolve()) as AutoWiredClient }
    
    container.register { ServiceImp1() as Service }
    container.register { ServiceImp2() }
    
    //when
    let _ = try! container.resolve(tag: "other tag") as AutoWiredClient
    
    //then
    XCTAssertTrue(notTaggedFactoryWithMostNumberOfArgumentsCalled)
  }
  
  func testThatItDoesNotTryToUseAutoWiringWhenCallingResolveWithArguments() {
    //given
    container.register { AutoWiredClientImp(service1: $0, service2: $1) as AutoWiredClient }
    container.register { ServiceImp1() as Service }
    container.register { ServiceImp2() }
    
    //when
    let service = try! container.resolve() as Service
    AssertThrows(expression: try container.resolve(arguments: service) as AutoWiredClient,
      "Container should not use auto-wiring when resolving with runtime arguments")
  }
  
  func testThatItDoesNotUseAutoWiringWhenFailedToResolveLowLevelDependency() {
    //given
    container.register { AutoWiredClientImp() as AutoWiredClient }
      .resolvingProperties { container, resolved in
        resolved.service1 = try container.resolve() as Service
        resolved.service2 = try container.resolve() as ServiceImp2
        
        //simulate that something goes wrong on the way
        throw DipError.definitionNotFound(key: DefinitionKey(type: ServiceImp1.self, typeOfArguments: Any.self))
    }
    
    container.register { AutoWiredClientImp(service1: $0, service2: $1) as AutoWiredClient }
      .resolvingProperties { container, resolved in
        //auto-wiring should be performed only when definition for type to resolve is not found
        //but not for any other type along the way in the graph
        XCTFail("Auto-wiring should not be performed if instance was actually resolved.")
    }
    
    container.register { ServiceImp1() as Service }
    container.register { ServiceImp2() }
    
    //then
    AssertThrows(expression: try container.resolve() as AutoWiredClient,
      "Container should not use auto-wiring when definition for resolved type is registered.")
  }
  
  func testThatItReusesInstancesResolvedWithAutoWiringWhenUsingAutoWiringAgain() {
    
    //given
    container.register { ServiceImp1() as Service }
    container.register { ServiceImp2() }
    
    var anotherInstance: AutoWiredClient?
    
    container.register { AutoWiredClientImp(service1: $0, service2: $1) as AutoWiredClient }
      .resolvingProperties { container, _ in
        if anotherInstance == nil {
          anotherInstance = try! container.resolve() as AutoWiredClient
        }
    }
    
    //when
    let resolved = try! container.resolve() as AutoWiredClient
    
    //then
    //when doing another auto-wiring during resolve we should reuse instance
    XCTAssertTrue((resolved as! AutoWiredClientImp) === (anotherInstance as! AutoWiredClientImp))
  }
  
  func testThatItReusesInstancesResolvedWithoutAutoWiringWhenUsingAutoWiringAgain() {
    
    //given
    container.register { ServiceImp1() as Service }
    container.register { ServiceImp2() }
    
    var anotherInstance: AutoWiredClient?
    
    container.register { AutoWiredClientImp(service1: $0, service2: $1) as AutoWiredClient }
      .resolvingProperties { container, _ in
        if anotherInstance == nil {
          anotherInstance = try! container.resolve() as AutoWiredClient
        }
    }
    
    //when
    let service1 = try! container.resolve() as Service?
    let service2 = try! container.resolve() as ServiceImp2
    let resolved = try! container.resolve(arguments: service1, service2) as AutoWiredClient
    
    //then
    //when doing another auto-wiring during resolve we should reuse instance
    XCTAssertTrue((resolved as! AutoWiredClientImp) === (anotherInstance as! AutoWiredClientImp))
  }

  func testThatItReusesInstancesResolvedWithAutoWiringWhenUsingAutoWiringAgainWithTheSameTag() {
    
    //given
    container.register { ServiceImp1() as Service }
    container.register { ServiceImp2() }
    
    var anotherInstance: AutoWiredClient?
    
    container.register(tag: "tag") { AutoWiredClientImp(service1: $0, service2: $1) as AutoWiredClient }
      .resolvingProperties { container, _ in
        if anotherInstance == nil {
          anotherInstance = try! container.resolve(tag: "tag") as AutoWiredClient
        }
    }
    
    //when
    let resolved = try! container.resolve(tag: "tag") as AutoWiredClient
    
    //then
    //when doing another auto-wiring during resolve we should reuse instance
    XCTAssertTrue((resolved as! AutoWiredClientImp) === (anotherInstance as! AutoWiredClientImp))
  }
  
  func testThatItDoesNotReuseInstancesResolvedWithAutoWiringWhenUsingAutoWiringAgainWithAnotherTag() {
    
    //given
    container.register { ServiceImp1() as Service }
    container.register { ServiceImp2() }
    
    var anotherInstance: AutoWiredClient?
    
    container.register { AutoWiredClientImp(service1: $0, service2: $1) as AutoWiredClient }
      .resolvingProperties { container, _ in
        if anotherInstance == nil {
          anotherInstance = try! container.resolve() as AutoWiredClient
        }
    }
    
    //when
    let resolved = try! container.resolve(tag: "tag") as AutoWiredClient
    
    //then
    //when doing another auto-wiring during resolve we should reuse instance
    XCTAssertTrue((resolved as! AutoWiredClientImp) !== (anotherInstance as! AutoWiredClientImp))
  }
  
  func testThatItUsesTagToResolveDependenciesWithAutoWiringWith1Argument() {
    //given
    container.register { ServiceImp1() as Service }
    container.register(tag: "tag") { ServiceImp2() as Service }
    
    container.register { (dep1: Service) -> ServiceImp3 in
      XCTAssertTrue(dep1 is ServiceImp2)
      return ServiceImp3()
    }
    
    //when
    let _ = try! container.resolve(tag: "tag") as ServiceImp3
  }

  func testThatItUsesTagToResolveDependenciesWithAutoWiringWith2Arguments() {
    //given
    container.register { ServiceImp1() as Service }
    container.register(tag: "tag") { ServiceImp2() as Service }
    
    container.register { (dep1: Service, dep2: Service) -> ServiceImp3 in
      XCTAssertTrue(dep1 is ServiceImp2)
      XCTAssertTrue(dep2 is ServiceImp2)
      return ServiceImp3()
    }
    
    //when
    let _ = try! container.resolve(tag: "tag") as ServiceImp3
  }

  func testThatItUsesTagToResolveDependenciesWithAutoWiringWith3Arguments() {
    //given
    container.register { ServiceImp1() as Service }
    container.register(tag: "tag") { ServiceImp2() as Service }
    
    container.register { (dep1: Service, dep2: Service, dep3: Service) -> ServiceImp3 in
      XCTAssertTrue(dep1 is ServiceImp2)
      XCTAssertTrue(dep2 is ServiceImp2)
      XCTAssertTrue(dep3 is ServiceImp2)
      return ServiceImp3()
    }
    
    //when
    let _ = try! container.resolve(tag: "tag") as ServiceImp3
  }

  func testThatItUsesTagToResolveDependenciesWithAutoWiringWith4Arguments() {
    //given
    container.register { ServiceImp1() as Service }
    container.register(tag: "tag") { ServiceImp2() as Service }
    
    container.register { (dep1: Service, dep2: Service, dep3: Service, dep4: Service) -> ServiceImp3 in
      XCTAssertTrue(dep1 is ServiceImp2)
      XCTAssertTrue(dep2 is ServiceImp2)
      XCTAssertTrue(dep3 is ServiceImp2)
      XCTAssertTrue(dep4 is ServiceImp2)
      return ServiceImp3()
    }
    
    //when
    let _ = try! container.resolve(tag: "tag") as ServiceImp3
  }

  func testThatItUsesTagToResolveDependenciesWithAutoWiringWith5Arguments() {
    //given
    container.register { ServiceImp1() as Service }
    container.register(tag: "tag") { ServiceImp2() as Service }
    
    container.register { (dep1: Service, dep2: Service, dep3: Service, dep4: Service, dep5: Service) -> ServiceImp3 in
      XCTAssertTrue(dep1 is ServiceImp2)
      XCTAssertTrue(dep2 is ServiceImp2)
      XCTAssertTrue(dep3 is ServiceImp2)
      XCTAssertTrue(dep4 is ServiceImp2)
      XCTAssertTrue(dep5 is ServiceImp2)
      return ServiceImp3()
    }
    
    //when
    let _ = try! container.resolve(tag: "tag") as ServiceImp3
  }

  func testThatItUsesTagToResolveDependenciesWithAutoWiringWith6Arguments() {
    //given
    container.register { ServiceImp1() as Service }
    container.register(tag: "tag") { ServiceImp2() as Service }
    
    container.register { (dep1: Service, dep2: Service, dep3: Service, dep4: Service, dep5: Service, dep6: Service) -> ServiceImp3 in
      XCTAssertTrue(dep1 is ServiceImp2)
      XCTAssertTrue(dep2 is ServiceImp2)
      XCTAssertTrue(dep3 is ServiceImp2)
      XCTAssertTrue(dep4 is ServiceImp2)
      XCTAssertTrue(dep5 is ServiceImp2)
      XCTAssertTrue(dep6 is ServiceImp2)
      return ServiceImp3()
    }
    
    //when
    let _ = try! container.resolve(tag: "tag") as ServiceImp3
  }

  func testThatItCanAutoWireOptional() {
    //given
    container.register { ServiceImp1() as Service }
    container.register { ServiceImp2() }
    container.register { AutoWiredClientImp(service1: $0, service2: $1) as AutoWiredClient }
    
    var resolved: AutoWiredClient?
    //when
    AssertNoThrow(expression: resolved = try container.resolve() as AutoWiredClient?)
    XCTAssertNotNil(resolved)
    
    //when
    AssertNoThrow(expression: resolved = try container.resolve() as AutoWiredClient!)
    XCTAssertNotNil(resolved)

    //when
    AssertNoThrow(expression: resolved = try container.resolve(tag: "tag") as AutoWiredClient?)
    XCTAssertNotNil(resolved)
    
    //when
    AssertNoThrow(expression: resolved = try container.resolve(tag: "tag") as AutoWiredClient!)
    XCTAssertNotNil(resolved)
  }
  
}

