import Foundation
import CocoaAsyncSocket

protocol SocketManagerDelegate: AnyObject {
    func socketManagerDidConnect(_ socketManager: SocketManager)
    func socketManagerDidDisconnect(_ socketManager: SocketManager, withError error: Error?)
    func socketManager(_ socketManager: SocketManager, didReceive data: Data)
}

class SocketManager: NSObject {
    static let shared = SocketManager()
    
    weak var delegate: SocketManagerDelegate?
    
    private var tcpSocket: GCDAsyncSocket?
    private var udpSocket: GCDAsyncUdpSocket?
    
    private var isTCPConnected = false
    private var isUDPConnected = false
    
    private override init() {
        super.init()
    }
    
    // MARK: - TCP Socket Methods
    
    func connectToTCPServer(host: String, port: UInt16) throws {
        guard !isTCPConnected else {
            print("Already connected to TCP server")
            return
        }
        
        tcpSocket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
        
        do {
            try tcpSocket?.connect(toHost: host, onPort: port)
            print("Connecting to TCP server at \(host):\(port)")
        } catch {
            throw error
        }
    }
    
    func disconnectFromTCPServer() {
        tcpSocket?.disconnect()
        isTCPConnected = false
    }
    
    func sendTCPData(_ data: Data) {
        guard isTCPConnected, let socket = tcpSocket else {
            print("Not connected to TCP server")
            return
        }
        
        socket.write(data, withTimeout: -1, tag: 0)
    }
    
    // MARK: - UDP Socket Methods
    
    func setupUDPSocket() throws {
        guard udpSocket == nil else {
            print("UDP socket already setup")
            return
        }
        
        udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.main)
        
        do {
            try udpSocket?.bind(toPort: 0) // 绑定到任意可用端口
            try udpSocket?.beginReceiving()
            print("UDP socket setup complete")
        } catch {
            throw error
        }
    }
    
    func sendUDPData(_ data: Data, toHost host: String, port: UInt16) {
        guard let socket = udpSocket else {
            print("UDP socket not setup")
            return
        }
        
        socket.send(data, toHost: host, port: port, withTimeout: -1, tag: 0)
    }
    
    func closeUDPSocket() {
        udpSocket?.close()
        udpSocket = nil
    }
    
    // MARK: - Connection Status
    
    func isTCPConnectedToServer() -> Bool {
        return isTCPConnected
    }
    
    func getLocalUDPPort() -> UInt16? {
        return udpSocket?.localPort()
    }
}

// MARK: - GCDAsyncSocketDelegate (TCP)

extension SocketManager: GCDAsyncSocketDelegate {
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("Connected to TCP server at \(host):\(port)")
        isTCPConnected = true
        delegate?.socketManagerDidConnect(self)
        
        // 开始读取数据
        sock.readData(withTimeout: -1, tag: 0)
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("Disconnected from TCP server")
        isTCPConnected = false
        delegate?.socketManagerDidDisconnect(self, withError: err)
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        print("Received TCP data: \(data.count) bytes")
        delegate?.socketManager(self, didReceive: data)
        
        // 继续读取更多数据
        sock.readData(withTimeout: -1, tag: 0)
    }
    
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        print("Successfully wrote TCP data")
    }
}

// MARK: - GCDAsyncUdpSocketDelegate (UDP)

extension SocketManager: GCDAsyncUdpSocketDelegate {
    func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
        print("Connected to UDP address")
        isUDPConnected = true
        delegate?.socketManagerDidConnect(self)
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: Error?) {
        print("Failed to connect to UDP address: \(String(describing: error))")
        isUDPConnected = false
        delegate?.socketManagerDidDisconnect(self, withError: error)
    }
    
    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        print("UDP socket closed: \(String(describing: error))")
        isUDPConnected = false
        delegate?.socketManagerDidDisconnect(self, withError: error)
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        print("Received UDP data: \(data.count) bytes")
        delegate?.socketManager(self, didReceive: data)
    }
}