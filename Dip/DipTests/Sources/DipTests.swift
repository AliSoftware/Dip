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
private protocol AnotherService: class { }
private class ServiceImp1: NSObject, Service, AnotherService { }
private class ServiceImp2: NSObject, Service, AnotherService { }

private protocol Server: class {
  weak var client: Client? { get }
}
private protocol Client: class {
  var server: Server? { get }
}

class DipTests: XCTestCase {

  let container = DependencyContainer()

  #if os(Linux)
  var allTests: [(String, () throws -> Void)] {
    return [
      ("testThatItResolvesInstanceRegisteredWithoutTag", testThatItResolvesInstanceRegisteredWithoutTag),
      ("testThatItResolvesInstanceByTypeForwarding", testThatItResolvesInstanceByTypeForwarding),
      ("testThatItResolvesInstanceRegisteredWithTag", testThatItResolvesInstanceRegisteredWithTag),
      ("testThatItResolvesDifferentInstancesRegisteredForDifferentTags", testThatItResolvesDifferentInstancesRegisteredForDifferentTags),
      ("testThatNewRegistrationOverridesPreviousRegistration", testThatNewRegistrationOverridesPreviousRegistration),
      ("testThatItCallsResolveDependenciesOnDefinition", testThatItCallsResolveDependenciesOnDefinition),
      ("testThatItThrowsErrorIfCanNotFindDefinitionForType", testThatItThrowsErrorIfCanNotFindDefinitionForType),
      ("testThatItThrowsErrorIfCanNotFindDefinitionForTag", testThatItThrowsErrorIfCanNotFindDefinitionForTag),
      ("testThatItThrowsErrorIfCanNotFindDefinitionForFactoryWithArguments", testThatItThrowsErrorIfCanNotFindDefinitionForFactoryWithArguments),
      ("testThatItThrowsErrorIfConstructorThrows", testThatItThrowsErrorIfConstructorThrows),
      ("testThatItThrowsErrorIfFailsToResolveDependency", testThatItThrowsErrorIfFailsToResolveDependency),
      ("testThatItCallsDidResolveDependenciesOnResolvableIntance", testThatItCallsDidResolveDependenciesOnResolvableIntance),
      ("testThatItCallsDidResolveDependenciesInReverseOrder", testThatItCallsDidResolveDependenciesInReverseOrder),
      ("testThatItResolvesCircularDependencies", testThatItResolvesCircularDependencies)
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
    
    let anyService = try! container.resolve(Service.self)
    XCTAssertTrue(anyService is ServiceImp1)
  }
  
  func testThatItResolvesInstanceByTypeForwarding() {
    //given
    container.register { ServiceImp1() as Service }
      .implements(AnotherService.self, NSObject.self)
    
    //when
    let anotherService = try! container.resolve() as AnotherService
    let object = try! container.resolve() as NSObject

    //and when
    let anyOtherService = try! container.resolve(AnotherService.self)
    let anyObject = try! container.resolve(NSObject.self)

    //then
    XCTAssertTrue(anotherService is ServiceImp1)
    XCTAssertTrue(object is ServiceImp1)

    XCTAssertTrue(anyOtherService is ServiceImp1)
    XCTAssertTrue(anyObject is ServiceImp1)
  }
  
  func testThatItUsesTaggedDefinitionWhenResolvingInstanceByTypeForwarding() {
    //given
    container.register() { ServiceImp1() as Service }
      .implements(AnotherService.self, NSObject.self)
    
    container.register(tag: "tag") { ServiceImp2() as Service }
      .implements(AnotherService.self, NSObject.self)
    
    //when
    let anotherService = try! container.resolve(tag: "tag") as AnotherService
    let object = try! container.resolve(tag: "tag") as NSObject
    
    //and when
    let anyOtherService = try! container.resolve(AnotherService.self, tag: "tag")
    let anyObject = try! container.resolve(NSObject.self, tag: "tag")
    
    //then
    XCTAssertTrue(anotherService is ServiceImp2)
    XCTAssertTrue(object is ServiceImp2)
    
    XCTAssertTrue(anyOtherService is ServiceImp2)
    XCTAssertTrue(anyObject is ServiceImp2)
  }
  
  func testThatItFallbackToDefinitionWithNoTagWhenResolvingInstanceByTypeForwarding() {
    //given
    container.register { ServiceImp1() as Service }
      .implements(AnotherService.self, NSObject.self, NSCoder.self)
    
    //when
    let anotherService = try! container.resolve(tag: "tag") as AnotherService
    let object = try! container.resolve(tag: "tag") as NSObject
    
    //and when
    let anyOtherService = try! container.resolve(AnotherService.self, tag: "tag")
    let anyObject = try! container.resolve(NSObject.self, tag: "tag")
    
    //then
    XCTAssertTrue(anotherService is ServiceImp1)
    XCTAssertTrue(object is ServiceImp1)
    
    XCTAssertTrue(anyOtherService is ServiceImp1)
    XCTAssertTrue(anyObject is ServiceImp1)
  }
  
  func testThatItThrowsErrorWhenResolvingNotImplementedTypeWithTypeForwarding() {
    //given
    container.register { ServiceImp1() as Service }
      .implements(NSCoder.self)

    //then
    AssertThrows(expression: try container.resolve() as NSCoder)
    
    //but no throw with weakly typed resolve
    AssertNoThrow(expression: try container.resolve(NSCoder.self))
  }

  func testThatItResolvesInstanceRegisteredWithTag() {
    //given
    container.register(tag: "service") { ServiceImp1() as Service }
    
    //when
    let serviceInstance = try! container.resolve(tag: "service") as Service
    
    //then
    XCTAssertTrue(serviceInstance is ServiceImp1)

    //and when
    let anyService = try! container.resolve(Service.self, tag: "service")
    
    //then
    XCTAssertTrue(anyService is ServiceImp1)
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
    
    //when
    let anyService1 = try! container.resolve(Service.self, tag: "service1")
    let anyService2 = try! container.resolve(Service.self, tag: "service2")
    
    //then
    XCTAssertTrue(anyService1 is ServiceImp1)
    XCTAssertTrue(anyService2 is ServiceImp2)
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
    resolveDependenciesCalled = false
    
    //and when
    try! container.resolve(Service.self)
    
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
      let expectedKey = DefinitionKey(protocolType: Service.self, argumentsType: Void.self, associatedTag: nil)
      XCTAssertEqual(key, expectedKey)

      return true
    }

    //and when
    AssertThrows(expression: try container.resolve(Service.self)) { error in
      guard case let DipError.DefinitionNotFound(key) = error else { return false }
      
      //then
      let expectedKey = DefinitionKey(protocolType: Service.self, argumentsType: Void.self, associatedTag: nil)
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
      let expectedKey = DefinitionKey(protocolType: Service.self, argumentsType: Void.self, associatedTag: "other tag")
      XCTAssertEqual(key, expectedKey)
      
      return true
    }

    //and when
    AssertThrows(expression: try container.resolve(Service.self, tag: "other tag")) { error in
      guard case let DipError.DefinitionNotFound(key) = error else { return false }
      
      //then
      let expectedKey = DefinitionKey(protocolType: Service.self, argumentsType: Void.self, associatedTag: "other tag")
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
      let expectedKey = DefinitionKey(protocolType: Service.self, argumentsType: String.self, associatedTag: nil)
      XCTAssertEqual(key, expectedKey)

      return true
    }

    //and when
    AssertThrows(expression: try container.resolve(Service.self, withArguments: "some string")) { error in
      guard case let DipError.DefinitionNotFound(key) = error else { return false }
      
      //then
      let expectedKey = DefinitionKey(protocolType: Service.self, argumentsType: String.self, associatedTag: nil)
      XCTAssertEqual(key, expectedKey)
      
      return true
    }
  }
  
