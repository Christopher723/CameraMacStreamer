import AVFoundation
import CoreImage
import UniformTypeIdentifiers
import Foundation
import Network

class FrameHandler: NSObject, ObservableObject {
    private let context = CIContext()
    private var videoOutput: AVCaptureVideoDataOutput?
    private var udpStreamer: UDPStreamer?
    private var session: AVCaptureSession?
    private var currentDevice: AVCaptureDevice?
    @Published var targetIP: String = ""
    @Published var targetPort: String = "15001"
    @Published var useTopHalfOnly: Bool = false
    @Published var mirrorVideo: Bool = false


    func startStreaming(from device: AVCaptureDevice?) {
        guard let device = device else { return }
        stopStreaming()
        guard !targetIP.isEmpty, let port = UInt16(targetPort) else {
            print("No target IP or port set")
            return
        }

        let session = AVCaptureSession()
        session.sessionPreset = .high

        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else { return }
            session.addInput(input)

            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
            guard session.canAddOutput(output) else { return }
            session.addOutput(output)

            self.session = session
            self.videoOutput = output
            self.currentDevice = device
            self.udpStreamer = UDPStreamer(host: targetIP, port: port)
            session.startRunning()
        } catch {
            print("FrameHandler camera error: \(error)")
        }
    }

    func stopStreaming() {
        session?.stopRunning()
        session = nil
        videoOutput = nil
        currentDevice = nil
        udpStreamer = nil
    }
}

extension FrameHandler: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let cgImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer, useTopHalfOnly: useTopHalfOnly),
              let imageData = encodeImageToData(cgImage: cgImage) else { return }
        udpStreamer?.send(data: imageData)
    }

    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer, useTopHalfOnly: Bool = false) -> CGImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        var ciImage = CIImage(cvPixelBuffer: imageBuffer)
        
    
        if mirrorVideo {
            let transform = CGAffineTransform(scaleX: -1, y: 1)
            ciImage = ciImage.transformed(by: transform)
        }
        
        guard let fullCGImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        if !useTopHalfOnly {
            return fullCGImage
        }
        
        let width = fullCGImage.width
        let height = fullCGImage.height / 2
        let cropRect = CGRect(x: 0, y: 0, width: width, height: height)
        return fullCGImage.cropping(to: cropRect)
    }


    private func encodeImageToData(cgImage: CGImage) -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else {
            return nil
        }
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.0
        ]
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        return CGImageDestinationFinalize(destination) ? (data as Data) : nil
    }
}

