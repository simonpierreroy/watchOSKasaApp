import Dependencies
import DeviceClient
import DeviceClientLive
import Foundation
import RoutingClient
import UserClient
import UserClientLive

public struct ProviderConfig {

    public init() {}

    @Dependency(\.userCache.loadBlocking) public var loadUser
    @Dependency(\.devicesCache.loadBlocking) public var loadDevices
    @Dependency(\.urlRouter.print) public var getURL

    public func render(link: AppLink) -> URL {
        do {
            return try getURL(link)
        } catch {
            return URL(string: "urlWidgetDeepLinkIssue")!
        }
    }

}
