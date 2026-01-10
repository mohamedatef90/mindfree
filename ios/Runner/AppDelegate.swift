import Flutter
import UIKit
import AudioToolbox

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Set up method channel for audio
    let controller = window?.rootViewController as! FlutterViewController
    let audioChannel = FlutterMethodChannel(
      name: "mindfree/audio",
      binaryMessenger: controller.binaryMessenger
    )

    audioChannel.setMethodCallHandler { [weak self] (call, result) in
      if call.method == "playSystemSound" {
        if let args = call.arguments as? [String: Any],
           let soundId = args["soundId"] as? Int {
          AudioServicesPlaySystemSound(SystemSoundID(soundId))
          result(nil)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Sound ID required", details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