  func testThatItThrowsErrorIfConstructorThrows() {
    //given
    let failedKey = DefinitionKey(protocolType: Any.self, argumentsType: Any.self)
    let expectedError = DipError.DefinitionNotFound(key: failedKey)
    container.register { () throws -> Service in throw expectedError }
    
    //when
    AssertThrows(expression: try container.resolve() as Service) { error in
      switch error {
      case let DipError.DefinitionNotFound(key) where key == failedKey: return true
      default: return false
      }
    }
    
    //and when
    AssertThrows(expression: try container.resolve(Service.self)) { error in
      switch error {
      case let DipError.DefinitionNotFound(key) where key == failedKey: return true
      default: return false
      }
    }
  }
  
  func testThatItThrowsErrorIfFailsToResolveDependency() {
    //given
    let failedKey = DefinitionKey(protocolType: Any.self, argumentsType: Any.self)
    let expectedError = DipError.DefinitionNotFound(key: failedKey)
    container.register { ServiceImp1() as Service }
      .resolveDependencies { container, service in
        //simulate throwing error when resolving dependency
        throw expectedError
    }
    
    //when
    AssertThrows(expression: try container.resolve() as Service) { error in
      switch error {
      case let DipError.DefinitionNotFound(key) where key == failedKey: return true
      default: return false
      }
    }
    
    //and when
    AssertThrows(expression: try container.resolve(Service.self)) { error in
      switch error {
      case let DipError.DefinitionNotFound(key) where key == failedKey: return true
      default: return false
      }
    }
  }

