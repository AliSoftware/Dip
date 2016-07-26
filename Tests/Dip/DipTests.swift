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

private protocol Server: class {
  weak var client: Client? { get }
}
private protocol Client: class {
  var server: Server? { get }
}

class ResolvableService: Service, Resolvable {
  var didResolveDependenciesCalled = false
  
  func didResolveDependencies() {
    XCTAssertFalse(didResolveDependenciesCalled, "didResolveDependencies should be called only once per instance")
    didResolveDependenciesCalled = true
  }
}

class DipTests: XCTestCase {

  let container = DependencyContainer()

  #if os(Linux)
  static var allTests: [(String, DipTests -> () throws -> Void)] {
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
      ("testThatItThrowsErrorIfFailsToResolveDependency", testThatItThrowsErrorIfFailsToResolveDependency),
      ("testThatItCallsDidResolveDependenciesOnResolvableIntance", testThatItCallsDidResolveDependenciesOnResolvableIntance),
      ("testThatItCallsDidResolveDependenciesInReverseOrder", testThatItCallsDidResolveDependenciesInReverseOrder),
      ("testThatItResolvesCircularDependencies", testThatItResolvesCircularDependencies),
      ("testContainerCollaborators", testContainerCollaborators)
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
    
    //and when
    let anyService = try! container.resolve(Service.self)
    
    //then
    XCTAssertTrue(anyService is ServiceImp1)

    //and when
    let optService = try! container.resolve((Service?).self)
    
    //then
    XCTAssertTrue(optService is ServiceImp1)
    
    //and when
    let impService = try! container.resolve((Service!).self)
    
    //then
    XCTAssertTrue(impService is ServiceImp1)
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
    
    //and when
    let optService = try! container.resolve((Service?).self, tag: "service")
    
    //then
    XCTAssertTrue(optService is ServiceImp1)
    
    //and when
    let impService = try! container.resolve((Service!).self, tag: "service")
    
    //then
    XCTAssertTrue(impService is ServiceImp1)
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
    
    //and when
    let anyService1 = try! container.resolve(Service.self, tag: "service1")
    let anyService2 = try! container.resolve(Service.self, tag: "service2")
    
    //then
    XCTAssertTrue(anyService1 is ServiceImp1)
    XCTAssertTrue(anyService2 is ServiceImp2)

    //and when
    let optService1 = try! container.resolve((Service?).self, tag: "service1")
    let optService2 = try! container.resolve((Service?).self, tag: "service2")
    
    //then
    XCTAssertTrue(optService1 is ServiceImp1)
    XCTAssertTrue(optService2 is ServiceImp2)
  
    //and when
    let impService1 = try! container.resolve((Service!).self, tag: "service1")
    let impService2 = try! container.resolve((Service!).self, tag: "service2")
    
    //then
    XCTAssertTrue(impService1 is ServiceImp1)
    XCTAssertTrue(impService2 is ServiceImp2)
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
    let _ = try! container.resolve() as Service
    
    //then
    XCTAssertTrue(resolveDependenciesCalled)
    resolveDependenciesCalled = false
    
    //and when
    let _ = try! container.resolve(Service.self)
    
    //then
    XCTAssertTrue(resolveDependenciesCalled)

    resolveDependenciesCalled = false
    
    //and when
    let _ = try! container.resolve((Service?).self)
    
    //then
    XCTAssertTrue(resolveDependenciesCalled)

    resolveDependenciesCalled = false
    
    //and when
    let _ = try! container.resolve((Service!).self)
    
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
    //given
    container.register { ResolvableService() as Service }
      .resolveDependencies { _, service in
        XCTAssertFalse((service as! ResolvableService).didResolveDependenciesCalled, "didResolveDependencies should not be called yet")
        return
    }

    container.register(tag: "graph", .ObjectGraph) { ResolvableService() as Service }
      .resolveDependencies { _, service in
        XCTAssertFalse((service as! ResolvableService).didResolveDependenciesCalled, "didResolveDependencies should not be called yet")
        return
    }

    container.register(tag: "singleton", .Singleton) { ResolvableService() as Service }
      .resolveDependencies { _, service in
        XCTAssertFalse((service as! ResolvableService).didResolveDependenciesCalled, "didResolveDependencies should not be called yet")
        return
    }

    //when
    let service = try! container.resolve() as Service
    
    //then
    XCTAssertTrue((service as! ResolvableService).didResolveDependenciesCalled)

    //and when
    let graphService = try! container.resolve(tag: "graph") as Service
    
    //then
    XCTAssertTrue((graphService as! ResolvableService).didResolveDependenciesCalled)
    
    //and when
    let singletonService = try! container.resolve(tag: "singleton") as Service
    let _ = try! container.resolve(tag: "singleton") as Service
    
    //then
    XCTAssertTrue((singletonService as! ResolvableService).didResolveDependenciesCalled)
  }
  
