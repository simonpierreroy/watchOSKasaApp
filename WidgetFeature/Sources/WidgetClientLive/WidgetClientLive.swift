import DeviceClientLive
import DeviceClient
import UserClientLive
import UserClient
import WidgetClient

public extension WidgetEnvironment {
    static let liveEnv = Self(
        loadDevices: DevicesEnvironment.liveLoadCache,
        loadUser: UserEnvironment.liveLoadUser
    )
}
