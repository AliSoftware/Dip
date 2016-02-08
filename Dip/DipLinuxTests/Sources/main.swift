import Glibc
import XCTest
import Dip


private protocol Service: class {
  var client: Client? { get set }
}

private protocol Client: class {
  var service: Service { get }
}

private class ClientImp: Client, Equatable {
  var service: Service
  init(service: Service) {
    self.service = service
  }
}

private func ==<T: ClientImp>(lhs: T, rhs: T) -> Bool {
  return lhs === rhs
}

private class ServiceImp: Service, Hashable {
  weak var client: Client?
  init() {}
  
  var hashValue: Int {
    return unsafeAddressOf(self).hashValue
  }
}

private func ==<T: ServiceImp>(lhs: T, rhs: T) -> Bool {
  return lhs === rhs
}


typealias TMain = @convention(c) (UnsafeMutablePointer<Void>) -> UnsafeMutablePointer<Void>

func dispatch_async(block: TMain) {
  var pid: pthread_t = 0
  pthread_create(&pid, nil, block, nil)
}

func dispatch_sync(block: TMain) -> UnsafeMutablePointer<Void> {
  var pid: pthread_t = 0
  var result: UnsafeMutablePointer<Void> = nil
  pthread_create(&pid, nil, block, nil)
  pthread_join(pid, &result)
  return result
}

private var resolvedServices = Set<ServiceImp>()
private var resolvedClients = Array<ClientImp>()

private var lock: pthread_spinlock_t = 0
pthread_spin_init(&lock, 0)

private var container: DependencyContainer!

class ThreadSafetyTests: XCTestCase {
  
  var allTests: [(String, () throws -> Void)] {
    return [
      ("testSingletonThreadSafety", testSingletonThreadSafety),
      ("testFactoryThreadSafety", testFactoryThreadSafety),
      ("testCircularReferenceThreadSafety", testCircularReferenceThreadSafety)
    ]
  }
  
  func setUp() {
    container = DependencyContainer()
  }
  
  func tearDown() {
  }
  
  func testSingletonThreadSafety() {
    container.register(.Singleton) { ServiceImp() as Service }
    
    for _ in 0..<100 {
      dispatch_async { _ in
        let service = try! container.resolve() as Service
        pthread_spin_lock(&lock)
        resolvedServices.insert(service as! ServiceImp)
        pthread_spin_unlock(&lock)
        return nil
      }
    }
    
    sleep(1)
    XCTAssertEqual(resolvedServices.count, 1, "Should create only one instance")
    resolvedServices.removeAll()
  }
  
  
  func testFactoryThreadSafety() {
    container.register { ServiceImp() as Service }
    
    for _ in 0..<100 {
      dispatch_async { _ in
        let service = try! container.resolve() as Service
        pthread_spin_lock(&lock)
        resolvedServices.insert(service as! ServiceImp)
        pthread_spin_unlock(&lock)
        return nil
      }
    }
    
    sleep(1)
    XCTAssertEqual(resolvedServices.count, 100, "All instances should be different")
    resolvedServices.removeAll()
  }
  
  
  func testCircularReferenceThreadSafety() {
    container.register(.ObjectGraph) { ClientImp(service: try container.resolve()) as Client }
    
    let resolveClient: TMain = { _ in
      let resolved = try! container.resolve() as Client
      return UnsafeMutablePointer(Unmanaged.passUnretained(resolved as! ClientImp).toOpaque())
    }
    container.register(.ObjectGraph) { ServiceImp() as Service }
      .resolveDependencies { container, service in
        var clientPointer: UnsafeMutablePointer<Void> = nil
        clientPointer = dispatch_sync(resolveClient)
        let client = Unmanaged<ClientImp>.fromOpaque(COpaquePointer(clientPointer)).takeUnretainedValue()
        service.client = client
    }
    
    for _ in 0..<100 {
      dispatch_async { _ in
        let client = try! container.resolve() as Client
        pthread_spin_lock(&lock)
        resolvedClients.append(client as! ClientImp)
        pthread_spin_unlock(&lock)
        return nil
      }
    }
    
    sleep(2)
    
    XCTAssertEqual(resolvedClients.count, 100, "Instances should be not reused in different object graphs")
    for client in resolvedClients {
      let service = client.service as! ServiceImp
      let serviceClient = service.client as! ClientImp
      XCTAssertEqual(serviceClient, client, "Instances should be reused when resolving single object graph")
    }
    
    resolvedClients.removeAll()
  }
  
}

XCTMain([ThreadSafetyTests()])
