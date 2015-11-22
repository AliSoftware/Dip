import Foundation

public protocol Service {}

public class ServiceImp1: Service {
  public init() {}
}
public class ServiceImp2: Service {
  public init() {}
}

public class ServiceImp3: Service {
  
  public let name: String
  
  public init(name: String, baseURL: NSURL, port: Int) {
    self.name = name
  }
  
}

public protocol Client {
  var service: Service {get}
  init(service: Service)
}
public class ClientImp1: Client {
  public var service: Service
  public required init(service: Service) {
    self.service = service
  }
}

public class ClientImp2: Client {
  public var service: Service
  public required init(service: Service) {
    self.service = service
  }
}

public class ServiceFactory {
  public init() {}
  
  public func someService() -> Service {
    return ServiceImp1()
  }
}

