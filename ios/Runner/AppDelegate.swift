import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Set up method channel for widget data sharing
    let controller = window?.rootViewController as! FlutterViewController
    let widgetChannel = FlutterMethodChannel(
      name: "com.simplist.app/widget",
      binaryMessenger: controller.binaryMessenger
    )

    widgetChannel.setMethodCallHandler { (call, result) in
      if call.method == "saveWidgetData" {
        guard let args = call.arguments as? [String: Any],
              let key = args["key"] as? String,
              let value = args["value"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
          return
        }

        let sharedDefaults = UserDefaults(suiteName: "group.simplist.todo.app")
        sharedDefaults?.set(value, forKey: key)
        sharedDefaults?.synchronize()

        print("AppDelegate: Saved \(key) to app group: \(value)")
        result(true)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