  func testThatItCallsDidResolveDependenciesInReverseOrder() {
    
    class ResolvableService: Service, Resolvable {
      static var resolved: [Service] = []
      
      func didResolveDependencies() {
        ResolvableService.resolved.append(self)
      }
    }
    
    //given
    var resolveDependenciesCalled = false
    var service2: Service!
    container.register { ResolvableService() as Service }
      .resolveDependencies { _, service in
        if !resolveDependenciesCalled {
          resolveDependenciesCalled = true
          service2 = try self.container.resolve() as Service
        }
        return
    }

    //when
    let service1 = try! container.resolve() as Service
    
    //then
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
    
    //Due to a bug in Swift 3 Mirror fails if weak property is not NSObject
    //https://bugs.swift.org/browse/SR-2144
    class ResolvableClient: NSObject, Client, Resolvable {
      var server: Server?
      var secondServer: Server?
      
      override init() {
        super.init()
      }
      
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

    //given
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

    //when
    let client = (try! container.resolve() as Client) as! ResolvableClient
    let server = client.server as! ResolvableServer
    let secondServer = client.secondServer as! ResolvableServer
    let secondClient = server.secondClient as! ResolvableClient
    
    //then
    XCTAssertTrue(client === server.client)
    XCTAssertTrue(client === server.secondClient)
    XCTAssertTrue(client === secondServer.client)
    XCTAssertTrue(client === secondServer.secondClient)
    XCTAssertTrue(client === secondClient)
    XCTAssertTrue(server === secondServer)
    
    XCTAssertTrue(client.didResolveDependenciesCalled)
    XCTAssertTrue(server.didResolveDependenciesCalled)
  }
  
  func testThatItValidatesConfiguration() {
    //given
    var createdService1 = false
    var createdService2 = false
    var createdService3 = false
    var createdService = false
    
    let service = container.register { ServiceImp1() }
      .resolveDependencies { container, _ in
        if container.context.resolvingType == ServiceImp1.self {
          createdService1 = true
        }
        if container.context.resolvingType == Service.self {
          createdService = true
        }
    }
    container.register(service, type: Service.self)
    
    container.register(tag: "tag") { ServiceImp2() as Service }
      .resolveDependencies { _ in
        createdService2 = true
    }
    
    container.register() { (arg: String) in ServiceImp1() }
      .resolveDependencies { _ in
        createdService3 = true
    }
    
    //then
    AssertNoThrow(expression: try container.validate("arg"))
    XCTAssertTrue(createdService1)
    XCTAssertTrue(createdService2)
    XCTAssertTrue(createdService3)
    XCTAssertTrue(createdService)
  }
  
  func testThatItPicksRuntimeArgumentsWhenValidatingConfiguration() {
    //given
    let expectedIntArgument = 1
    let expectedStringArgument = "a"
    container.register { (a: Int) -> Service in
      XCTAssertEqual(a, expectedIntArgument)
      return ServiceImp1() as Service
    }
    
    container.register { (a: Int, b: String) -> Service in
      XCTAssertEqual(a, expectedIntArgument)
      XCTAssertEqual(b, expectedStringArgument)
      return ServiceImp1() as Service
    }
    
    //then
    AssertNoThrow(expression:
      try container.validate(
        "1",
        expectedIntArgument,
        "x",
        (expectedStringArgument, expectedIntArgument),
        (expectedIntArgument, expectedStringArgument)
      )
    )
  }
  
  func testThatItFailsValidationIfNoMatchingArgumentsFound() {
    //given
    container.register { (a: Int) -> Service in ServiceImp1() as Service }
    
    //then
    AssertThrows(expression: try container.validate()) { error in error is DipError }
    AssertThrows(expression: try container.validate("1")) { error in error is DipError }
  }
  
  func testThatItFailsValidationOnlyForDipErrors() {
    //given
    container.register { () -> Service in
      throw NSError(domain: "", code: 0, userInfo: nil)
    }
    
    //then
    AssertNoThrow(expression: try container.validate())
    
    //given
    let key = DefinitionKey(protocolType: Service.self, argumentsType: Void.self, associatedTag: nil)
    container.register { () -> Service in
      throw DipError.DefinitionNotFound(key: key)
    }
    
    //then
    AssertThrows(expression: try container.validate()) { error in
      if case let DipError.DefinitionNotFound(_key) = error where _key == key { return true }
      else { return false }
    }
  }
  
}

extension DipTests {

