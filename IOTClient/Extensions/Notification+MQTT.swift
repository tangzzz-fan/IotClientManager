import Foundation

extension Notification.Name {
    static let mqttNewMessage = Notification.Name("kMQTTNewMessageNotification")
    static let refreshMessageHome = Notification.Name("toRefreshMessageHome")
    static let deviceStatusDidUpdate = Notification.Name("deviceStatusDidUpdate")
    static let connectivityStatusChanged = Notification.Name("connectivityStatusChanged")
}
