import AVFoundation
import Foundation
import SPAGCore
import SwiftUI
import UIKit

/// Scans the QR code on a login card with the camera. Camera pictures are never recorded or saved.
struct LoginCardScannerSheet: View {
    var onScan: (JoinDetails) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @State private var cameraAllowed: Bool?
    @State private var wrongCode = false

    var body: some View {
        NavigationStack {
            Group {
                switch cameraAllowed {
                case nil:
                    ProgressView()
                case false?:
                    BuddySays(text: "I can't use the camera on this iPad. Type the class code from your card instead.", mood: .thinking)
                        .padding(24)
                case true?:
                    VStack(spacing: 16) {
                        Text(wrongCode ? "That isn't a SPAG School login card. Try again." : "Hold your login card up to the camera.")
                            .pupilText(.title3, weight: .semibold)
                            .foregroundStyle(wrongCode ? theme.tryAgain : theme.text)
                            .multilineTextAlignment(.center)
                        QRCodeScanner { text in
                            if let details = JoinDetails(scannedText: text) {
                                onScan(details)
                            } else {
                                wrongCode = true
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .accessibilityLabel("Camera view for scanning your login card")
                    }
                    .padding(24)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .screenBackground()
            .navigationTitle("Scan my login card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .task { cameraAllowed = await Self.requestCamera() }
    }

    private static func requestCamera() async -> Bool {
        guard AVCaptureDevice.default(for: .video) != nil else { return false }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return true
        case .notDetermined: return await AVCaptureDevice.requestAccess(for: .video)
        default: return false
        }
    }
}

/// Calls `onCode` with the text of each QR code it sees, until it is given a different closure.
struct QRCodeScanner: UIViewControllerRepresentable {
    var onCode: (String) -> Void

    func makeUIViewController(context: Context) -> ScannerController {
        let controller = ScannerController()
        controller.onCode = onCode
        return controller
    }

    func updateUIViewController(_ controller: ScannerController, context: Context) {
        controller.onCode = onCode
    }

    final class ScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
        var onCode: ((String) -> Void)?
        private let captureSession = AVCaptureSession()
        private var previewLayer: AVCaptureVideoPreviewLayer?
        private var lastCode: String?

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .black
            guard let camera = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: camera),
                  captureSession.canAddInput(input) else { return }
            captureSession.addInput(input)

            let output = AVCaptureMetadataOutput()
            guard captureSession.canAddOutput(output) else { return }
            captureSession.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr]

            let layer = AVCaptureVideoPreviewLayer(session: captureSession)
            layer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(layer)
            previewLayer = layer
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            previewLayer?.frame = view.bounds
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            let session = captureSession
            // startRunning blocks until the camera is ready, so keep it off the main thread.
            DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            let session = captureSession
            DispatchQueue.global(qos: .userInitiated).async { session.stopRunning() }
        }

        nonisolated func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard let code = metadataObjects.lazy.compactMap({ ($0 as? AVMetadataMachineReadableCodeObject)?.stringValue }).first else { return }
            // The delegate queue is the main queue.
            MainActor.assumeIsolated {
                guard code != lastCode else { return }
                lastCode = code
                onCode?(code)
            }
        }
    }
}
