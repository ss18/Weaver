/// This file is generated by Weaver
/// DO NOT EDIT!
import Weaver
// MARK: - PersonManager
protocol PersonManagerDependencyResolver {
    var movieAPI: APIProtocol { get }
}
protocol PersonManagerDependencyInjectable {
    init(injecting dependencies: PersonManagerDependencyResolver)
}
extension PersonManager: PersonManagerDependencyInjectable {}