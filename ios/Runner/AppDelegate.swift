import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AppIcon") {
      AppIcon.register(with: registrar.messenger())
    }
  }
}

/// Значок приложения на рабочем столе в цветах темы.
///
/// Значки тем — альтернативные `AppIcon-<Тема>` в Assets.xcassets, их
/// генерирует tool/generate_theme_icons.sh. Основной значок — чёрной темы.
private enum AppIcon {
  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.tasbeh.app/app_icon",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "setIcon", let palette = call.arguments as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      setIcon(for: palette, result: result)
    }
  }

  /// Имя значка для темы — имени из `ThemePalette` во Flutter. Для основного
  /// значка система ждёт `nil`.
  private static func iconName(for palette: String) -> String? {
    palette == "black" ? nil : "AppIcon-" + palette.prefix(1).uppercased() + palette.dropFirst()
  }

  /// Уже стоящий значок не переставляется: каждая смена показывает системное
  /// уведомление, и повторять его без изменений незачем.
  private static func setIcon(for palette: String, result: @escaping FlutterResult) {
    let application = UIApplication.shared
    let name = iconName(for: palette)
    guard application.supportsAlternateIcons, application.alternateIconName != name else {
      result(nil)
      return
    }

    application.setAlternateIconName(name) { error in
      DispatchQueue.main.async {
        if let error = error {
          result(FlutterError(
            code: "set_icon_failed",
            message: error.localizedDescription,
            details: nil
          ))
        } else {
          result(nil)
        }
      }
    }
  }
}
