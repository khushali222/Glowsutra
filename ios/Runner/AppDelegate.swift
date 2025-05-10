import Flutter
import UIKit
import Firebase
import flutter_local_notifications


@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
  FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
        GeneratedPluginRegistrant.register(with: registry)
      }

     FirebaseApp.configure()
     GeneratedPluginRegistrant.register(with: self)
     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
