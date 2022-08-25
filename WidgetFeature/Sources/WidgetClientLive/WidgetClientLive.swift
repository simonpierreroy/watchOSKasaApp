import DeviceClientLive
import DeviceClient
import UserClientLive
import UserClient
import WidgetClient
import RoutingClientLive
import RoutingClient
import Foundation

public extension WidgetEnvironment {
    static let live = Self(
        loadDevices: DevicesEnvironment.liveloadBlockingCache,
        loadUser: UserEnvironment.liveLoadBlockingUser,
        getURL: { deviceLink in
            do {
                return try URLRouter.live.print(deviceLink)
            } catch {
                return URL(string: "urlWidgetDeepLinkIssue")!
            }
        }
    )
}
