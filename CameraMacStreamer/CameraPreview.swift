import SwiftUI
import AVFoundation

struct CameraPreview: NSViewRepresentable {
    @Binding var device: AVCaptureDevice?

    func makeNSView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.updateDevice(device)
        return view
    }

    func updateNSView(_ nsView: CameraPreviewView, context: Context) {
        nsView.updateDevice(device)
    }
}

class CameraPreviewView: NSView {
    private var session: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var currentDevice: AVCaptureDevice?

    func updateDevice(_ newDevice: AVCaptureDevice?) {
        guard let newDevice = newDevice, newDevice != currentDevice else { return }
        stopSession()
        setupCamera(device: newDevice)
        currentDevice = newDevice
    }

    private func setupCamera(device: AVCaptureDevice) {
        let session = AVCaptureSession()
        session.sessionPreset = .high

        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else { return }
            session.addInput(input)

            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = self.bounds

            self.layer = previewLayer
            self.wantsLayer = true
            self.previewLayer = previewLayer
            self.session = session

            session.startRunning()
        } catch {
            print("Camera setup error: \(error)")
        }
    }

    private func stopSession() {
        session?.stopRunning()
        session = nil
        previewLayer?.removeFromSuperlayer()
        previewLayer = nil
        currentDevice = nil
    }

    override func layout() {
        super.layout()
        previewLayer?.frame = self.bounds
    }
}
