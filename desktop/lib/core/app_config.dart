/// Build-time configuration mirrored from the Android app
/// (google-services.json + WorkerHealth.DEFAULT_PRIMARY).
class AppConfig {
  static const String appName = "Convo Chat";
  static const String appVersion = "6.1.1";
  static const int appVersionCode = 75;
  static const String packageName = "com.ebchat";

  /// Firebase Web API key (google-services.json → api_key.current_key).
  static const String firebaseApiKey =
      "AIzaSyAw1P7TLWfkLXS1f0qjrLUSwkfVEOhLxfk";

  /// ChatViewModel.getDatabaseInstance() fallback URL.
  static const String rtdbUrl =
      "https://chat-4e1d0-default-rtdb.asia-southeast1.firebasedatabase.app";

  /// WorkerHealth.DEFAULT_PRIMARY (canonical Cloudflare worker).
  static const String defaultWorkerPrimary =
      "https://convo-chat-companion.mr4425390.workers.dev";

  static const String projectId = "chat-4e1d0";

  /// Minimum and default window geometry for the desktop port.
  static const double minWidth = 1280;
  static const double minHeight = 720;
  static const double defaultWidth = 1440;
  static const double defaultHeight = 900;
}
