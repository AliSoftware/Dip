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
  var client: Client! { get }
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
  }

  func testThatItThrowsErrorIfCanNotFindDefinitionForType() {
    //given
    container.register { ServiceImp1() as ServiceImp1 }
    
    //when
    XCTAssertThrowsError(try self.container.resolve() as Service) { error in
      guard case let DipError.definitionNotFound(key) = error else {
        XCTFail("Thrown unexpected error: \(error)")
        return
      }
      
      //then
      let expectedKey = DefinitionKey(type: Service.self, typeOfArguments: Void.self, tag: nil)
      XCTAssertEqual(key, expectedKey)
    }

    //and when
    XCTAssertThrowsError(try self.container.resolve(Service.self)) { error in
      guard case let DipError.definitionNotFound(key) = error else {
        XCTFail("Thrown unexpected error: \(error)")
        return
      }
      
      //then
      let expectedKey = DefinitionKey(type: Service.self, typeOfArguments: Void.self, tag: nil)
      XCTAssertEqual(key, expectedKey)
    }
  }
  
  func testThatItThrowsErrorIfCanNotFindDefinitionForTag() {
    //given
    container.register(tag: "some tag") { ServiceImp1() as Service }
    
    //when
    XCTAssertThrowsError(try self.container.resolve(tag: "other tag") as Service) { error in
      guard case let DipError.definitionNotFound(key) = error  else {
        XCTFail("Thrown unexpected error: \(error)")
        return
      }
      
      //then
      let expectedKey = DefinitionKey(type: Service.self, typeOfArguments: Void.self, tag: "other tag")
      XCTAssertEqual(key, expectedKey)
    }

    //and when
    XCTAssertThrowsError(try self.container.resolve(Service.self, tag: "other tag")) { error in
      guard case let DipError.definitionNotFound(key) = error else {
        XCTFail("Thrown unexpected error: \(error)")
        return
      }
      
      //then
      let expectedKey = DefinitionKey(type: Service.self, typeOfArguments: Void.self, tag: "other tag")
      XCTAssertEqual(key, expectedKey)
    }
  }
  
  func testThatItThrowsErrorIfCanNotFindDefinitionForFactoryWithArguments() {
    //given
    container.register { ServiceImp1() as Service }
    
    //when
    XCTAssertThrowsError(try self.container.resolve(arguments: "some string") as Service) { error in
      guard case let DipError.definitionNotFound(key) = error else {
        XCTFail("Thrown unexpected error: \(error)")
        return
      }
      
      //then
      let expectedKey = DefinitionKey(type: Service.self, typeOfArguments: String.self, tag: nil)
      XCTAssertEqual(key, expectedKey)
    }

    //and when
    XCTAssertThrowsError(try self.container.resolve(Service.self, arguments: "some string")) { error in
      guard case let DipError.definitionNotFound(key) = error else {
        XCTFail("Thrown unexpected error: \(error)")
        return
      }
      
      //then
      let expectedKey = DefinitionKey(type: Service.self, typeOfArguments: String.self, tag: nil)
      XCTAssertEqual(key, expectedKey)
    }
  }
  
  func testThatItThrowsErrorIfConstructorThrows() {
    //given
    let failedKey = DefinitionKey(type: Any.self, typeOfArguments: Any.self)
    let expectedError = DipError.definitionNotFound(key: failedKey)
    container.register { () throws -> Service in throw expectedError }
    
    //when
    XCTAssertThrowsError(try self.container.resolve() as Service) { error in
      guard case let DipError.definitionNotFound(key) = error, key == failedKey else {
        XCTFail("Thrown unexpected error: \(error)")
        return
      }
    }
    
    //and when
    XCTAssertThrowsError(try self.container.resolve(Service.self)) { error in
      guard case let DipError.definitionNotFound(key) = error, key == failedKey else {
        XCTFail("Thrown unexpected error: \(error)")
        return
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
    XCTAssertThrowsError(try self.container.resolve() as Service) { error in
      guard case let DipError.definitionNotFound(key) = error, key == failedKey else {
        XCTFail("Thrown unexpected error: \(error)")
        return
      }
    }
    
    //and when
    XCTAssertThrowsError(try self.container.resolve(Service.self)) { error in
      guard case let DipError.definitionNotFound(key) = error, key == failedKey else {
        XCTFail("Thrown unexpected error: \(error)")
        return
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
      .resolvingProperty(\ResolvableServer.secondClient, as: Client.self)
    
    container.register { ResolvableClient() as Client }
      .resolvingProperty(\ResolvableClient.server, factory: { try $0.resolve() })
      .resolvingProperty(\ResolvableClient.secondServer)

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
      .resolvingProperties { _,_  in
        createdService2 = true
    }
    
    container.register { (arg: String) in ServiceImp1() }
      .resolvingProperties { _,_  in
        createdService3 = true
    }
    
    //then
    XCTAssertNoThrow(try self.container.validate("arg"))
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
    XCTAssertNoThrow(
      try self.container.validate(
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
    XCTAssertThrowsError(try self.container.validate()) { error in
      guard error is DipError else {
        XCTFail("Thrown unexpected error: \(error)")
        return
      }
    }
    XCTAssertThrowsError(try self.container.validate("1")) { error in
      guard error is DipError else {
        XCTFail("Thrown unexpected error: \(error)")
        return
      }
    }
  }
  
  func testThatItFailsValidationOnlyForDipErrors() {
    //given
    enum SomeError: Error { case error }
    
    container.register { () -> Service in
      throw SomeError.error
    }
    
    //then
    XCTAssertNoThrow(try self.container.validate())
    
    //given
    let key = DefinitionKey(type: Service.self, typeOfArguments: Void.self, tag: nil)
    container.register { () -> Service in
      throw DipError.definitionNotFound(key: key)
    }
    
    //then
    XCTAssertThrowsError(try self.container.validate()) { error in
      guard case let DipError.definitionNotFound(_key) = error, _key == key else {
        XCTFail("Thrown unexpected error: \(error)")
        return
      }
    }
  }
  
}

extension DipTests {

  func testThatItCanResolveUsingContainersCollaboration() {
    //given
    let collaborator = DependencyContainer()
    collaborator.register { ResolvableService() as Service }
    container.register { "something" }

    //when
    container.collaborate(with: collaborator)
    
    //then
    XCTAssertNoThrow(try self.container.resolve() as Service)
    XCTAssertNoThrow(try self.container.resolve(Service.self))
    XCTAssertNoThrow(try collaborator.resolve() as String)
    XCTAssertNoThrow(try collaborator.resolve(String.self))
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
  
  func testThatCollaborationReferencesAreRecursivelyUpdate() {
    let container = DependencyContainer()
    container.register(.singleton){ ResolvableService() as Service }
    
    //when
    let collaborator1 = DependencyContainer()
    let collaborator2 = DependencyContainer()
    let collaborator3 = DependencyContainer()
    let collaborator4 = DependencyContainer()
    
    collaborator1.collaborate(with: container)
    XCTAssertTrue(collaborator1.resolvedInstances.sharedSingletonsBox === container.resolvedInstances.sharedSingletonsBox)

    collaborator2.collaborate(with: container)
    XCTAssertTrue(collaborator2.resolvedInstances.sharedSingletonsBox === container.resolvedInstances.sharedSingletonsBox)

    collaborator3.collaborate(with: collaborator1)
    XCTAssertTrue(collaborator3.resolvedInstances.sharedSingletonsBox === container.resolvedInstances.sharedSingletonsBox)

    collaborator4.collaborate(with: collaborator2)
    XCTAssertTrue(collaborator4.resolvedInstances.sharedSingletonsBox === container.resolvedInstances.sharedSingletonsBox)
    
    let service1 = try! collaborator1.resolve() as Service
    let service2 = try! collaborator2.resolve() as Service
    let service3 = try! collaborator3.resolve() as Service
    let service4 = try! collaborator4.resolve() as Service
    let serviceRoot = try! container.resolve() as Service
    
    XCTAssertTrue(service1 === service2)
    XCTAssertTrue(service1 === service3)
    XCTAssertTrue(service1 === service4)
    
    XCTAssertTrue(service1 === serviceRoot)
    XCTAssertTrue(service2 === serviceRoot)
    XCTAssertTrue(service3 === serviceRoot)
    XCTAssertTrue(service4 === serviceRoot)
  }

  class RootService {}
  class ServiceClient {
    let name: String
    let service: RootService
    init(name: String, service: RootService) {
      self.name = name
      self.service = service
    }
  }

  func testThatContainersShareTheirSingletonsOnlyWithCollaborators() {
    let container = DependencyContainer()
    container.register(.singleton) { RootService() }
    
    let collaborator1 = DependencyContainer()
    collaborator1.register(.singleton) {
      ServiceClient(name: "1", service: $0)
    }
    
    let collaborator2 = DependencyContainer()
    collaborator2.register(.singleton) {
      ServiceClient(name: "2", service: $0)
    }
    
    collaborator1.collaborate(with: container)
    collaborator2.collaborate(with: container)
    
    let client2 = try! collaborator2.resolve() as ServiceClient
    let client1 = try! collaborator1.resolve() as ServiceClient
    
    XCTAssertEqual(client1.name, "1")
    XCTAssertEqual(client2.name, "2")
    XCTAssertTrue(client1.service === client2.service)
  }

  func testThatContainerAutowireBeforeCollaboration() {
    let container = DependencyContainer()
    container.register(.singleton) { RootService() }
    
    let collaborator1 = DependencyContainer()
    collaborator1.register(.singleton) {
      ServiceClient(name: "1", service: $0)
    }
    
    let collaborator2 = DependencyContainer()
    collaborator2.register(.singleton) {
      ServiceClient(name: "2", service: $0)
    }
    
    collaborator1.collaborate(with: container, collaborator2)
    collaborator2.collaborate(with: container, collaborator1)
    
    let client2 = try! collaborator2.resolve() as ServiceClient
    let client1 = try! collaborator1.resolve() as ServiceClient
    
    XCTAssertEqual(client1.name, "1")
    XCTAssertEqual(client2.name, "2")
    XCTAssertTrue(client1.service === client2.service)
  }
}

class Manager {}
class AnotherManager {}

class Object {
  let manager: Manager?
  
  init(with container: DependencyContainer) {
    self.manager = try? container.resolve()
  }
}

class Owner {
  var manager: Manager?
}

extension DipTests {
  func testThatItCanHandleSeparateContainersAndTheirCollaboration() {
    let container = self.container
    
    let anotherContainer = DependencyContainer()
    anotherContainer.register { Object(with: anotherContainer) }
    
    container.collaborate(with: anotherContainer)
    
    container
      .register { Owner() }
      .resolvingProperties { $1.manager = try $0.resolve() }
    
    container.register(.singleton) { AnotherManager() }
    container.register(.singleton) { Manager() }
    
    let manager: Manager? = try? container.resolve()
    let another: AnotherManager? = try? container.resolve()
    var owner: Owner? = try? container.resolve(arguments: 1, "")
    
    let object: Object? = try? container.resolve()
    owner = try? container.resolve()
    
    let nonNilValues: [Any?] = [another, manager, owner, object, object?.manager]
    nonNilValues.forEach { XCTAssertNotNil($0) }
    
    XCTAssertTrue(
      owner?.manager
        .flatMap { value in
          manager.flatMap { $0 === value }
        }
        ?? false
    )
  }
}

extension DipTests {
  // https://bugs.swift.org/browse/SR-8878
  func test_weak_mirror_regression() {
    class A {
      static var released = false
      deinit {
        A.released = true
      }
    }
    class B {
      static var released = false
      weak var a: A?
      init(a: A) {
        self.a = a
      }
      deinit {
        B.released = true
      }
    }
    let container = DependencyContainer()
    let tag = "my_tag"
    container.register(.unique, tag: tag, factory: B.init(a:))
    do {
      let a0 = A()
      let _: B = try container.resolve(tag: tag, arguments: a0)


      XCTAssertTrue(B.released)
      // Due to regression in swift 4.2 Mirror retains weak children
      // https://bugs.swift.org/browse/SR-8878
      XCTAssertFalse(A.released)
    } catch {
    }
  }
}
