import Foundation

public protocol Service: class {}

public class ServiceImp1: Service {
  public init() {}
}
public class ServiceImp2: Service {
  public init() {}
}
public class ServiceImp3: Service {
    public init() {}
}

public class ServiceImp4: Service {
  
  public let name: String
  
  public init(name: String, baseURL: NSURL, port: Int) {
    self.name = name
  }
  
}

public protocol Client: class {
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

public class ClientServiceImp: Service {
    public weak var client: Client?
    public init() {}
}

public protocol Logger {}
public protocol Tracker {}
public protocol DataProvider {}
public protocol Router {}

public class LoggerImp: Logger {
    public init() {}
}

public class TrackerImp: Tracker {
    public init() {}
}

public class RouterImp: Router {
    public init() {}
}

public class DataProviderImp: DataProvider {
    public init() {}
}

public protocol ListInteractorOutput: class {}
public protocol ListModuleInterface: class {}
public protocol ListInteractorInput: class {}
public class ListPresenter: NSObject {
    public var listInteractor : ListInteractorInput?
    public var listWireframe : ListWireframe?
    public override init() {}
}
public class ListInteractor: NSObject {
    public var output : ListInteractorOutput?
    public override init() {}
}

public class ListWireframe : NSObject {
    public let addWireframe: AddWireframe
    public let listPresenter: ListPresenter
    public init(addWireFrame: AddWireframe, listPresenter: ListPresenter) {
        self.addWireframe = addWireFrame
        self.listPresenter = listPresenter
    }
}

public protocol AddModuleDelegate: class {}
public protocol AddModuleInterface: class {}
public class AddWireframe: NSObject {
    let addPresenter : AddPresenter
    public init(addPresenter: AddPresenter) {
        self.addPresenter = addPresenter
    }
}
public class AddPresenter: NSObject {
    public var addModuleDelegate : AddModuleDelegate?
    public override init() {}
}
