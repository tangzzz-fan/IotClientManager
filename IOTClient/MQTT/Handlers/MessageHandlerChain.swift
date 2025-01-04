import Foundation

protocol MessageHandler {
    var next: MessageHandler? { get set }
    func handle(data: Data, topic: String, retained: Bool) -> Bool
}

class WillMessageHandler: MessageHandler {
    var next: MessageHandler?

    func handle(data: Data, topic: String, retained: Bool) -> Bool {
        if topic.hasPrefix("w/") {
            guard let willMsg = String(data: data, encoding: .utf8) else { return false }
            NotificationCenter.default.post(
                name: .mqttNewMessage,
                object: nil,
                userInfo: ["topic": topic, "lastWill": willMsg]
            )
            return true
        }
        return next?.handle(data: data, topic: topic, retained: retained) ?? false
    }
}

class StatusMessageHandler: MessageHandler {
    var next: MessageHandler?

    func handle(data: Data, topic: String, retained: Bool) -> Bool {
        if topic.hasPrefix("status/") {
            guard let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return false
            }
            NotificationCenter.default.post(
                name: .deviceStatusDidUpdate,
                object: nil,
                userInfo: dict
            )
            return true
        }
        return next?.handle(data: data, topic: topic, retained: retained) ?? false
    }
}

class NotificationMessageHandler: MessageHandler {
    var next: MessageHandler?

    func handle(data: Data, topic: String, retained: Bool) -> Bool {
        if topic.hasPrefix("msg/") {
            NotificationCenter.default.post(
                name: .refreshMessageHome,
                object: nil,
                userInfo: ["data": data]
            )
            return true
        }
        return next?.handle(data: data, topic: topic, retained: retained) ?? false
    }
}
