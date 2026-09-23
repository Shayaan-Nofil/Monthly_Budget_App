import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let ok = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // Keep the native window / Flutter view matched to system light/dark.
    window?.backgroundColor = .systemBackground
    if let flutterView = window?.rootViewController?.view {
      flutterView.backgroundColor = .systemBackground
    }

    return ok
  }
}
