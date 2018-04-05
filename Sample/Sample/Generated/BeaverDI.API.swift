/// This file is generated by BeaverDI
/// DO NOT EDIT!

import BeaverDI

// MARK: - MovieAPI

final class MovieAPIDependencyContainer: DependencyContainer {

    init(_ parent: DependencyContainer) {
        super.init(parent)
    }

    override func registerDependencies(in store: DependencyStore) {
        
    }
}

protocol MovieAPIDependencyResolver {
    
    var urlSession: URLSession { get }
    
}

extension MovieAPIDependencyContainer: MovieAPIDependencyResolver {
    
    var urlSession: URLSession {
        return resolve(URLSession.self)
    }
}

extension MovieAPI {

    static func makeMovieAPI(injecting parentDependencies: DependencyContainer) -> MovieAPI {
        let dependencies = MovieAPIDependencyContainer(parentDependencies)
        return MovieAPI(injecting: dependencies)
    }
}

protocol MovieAPIDependencyInjectable {
    init(injecting dependencies: MovieAPIDependencyResolver)
}

extension MovieAPI: MovieAPIDependencyInjectable {}
