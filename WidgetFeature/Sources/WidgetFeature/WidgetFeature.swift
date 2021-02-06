import Foundation
import WidgetClient
import Combine
import KasaCore

public func getCacheState(environment: WidgetEnvironment) -> AnyPublisher<WidgetState, Error> {
    return environment
        .loadUser
        .mapError(absurd)
        .zip(environment.loadDevices)
        .map(WidgetState.init(user:device:))
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
}