  func testThatItCallsDidResolveDependenciesOnResolvableIntance() {
    
    class ResolvableService: Service, Resolvable {
      var didResolveDependenciesCalled = false
      
      func didResolveDependencies() {
        XCTAssertFalse(didResolveDependenciesCalled, "didResolveDependencies should be called only once per instance")
        didResolveDependenciesCalled = true
      }
    }
    
    container.register { ResolvableService() as Service }
      .resolveDependencies { _, service in
        XCTAssertFalse((service as! ResolvableService).didResolveDependenciesCalled, "didResolveDependencies should not be called yet")
        return
    }

    container.register(tag: "graph", .ObjectGraph) { ResolvableService() as Service }
      .resolveDependencies { _, service in
        XCTAssertFalse((service as! ResolvableService).didResolveDependenciesCalled)
        return
    }

    container.register(tag: "singleton", .Singleton) { ResolvableService() as Service }
      .resolveDependencies { _, service in
        XCTAssertFalse((service as! ResolvableService).didResolveDependenciesCalled)
        return
    }

    let service = try! container.resolve() as Service
    XCTAssertTrue((service as! ResolvableService).didResolveDependenciesCalled)

    let graphService = try! container.resolve(tag: "graph") as Service
    XCTAssertTrue((graphService as! ResolvableService).didResolveDependenciesCalled)
    
    let singletonService = try! container.resolve(tag: "singleton") as Service
    let _ = try! container.resolve(tag: "singleton") as Service
    XCTAssertTrue((singletonService as! ResolvableService).didResolveDependenciesCalled)
  }
  
  func testThatItCallsDidResolveDependenciesInReverseOrder() {
    
    class ResolvableService: Service, Resolvable {
      static var resolved: [Service] = []
      
      func didResolveDependencies() {
        ResolvableService.resolved.append(self)
      }
    }
    
    var resolveDependenciesCalled = false
    var service2: Service!
    container.register { ResolvableService() as Service }
      .resolveDependencies { _, service in
        if !resolveDependenciesCalled {
          resolveDependenciesCalled = true
          service2 = try! self.container.resolve() as Service
        }
        return
    }

    let service1 = try! container.resolve() as Service
    
    XCTAssertTrue(ResolvableService.resolved.first === service2)
    XCTAssertTrue(ResolvableService.resolved.last === service1)
  }
  
  func testThatItResolvesCircularDependencies() {
    
    class ResolvableServer: Server, Resolvable {
      weak var client: Client?
      weak var secondClient: Client?
      
      init(client: Client) {
        self.client = client
      }
      
      var didResolveDependenciesCalled = false
      
      func didResolveDependencies() {
        XCTAssertFalse(didResolveDependenciesCalled, "didResolveDependencies should be called only once per instance")
        didResolveDependenciesCalled = true

        XCTAssertNotNil(self.client)
        XCTAssertNotNil(self.secondClient)
        XCTAssertNotNil(self.client?.server)
        XCTAssertNotNil(self.secondClient)
        XCTAssertNotNil(self.secondClient?.server)
      }
      
    }
    
    class ResolvableClient: Client, Resolvable {
      var server: Server?
      var secondServer: Server?
      
      init() {}
      
      var didResolveDependenciesCalled = false
      
      func didResolveDependencies() {
        XCTAssertFalse(didResolveDependenciesCalled, "didResolveDependencies should be called only once per instance")
        didResolveDependenciesCalled = true

        XCTAssertNotNil(self.server)
        XCTAssertNotNil(self.secondServer)
        XCTAssertNotNil(self.server?.client)
        XCTAssertNotNil(self.secondServer?.client)
      }
      
    }

    container.register(.ObjectGraph) { try ResolvableServer(client: self.container.resolve()) as Server }
      .resolveDependencies { (container: DependencyContainer, server: Server) in
        let server = server as! ResolvableServer
        server.secondClient = try container.resolve() as Client
    }
    
    container.register(.ObjectGraph) { ResolvableClient() as Client }
      .resolveDependencies { (container: DependencyContainer, client: Client) in
        let client = client as! ResolvableClient
        client.server = try container.resolve() as Server
        client.secondServer = try container.resolve() as Server
    }

    let client = (try! container.resolve() as Client) as! ResolvableClient
    let server = client.server as! ResolvableServer
    let secondServer = client.secondServer as! ResolvableServer
    let secondClient = server.secondClient as! ResolvableClient
    
    XCTAssertTrue(client === server.client)
    XCTAssertTrue(client === server.secondClient)
    XCTAssertTrue(client === secondServer.client)
    XCTAssertTrue(client === secondServer.secondClient)
    XCTAssertTrue(client === secondClient)
    XCTAssertTrue(server === secondServer)
    
    XCTAssertTrue(client.didResolveDependenciesCalled)
    XCTAssertTrue(server.didResolveDependenciesCalled)
  }
  
}
