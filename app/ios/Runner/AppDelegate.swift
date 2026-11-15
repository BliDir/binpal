import Flutter
import UIKit
import UserNotifications
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Lets flutter_local_notifications show reminders while the app is open.
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "TextRecognition") {
      TextRecognition.register(with: registrar)
    }
  }
}

/// Reads the text on a photo for photo check's recycling marks (プラ, PET,
/// アルミ, スチール, 紙). The ML Kit plugin reads only Latin text on iOS, so
/// Apple's Vision does it here, on the device. Japanese needs iOS 16; on
/// iOS 15 only Latin text such as PET is read.
enum TextRecognition {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "binpal/text_recognition", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard call.method == "recognize",
        let path = (call.arguments as? [String: Any])?["path"] as? String
      else {
        result(FlutterMethodNotImplemented)
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        // Marks are single words; correction would "fix" them into others.
        request.usesLanguageCorrection = false
        if #available(iOS 16.0, *) {
          request.revision = VNRecognizeTextRequestRevision3
          request.recognitionLanguages = ["ja-JP", "en-US"]
        }
        do {
          try VNImageRequestHandler(url: URL(fileURLWithPath: path)).perform([request])
          let lines = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
          DispatchQueue.main.async { result(lines.joined(separator: "\n")) }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "failed", message: error.localizedDescription, details: nil))
          }
        }
      }
    }
  }
}
