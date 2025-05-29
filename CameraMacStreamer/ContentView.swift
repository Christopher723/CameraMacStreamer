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
            
            // --- Add this block for resolution selection ---
            if !cameraManager.availableFormats.isEmpty {
                Picker("Resolution", selection: $cameraManager.selectedFormat) {
                    ForEach(cameraManager.availableFormats, id: \.self) { format in
                        Text(cameraManager.resolutionString(for: format)).tag(format as AVCaptureDevice.Format?)
                    }
                }
                .onChange(of: cameraManager.selectedFormat) { newFormat in
                    if let format = newFormat {
                        cameraManager.setResolution(format: format)
                    }
                }
                .padding()
            }
            
            CameraPreview(device: $cameraManager.selectedCamera)
                .frame(width: 640, height: 480)
        }
        .onDisappear {
            frameHandler.stopStreaming()
        }
        
    }
}
