import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    provideGoogleMapsApiKey()
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Injeta a chave do Google Maps para iOS lida do Info.plist (GMSApiKey),
  /// que por sua vez vem da build setting GMS_API_KEY definida em
  /// Flutter/ApiKeys.xcconfig. Sem chave configurada o mapa fica vazio,
  /// mas o app continua funcional e nenhuma chave real e versionada.
  private func provideGoogleMapsApiKey() {
    guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
          !apiKey.isEmpty,
          !apiKey.hasPrefix("$(") else {
      return
    }
    GMSServices.provideAPIKey(apiKey)
  }
}
