//
//  FrameHandler.swift
//  CameraMacStreamer
//
//  Created by Christopher Woods on 5/20/25.
//


import AVFoundation
import CoreImage
import UniformTypeIdentifiers

class FrameHandler: NSObject, ObservableObject {
    private let context = CIContext()
    private var videoOutput: AVCaptureVideoDataOutput?
    private var udpStreamer: UDPStreamer?
    private var session: AVCaptureSession?
    private var currentDevice: AVCaptureDevice?

    func startStreaming(from device: AVCaptureDevice?) {
        guard let device = device else { return }
        stopStreaming()

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
            self.udpStreamer = UDPStreamer(host: "127.0.0.1", port: 15001)
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
        guard let cgImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer),
              let imageData = encodeImageToData(cgImage: cgImage) else { return }
        udpStreamer?.send(data: imageData)
    }

    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> CGImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        return context.createCGImage(ciImage, from: ciImage.extent)
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
