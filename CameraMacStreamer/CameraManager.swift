//
//  CameraManager.swift
//  CameraMac
//
//  Created by Christopher Woods on 4/24/25.
//


import AVFoundation

class CameraManager: ObservableObject {
    @Published var availableCameras: [AVCaptureDevice] = []
    @Published var selectedCamera: AVCaptureDevice?

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
}
