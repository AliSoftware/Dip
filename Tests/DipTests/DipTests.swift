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
  weak var client: Client! { get }
}
private protocol Client: class {
  var server: Server! { get }
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

  static var allTests = {
    return [
      ("testThatCreatingContainerWithConfigBlockDoesNotCreateRetainCycle", testThatCreatingContainerWithConfigBlockDoesNotCreateRetainCycle),
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
      ("testItCallsResolveDependenciesOnResolableInstance", testItCallsResolveDependenciesOnResolableInstance),
      ("testThatItResolvesCircularDependencies", testThatItResolvesCircularDependencies),
      ("testThatItCanResolveUsingContainersCollaboration", testThatItCanResolveUsingContainersCollaboration),
      ("testThatCollaboratingWithSelfIsIgnored", testThatCollaboratingWithSelfIsIgnored),
      ("testThatCollaboratingContainersAreWeakReferences", testThatCollaboratingContainersAreWeakReferences),
      ("testThatCollaboratingContainersReuseInstancesResolvedByAnotherContainer", testThatCollaboratingContainersReuseInstancesResolvedByAnotherContainer),
    ]
  }()

  override func setUp() {
    container.reset()
  }
  
  func testThatCreatingContainerWithConfigBlockDoesNotCreateRetainCycle() {
    var container: DependencyContainer! = DependencyContainer() { container in
      //compiler crashes if you try to capture container in capture list
      //so instead we capture it in a variable
      unowned let container = container
      
      container.register { ServiceImp1() }
      container.register { (_: ServiceImp1)->Service in
        //referencing container in factory
        let _ = container
        return ServiceImp1() as Service
        }.resolvingProperties { container, _ in
          //when container is passed as argument there will be no retain cycle
          let _ = container
      }
    }
    
    let _ = try! container.resolve() as Service

    weak var weakContainer = container
    container = nil
    
    XCTAssertNil(weakContainer)
  }

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
    container.register { ServiceImp1() as Service }.resolvingProperties { (c, s) in
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
      guard case let DipError.definitionNotFound(key) = error else { return false }
      
      //then
      let expectedKey = DefinitionKey(type: Service.self, typeOfArguments: Void.self, tag: nil)
      XCTAssertEqual(key, expectedKey)

      return true
    }

