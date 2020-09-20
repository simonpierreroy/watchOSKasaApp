//
//  DeviceDetailFeature.swift
//  
//
//  Created by Simon-Pierre Roy on 9/18/20.
//

import Foundation
import ComposableArchitecture
import Combine
import Tagged
import KasaCore
import DeviceClient

public enum DevicesAtion {
    case set(to: [DeviceSate])
    case fetchFromRemote
    case send(Error)
    case errorHandled
    case deviceDetail(index: Int, action: DeviceDetailAction)
    case closeAll
    case doneClosingAll(())
    case empty
}

public struct DevicesState {
    public static let empty = DevicesState(_devices: [], isLoading: .nerverLoaded, error: nil, token: nil)
    
    public enum Loading {
        case nerverLoaded
        case loadingDevices
        case closingAll
        case loaded
        
        var isInFlight: Bool {
            switch self {
            case .loadingDevices, .closingAll:
                return true
            case .loaded, .nerverLoaded:
                return false
            }
        }
    }
    
    private var _devices: [DeviceSate]
    public var devices: [DeviceSate] {
        get {
            _devices.map {
                var copy = $0
                copy.token = self.token
                return copy
            }
        }
        set { self._devices = newValue }
    }
    public var isLoading: Loading
    public var error: Error?
    public var token: Token?
}

extension DeviceSate {
    init(device: Device) {
        self.init(id: device.id, name: device.name)
    }
}

public let devicesReducer = Reducer<DevicesState, DevicesAtion, DevicesEnvironment> { state, action, environment in
    switch action {
    case .set(let devices):
        state.isLoading = .loaded
        state.devices = devices
        return .none
    case .fetchFromRemote:
        guard let token = state.token else { return .none }
        state.isLoading = .loadingDevices
        return environment.loadDevices(token)
            .map(map(DeviceSate.init(device:)))
            .map(DevicesAtion.set)
            .catch(DevicesAtion.send >>> Just.init)
            .receive(on: environment.mainQueue)
            .merge(with: Effect.cancel(id: CancelInFlightToggle()))
            .eraseToEffect()
    case .send(let error):
        state.isLoading = .loaded
        state.error = error
        return .none
    case .errorHandled:
        state.error = nil
        return .none
    case .closeAll:
        guard let token = state.token, state.isLoading != .nerverLoaded else { return .none }
        state.isLoading = .closingAll
        
        func stateInfo(device: DeviceSate) ->  AnyPublisher<(Device.ID, RelayIsOn), Error> {
            return environment.getDevicesState(token , device.id)
                .map { isOn in return (device.id, isOn) }
                .eraseToAnyPublisher()
        }
        
        return Publishers.MergeMany.init(
            state.devices.map(stateInfo)
        ).filter(\.1.rawValue)
        .map { (token, $0.0, false) }
        .flatMap(environment.changeDevicesState)
        .map(always)
        .map(DevicesAtion.doneClosingAll)
        .last()
        .catch(DevicesAtion.send >>> Just.init)
        .replaceEmpty(with: DevicesAtion.doneClosingAll(()))
        .eraseToEffect()
    case .doneClosingAll:
        state.isLoading = .loaded
        return .none
    case .deviceDetail: return .none
    case .empty: return .none
    }
}.combined(with:
            deviceDetailStateReducer.forEach(
                state: \DevicesState.devices,
                action: /DevicesAtion.deviceDetail(index:action:),
                environment: DeviceDetailEvironment.init(devicesEnv:)
            )
)

#if DEBUG
extension DevicesState {
    static let emptyLogged = DevicesState(_devices: [], isLoading: .nerverLoaded, error: nil, token: "logged")
    static let emptyLoading = DevicesState(_devices: [], isLoading: .loadingDevices, error: nil, token: "logged")
    static let emptyNeverLoaded = DevicesState(_devices: [], isLoading: .nerverLoaded, error: nil, token: "logged")
    static let oneDeviceLoaded = DevicesState(_devices: [.init(id: "1", name: "Test 1")], isLoading: .loaded, error: nil, token: "logged")
}
#endif