  func testThatItCanResolveUsingContainersCollaboration() {
    //given
    let collaborator = DependencyContainer()
    collaborator.register { ResolvableService() as Service }

    //when
    container.collaborate(with: collaborator)
    
    //then
    AssertNoThrow(expression: try container.resolve() as Service)
    AssertNoThrow(expression: try container.resolve(Service.self))
  }
  
  func testThatCollaboratingWithSelfIsIgnored() {
    let collaborator = DependencyContainer()
    collaborator.collaborate(with: collaborator)
    XCTAssertTrue(collaborator._collaborators.isEmpty, "Container should not collaborate with itself")
    
  }
  
  func testThatCollaboratingContainersAreWeakReferences() {
    //given
    var collaborator: DependencyContainer? = DependencyContainer()
    weak var weakCollaborator = collaborator
    
    //when
    container.collaborate(with: collaborator!)
    collaborator = nil
    
    //then
    XCTAssertNil(weakCollaborator)
  }
  
  func testThatCollaboratingContainersReuseInstancesResolvedByAnotherContainer() {
    //given
    class ServerImp: Server {
      weak var client: Client?
      init(client: Client) { self.client = client }
    }
    
    //Due to a bug in Swift 3 Mirror fails if weak property is not NSObject
    //https://bugs.swift.org/browse/SR-2144
    class ClientImp: NSObject, Client {
      var server: Server?
      var anotherServer: Server?
      override init() {
        super.init()
      }
    }
    
    let serverContainer = DependencyContainer() { container in
      container.register(.ObjectGraph) { ServerImp(client: $0) as Server }
    }
    let clientContainer = DependencyContainer() { container in
      container.register(.ObjectGraph) { ClientImp() as Client }
        .resolveDependencies { container, client in
          let client = client as! ClientImp
          client.server = try container.resolve() as Server
          client.anotherServer = try container.resolve() as Server
      }
    }

    //when
    serverContainer.collaborate(with: clientContainer)
    clientContainer.collaborate(with: serverContainer)
    var client = try? clientContainer.resolve() as Client
    
    //then
    XCTAssertNotNil(client)
    XCTAssertTrue(client === client?.server?.client)
    XCTAssertTrue(client === (client as? ClientImp)?.anotherServer?.client)
    XCTAssertTrue(client?.server === (client as? ClientImp)?.anotherServer)
    
    client = try? serverContainer.resolve() as Client
    
    //then
    XCTAssertNotNil(client)
    XCTAssertTrue(client === client?.server?.client)
    XCTAssertTrue(client === (client as? ClientImp)?.anotherServer?.client)
    XCTAssertTrue(client?.server === (client as? ClientImp)?.anotherServer)
  }
  
}