    //and when
    AssertThrows(expression: try container.resolve(Service.self)) { error in
      guard case let DipError.definitionNotFound(key) = error else { return false }
      
      //then
      let expectedKey = DefinitionKey(type: Service.self, typeOfArguments: Void.self, tag: nil)
      XCTAssertEqual(key, expectedKey)
      
      return true
    }
  }
  
  func testThatItThrowsErrorIfCanNotFindDefinitionForTag() {
    //given
    container.register(tag: "some tag") { ServiceImp1() as Service }
    
    //when
    AssertThrows(expression: try container.resolve(tag: "other tag") as Service) { error in
      guard case let DipError.definitionNotFound(key) = error else { return false }
      
      //then
      let expectedKey = DefinitionKey(type: Service.self, typeOfArguments: Void.self, tag: "other tag")
      XCTAssertEqual(key, expectedKey)
      
      return true
    }

    //and when
    AssertThrows(expression: try container.resolve(Service.self, tag: "other tag")) { error in
      guard case let DipError.definitionNotFound(key) = error else { return false }
      
      //then
      let expectedKey = DefinitionKey(type: Service.self, typeOfArguments: Void.self, tag: "other tag")
      XCTAssertEqual(key, expectedKey)
      
      return true
    }
  }
  
  func testThatItThrowsErrorIfCanNotFindDefinitionForFactoryWithArguments() {
    //given
    container.register { ServiceImp1() as Service }
    
    //when
    AssertThrows(expression: try container.resolve(arguments: "some string") as Service) { error in
      guard case let DipError.definitionNotFound(key) = error else { return false }
      
      //then
      let expectedKey = DefinitionKey(type: Service.self, typeOfArguments: String.self, tag: nil)
      XCTAssertEqual(key, expectedKey)

      return true
    }

    //and when
    AssertThrows(expression: try container.resolve(Service.self, arguments: "some string")) { error in
      guard case let DipError.definitionNotFound(key) = error else { return false }
      
      //then
      let expectedKey = DefinitionKey(type: Service.self, typeOfArguments: String.self, tag: nil)
      XCTAssertEqual(key, expectedKey)
      
      return true
    }
  }
  
  func testThatItThrowsErrorIfConstructorThrows() {
    //given
    let failedKey = DefinitionKey(type: Any.self, typeOfArguments: Any.self)
    let expectedError = DipError.definitionNotFound(key: failedKey)
    container.register { () throws -> Service in throw expectedError }
    
    //when
    AssertThrows(expression: try container.resolve() as Service) { error in
      switch error {
      case let DipError.definitionNotFound(key) where key == failedKey: return true
      default: return false
      }
    }
    
    //and when
    AssertThrows(expression: try container.resolve(Service.self)) { error in
      switch error {
      case let DipError.definitionNotFound(key) where key == failedKey: return true
      default: return false
      }
    }
  }
  
  func testThatItThrowsErrorIfFailsToResolveDependency() {
    //given
    let failedKey = DefinitionKey(type: Any.self, typeOfArguments: Any.self)
    let expectedError = DipError.definitionNotFound(key: failedKey)
    container.register { ServiceImp1() as Service }
      .resolvingProperties { container, service in
        //simulate throwing error when resolving dependency
        throw expectedError
    }
    
    //when
    AssertThrows(expression: try container.resolve() as Service) { error in
      switch error {
      case let DipError.definitionNotFound(key) where key == failedKey: return true
      default: return false
      }
    }
    
    //and when
    AssertThrows(expression: try container.resolve(Service.self)) { error in
      switch error {
      case let DipError.definitionNotFound(key) where key == failedKey: return true
      default: return false
      }
    }
  }

  func testThatItCallsDidResolveDependenciesOnResolvableIntance() {
    //given
    container.register { ResolvableService() as Service }
      .resolvingProperties { _, service in
        XCTAssertFalse((service as! ResolvableService).didResolveDependenciesCalled, "didResolveDependencies should not be called yet")
        return
    }

    container.register(tag: "graph") { ResolvableService() as Service }
      .resolvingProperties { _, service in
        XCTAssertFalse((service as! ResolvableService).didResolveDependenciesCalled, "didResolveDependencies should not be called yet")
        return
    }

    container.register(.singleton, tag: "singleton") { ResolvableService() as Service }
      .resolvingProperties { _, service in
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
      .resolvingProperties { _, service in
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
  
  func testItCallsResolveDependenciesOnResolableInstance() {
    
    class Class: Resolvable {
      var resolveDependenciesCalled = false
      
      func resolveDependencies(_ container: DependencyContainer) {
        resolveDependenciesCalled = true
      }
    }
    
    class SubClass: Class {
      override func resolveDependencies(_ container: DependencyContainer) {
        super.resolveDependencies(container)
      }
    }
    
    container.register { Class() }
      .resolvingProperties { _, instance in
        XCTAssertTrue(instance.resolveDependenciesCalled)
    }
    
    container.register { SubClass() }
      .resolvingProperties { _, instance in
        XCTAssertTrue(instance.resolveDependenciesCalled)
    }
    
    let _ = try! container.resolve() as Class
    let _ = try! container.resolve() as SubClass
  }
  
  func testThatItResolvesCircularDependencies() {
    
    class ResolvableServer: Server, Resolvable {
      weak var client: Client!
      weak var secondClient: Client!
      
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
      var server: Server!
      var secondServer: Server!
      
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
    container.register { try ResolvableServer(client: self.container.resolve()) as Server }
      .resolvingProperties { (container: DependencyContainer, server: Server) in
        let server = server as! ResolvableServer
        server.secondClient = try container.resolve() as Client
    }
    
    container.register { ResolvableClient() as Client }
      .resolvingProperties { (container: DependencyContainer, client: Client) in
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
    
    container.register { ServiceImp1() }
      .resolvingProperties { container, _ in
        if container.context.resolvingType == ServiceImp1.self {
          createdService1 = true
        }
        if container.context.resolvingType == Service.self {
          createdService = true
        }
      }.implements(Service.self)
    
    container.register(tag: "tag") { ServiceImp2() as Service }
      .resolvingProperties { _ in
        createdService2 = true
    }
    
    container.register { (arg: String) in ServiceImp1() }
      .resolvingProperties { _ in
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
    enum SomeError: Error { case error }
    
    container.register { () -> Service in
      throw SomeError.error
    }
    
    //then
    AssertNoThrow(expression: try container.validate())
    
    //given
    let key = DefinitionKey(type: Service.self, typeOfArguments: Void.self, tag: nil)
    container.register { () -> Service in
      throw DipError.definitionNotFound(key: key)
    }
    
    //then
    AssertThrows(expression: try container.validate()) { error in
      if case let DipError.definitionNotFound(_key) = error, _key == key { return true }
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
      weak var client: Client!
      init(client: Client) { self.client = client }
    }
    
    class ClientImp: Client {
      var server: Server!
      var anotherServer: Server!
    }
    
    let serverContainer = DependencyContainer()
    serverContainer.register { ServerImp(client: $0) as Server }

    let clientContainer = DependencyContainer()
    clientContainer.register { ClientImp() as Client }
      .resolvingProperties { container, client in
        let client = client as! ClientImp
        client.server = try container.resolve() as Server
        client.anotherServer = try container.resolve() as Server
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
