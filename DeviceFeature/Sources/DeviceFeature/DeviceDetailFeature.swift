import Combine
import ComposableArchitecture
import DeviceClient
import Foundation
import KasaCore
import Tagged

@Reducer
public struct DeviceReducer {

    @Reducer
    public struct Destination {

        public enum State: Equatable {
            case alert(AlertState<Action.Alert>)
            case info(DeviceInfoReducer.State)
        }

        public enum Action {
            public enum Alert: Equatable {}
            case alert(Alert)
            case info(DeviceInfoReducer.Action)
        }

        public var body: some ReducerOf<Self> {
            Scope(state: \.info, action: \Action.Cases.info) {
                DeviceInfoReducer()
            }
        }
    }

    public struct State: Equatable, Identifiable {

        init(
            isLoading: Bool = false,
            destination: Destination.State? = nil,
            id: Device.Id,
            name: String,
            children: [DeviceChildReducer.State],
            details: Device.State,
            info: DeviceInfoReducer.State? = nil
        ) {
            self.isLoading = isLoading
            self.id = id
            self.name = name
            self.details = details
            self._children = .init(uniqueElements: children)
            self.destination = destination
        }

        public var isLoading: Bool
        public let id: Device.Id
        public let name: String
        public var details: Device.State

        @PresentationState public var destination: Destination.State?

        public var token: Token? = nil

        private var _children: IdentifiedArrayOf<DeviceChildReducer.State>
        public var children: IdentifiedArrayOf<DeviceChildReducer.State> {
            get {
                return .init(
                    uniqueElements: _children.map {
                        var copy = $0
                        copy.token = self.token
                        return copy
                    }
                )
            }
            set { self._children = newValue }
        }
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
        .ifLet(\.$destination, action: \.destination) {
            Destination()
        }
        .forEach(\.children, action: \.deviceChild) {
            DeviceChildReducer()
        }
    }
}

@Reducer
public struct DeviceChildReducer {

    public enum Action {
        case didToggleChild(relay: RelayIsOn)
        case toggleChild
        case setError(Error)

        case alert(PresentationAction<Alert>)
        public enum Alert: Equatable {}

    }

    public struct State: Equatable, Identifiable {

        public var relay: RelayIsOn
        public let parentId: Device.Id
        public let id: Device.Id
        public var isLoading: Bool = false
        public let name: String
        public var token: Token? = nil

        @PresentationState public var alert: AlertState<Action.Alert>?
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
