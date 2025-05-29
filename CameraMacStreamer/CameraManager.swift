import AVFoundation
import Combine

class CameraManager: ObservableObject {
    @Published var availableCameras: [AVCaptureDevice] = []
    @Published var selectedCamera: AVCaptureDevice? {
        didSet { updateAvailableFormats() }
    }
    @Published var availableFormats: [AVCaptureDevice.Format] = []
    @Published var selectedFormat: AVCaptureDevice.Format?

    func fetchCameras() {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.externalUnknown, .builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        )
        DispatchQueue.main.async {
            self.availableCameras = discoverySession.devices
            if self.selectedCamera == nil, let first = discoverySession.devices.first {
                self.selectedCamera = first
            }
        }
    }

    func updateAvailableFormats() {
        if let device = selectedCamera {
            availableFormats = device.formats
            selectedFormat = device.activeFormat
        } else {
            availableFormats = []
            selectedFormat = nil
        }
    }

    func setResolution(format: AVCaptureDevice.Format) {
        guard let device = selectedCamera else { return }
        do {
            try device.lockForConfiguration()
            device.activeFormat = format
            device.unlockForConfiguration()
            DispatchQueue.main.async {
                self.selectedFormat = format
            }
        } catch {
            print("Failed to set format: \(error)")
        }
    }

    // Helper to show resolution string
    func resolutionString(for format: AVCaptureDevice.Format) -> String {
        let desc = format.formatDescription
        let dims = CMVideoFormatDescriptionGetDimensions(desc)
        let frameRates = format.videoSupportedFrameRateRanges
        let minRate = frameRates.first?.minFrameRate ?? 0
        let maxRate = frameRates.first?.maxFrameRate ?? 0
        return "\(dims.width)x\(dims.height) (\(Int(minRate))-\(Int(maxRate)) fps)"
    }
}
