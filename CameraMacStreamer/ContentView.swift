import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var frameHandler = FrameHandler()

    var body: some View {
        VStack {
            Picker("Camera", selection: $cameraManager.selectedCamera) {
                ForEach(cameraManager.availableCameras, id: \.uniqueID) { device in
                    Text(device.localizedName).tag(device as AVCaptureDevice?)
                }
            }
            .onAppear { cameraManager.fetchCameras() }
            .onChange(of: cameraManager.selectedCamera) { newDevice in
                frameHandler.startStreaming(from: newDevice)
            }
            .padding()

            CameraPreview(device: $cameraManager.selectedCamera)
                .frame(width: 640, height: 480)
        }
        .onDisappear {
            frameHandler.stopStreaming()
        }
    }
}
