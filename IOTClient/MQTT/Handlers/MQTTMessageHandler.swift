import Foundation

final class MQTTMessageHandler {
    func handle(data: Data, topic: String, retained: Bool) {
        switch topic.prefix(while: { $0 != "/" }) {
        case "w":
            handleWillMessage(data: data, topic: topic)
        case "status":
            handleStatusMessage(data: data, topic: topic)
        case "msg":
            handleNotificationMessage(data: data)
        default:
            break
        }
    }

    private func handleWillMessage(data: Data, topic: String) {
        guard let willMsg = String(data: data, encoding: .utf8) else { return }

        NotificationCenter.default.post(
            name: .mqttNewMessage,
            object: nil,
            userInfo: [
                "topic": topic,
                "lastWill": willMsg,
            ]
        )
    }

    private func handleStatusMessage(data: Data, topic: String) {
        guard let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        var userInfo = dict
        if let currentDeviceId = UserDefaults.standard.string(forKey: "did") {
            userInfo["topic"] = topic
            userInfo["did"] = currentDeviceId
        }

        NotificationCenter.default.post(
            name: .mqttNewMessage,
            object: nil,
            userInfo: userInfo
        )
    }

    private func handleNotificationMessage(data: Data) {
        guard (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) != nil else {
            return
        }
        NotificationCenter.default.post(name: .refreshMessageHome, object: nil)
    }
}
