import Foundation
import Network

class UDPStreamer {
    private var connection: NWConnection?
    private let maxPacketSize = 1400
    private let throttleDelay: UInt32 = 1
    private var streamId: UInt8 = 2
    private var frameCounter: UInt32 = 0
    
    init(host: String, port: UInt16) {
        let endpoint = NWEndpoint.Host(host)
        let port = NWEndpoint.Port(rawValue: port)!
        let parameters = NWParameters.udp
        
        connection = NWConnection(host: endpoint, port: port, using: parameters)
        
        connection?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("Connection ready")
            case .failed(let error):
                print("Connection failed with error: \(error)")
            default:
                break
            }
        }
        
        connection?.start(queue: .global(qos: .background))
    }
    
    func send(data: Data) {
        frameCounter &+= 1 // wraps around on overflow
        let frameId = frameCounter
        let totalChunks = UInt16((data.count + maxPacketSize - 1) / maxPacketSize)
        var offset = 0
        var chunkIndex: UInt16 = 0
        
        while offset < data.count {
            let chunkSize = min(maxPacketSize, data.count - offset)
            let chunk = data.subdata(in: offset..<(offset + chunkSize))
            var packet = Data()
            packet.append(contentsOf: withUnsafeBytes(of: frameId.bigEndian, Array.init))
            packet.append(contentsOf: withUnsafeBytes(of: chunkIndex.bigEndian, Array.init))
            packet.append(contentsOf: withUnsafeBytes(of: totalChunks.bigEndian, Array.init))
            packet.append(streamId)
            packet.append(chunk)
            
            sendChunk(packet)
            offset += chunkSize
            chunkIndex += 1
            usleep(throttleDelay)
        }
    }
    
    private func sendChunk(_ chunk: Data) {
        connection?.send(content: chunk, completion: .contentProcessed { error in
            if let error = error {
                print("Send failed: \(error)")
            }
        })
    }
    
    deinit {
        connection?.cancel()
    }
}
