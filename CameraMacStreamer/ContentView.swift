import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var frameHandler = FrameHandler()
    @State private var isStreaming = false

    var body: some View {
        VStack {
            HStack {
                TextField("Destination IP (e.g., 192.168.1.123)", text: $frameHandler.targetIP)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 200)
                TextField("Port", text: $frameHandler.targetPort)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
            }
            .padding()
            
            Toggle("Use Top Half Only", isOn: $frameHandler.useTopHalfOnly)
                    .padding()
            
            Toggle("Mirror Video", isOn: $frameHandler.mirrorVideo)
                .padding()

            Button(isStreaming ? "Disconnect" : "Connect") {
                if isStreaming {
                    frameHandler.stopStreaming()
                } else {
                    frameHandler.startStreaming(from: cameraManager.selectedCamera)
                }
                isStreaming.toggle()
            }
            .disabled(frameHandler.targetIP.isEmpty || frameHandler.targetPort.isEmpty)
            .padding()

            Picker("Camera", selection: $cameraManager.selectedCamera) {
                ForEach(cameraManager.availableCameras, id: \.uniqueID) { device in
                    Text(device.localizedName).tag(device as AVCaptureDevice?)
                }
            }
            .onAppear { cameraManager.fetchCameras() }
            .padding()

            if !cameraManager.availableFormats.isEmpty {
                Picker("Resolution", selection: $cameraManager.selectedFormat) {
                    ForEach(cameraManager.availableFormats, id: \.self) { format in
                        Text(cameraManager.resolutionString(for: format)).tag(format as AVCaptureDevice.Format?)
                    }
                }
                .onChange(of: cameraManager.selectedFormat) {_, newFormat in
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
            isStreaming = false
        }
    }
}
