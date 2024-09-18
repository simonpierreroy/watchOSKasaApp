import Combine
import ComposableArchitecture
import DeviceClient
import Foundation
import KasaCore
import Tagged

@Reducer
public struct DeviceReducer: Sendable {

    @Reducer(state: .equatable, .sendable)
    public enum Destination: Sendable {
        case alert(AlertState<Alert>)
        case info(DeviceInfoReducer)
        public enum Alert: Equatable, Sendable {}
    }

    @ObservableState
    public struct State: Equatable, Identifiable, Sendable {

        init(
            isLoading: Bool = false,
            destination: Destination.State? = nil,
            id: Device.Id,
            name: String,
            children: [DeviceChildReducer.State],
            details: Device.State,
            info: DeviceInfoReducer.State? = nil,
            token: Shared<Token?>
        ) {
            self.isLoading = isLoading
            self.id = id
            self.name = name
            self.details = details
            self.children = .init(uniqueElements: children)
            self.destination = destination
            self._token = token
        }

        public var isLoading: Bool
        public let id: Device.Id
        public let name: String
        public var details: Device.State
        public var children: IdentifiedArrayOf<DeviceChildReducer.State>
        @Presents public var destination: Destination.State?
        @Shared public var token: Token?
    }

    public enum Action {
        case toggle
        case setError(Error)
        case didToggle(state: RelayIsOn, info: Device.Info)
        case deviceChild(IdentifiedActionOf<DeviceChildReducer>)
        case destination(PresentationAction<Destination.Action>)
        case presentInfo
    }

    @Dependency(\.devicesClient.toggleDeviceRelayState) var toggleDeviceRelayState

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .toggle:
                guard let token = state.token, state.isLoading == false,
                    case .status(_, let info) = state.details
                else { return .none }
                state.isLoading = true
                return .run { [state] send in
                    let newState = try await toggleDeviceRelayState(token, state.id, nil)
                    await send(.didToggle(state: newState, info: info), animation: .default)
                } catch: { error, send in
                    await send(.setError(error))
                }
            case .didToggle(let relay, let info):
                state.isLoading = false
                state.details = .status(relay: relay, info: info)
                return .none
            case .setError(let error):
                state.isLoading = false
                state.destination = .alert(
                    AlertState(title: { TextState(error.localizedDescription) })
                )
                return .none
            case .deviceChild:  // Child is taking care of it
                return .none
            case .presentInfo:
                guard let info = state.details.info else { return .none }
                state.destination = .info(.init(info: info, deviceName: state.name))
                return .none
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        .forEach(\.children, action: \.deviceChild) {
            DeviceChildReducer()
        }
    }
}

@Reducer
public struct DeviceChildReducer: Sendable {

    public enum Action: Sendable {
        case didToggleChild(relay: RelayIsOn)
        case toggleChild
        case setError(Error)

        case alert(PresentationAction<Alert>)
        public enum Alert: Equatable, Sendable {}

    }

    @ObservableState
    public struct State: Equatable, Identifiable, Sendable {

        public var relay: RelayIsOn
        public let parentId: Device.Id
        public let id: Device.Id
        public var isLoading: Bool = false
        public let name: String
        @Shared public var token: Token?
        @Presents public var alert: AlertState<Action.Alert>?
    }

    @Dependency(\.devicesClient.toggleDeviceRelayState) var toggleDeviceRelayState

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .toggleChild:
                guard let token = state.token, state.isLoading == false else {
                    return .none
                }
                state.isLoading = true
                return .run { [parentId = state.parentId, childId = state.id] send in
                    let relay = try await toggleDeviceRelayState(token, parentId, childId)
                    await send(.didToggleChild(relay: relay), animation: .default)
                } catch: { error, send in
                    await send(.setError(error))
                }
            case .didToggleChild(let status):
                state.isLoading = false
                state.relay = status
                return .none
            case .setError(let error):
                state.isLoading = false
                state.alert = AlertState(title: { TextState(error.localizedDescription) })
                return .none
            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
