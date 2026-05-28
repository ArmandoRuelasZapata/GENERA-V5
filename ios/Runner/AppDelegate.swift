import Flutter
import UIKit
import Darwin
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
    
  private var visualEffectView: UIVisualEffectView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // 1. Inicializar Google Maps con la API key de Info.plist (iOS requiere esto)
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
       !apiKey.isEmpty {
      GMSServices.provideAPIKey(apiKey)
    } else {
      NSLog("⚠️ GMSApiKey no configurada en Info.plist")
    }

    // 2. Registrar plugins y arrancar Flutter PRIMERO — esto inicializa self.window
    GeneratedPluginRegistrant.register(with: self)
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // 3. Configurar el canal de seguridad DESPUÉS de que Flutter esté inicializado
    if let controller = window?.rootViewController as? FlutterViewController {
      let securityChannel = FlutterMethodChannel(name: "com.originallab/security",
                                                binaryMessenger: controller.binaryMessenger)
      securityChannel.setMethodCallHandler({
        (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        if call.method == "isJailBroken" {
            result(self.checkJailBroken())
        } else if call.method == "isSimulator" {
            #if targetEnvironment(simulator)
            result(true)
            #else
            result(false)
            #endif
        } else if call.method == "isTampered" {
            result(self.isTampered())
        } else {
          result(FlutterMethodNotImplemented)
        }
      })
    }

    // Capturas permitidas temporalmente en todas las variantes.

    return result
  }

  // Comprobaciones heurísticas de seguridad locales
  private func checkJailBroken() -> Bool {
      #if targetEnvironment(simulator)
      return false
      #else
      let fileManager = FileManager.default
      let paths = [
          "/Applications/Cydia.app",
          "/Applications/Sileo.app",
          "/Applications/Zebra.app",
          "/Library/MobileSubstrate/MobileSubstrate.dylib",
          "/bin/bash",
          "/usr/sbin/sshd",
          "/etc/apt"
      ]
      
      for path in paths {
          if fileManager.fileExists(atPath: path) {
              return true
          }
      }
      
      let path = "/private/" + NSUUID().uuidString
      do {
          try "jailbreak_test".write(toFile: path, atomically: true, encoding: .utf8)
          try fileManager.removeItem(atPath: path)
          return true
      } catch {
          // Fallo esperado si la sandbox está intacta
      }
      
      if let url = URL(string: "cydia://package/com.example.package"), UIApplication.shared.canOpenURL(url) {
          return true
      }
      return false
      #endif
  }

  private func isTampered() -> Bool {
      let dyldInsert = ProcessInfo.processInfo.environment["DYLD_INSERT_LIBRARIES"] ?? ""
      if !dyldInsert.isEmpty {
          NSLog("⚠️ DYLD_INSERT_LIBRARIES detected: \(dyldInsert)")
      }

      return false
  }

  override func applicationWillResignActive(_ application: UIApplication) {
      if let window = self.window {
          let blurEffect = UIBlurEffect(style: .dark)
          visualEffectView = UIVisualEffectView(effect: blurEffect)
          visualEffectView?.frame = window.bounds
          window.addSubview(visualEffectView!)
      }
      super.applicationWillResignActive(application)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
      visualEffectView?.removeFromSuperview()
      super.applicationDidBecomeActive(application)
  }
}
