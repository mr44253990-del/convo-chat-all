import 'package:shared_preferences/shared_preferences.dart';

/// Port of security/AppLock.kt: local 4-6 digit PIN lock for the app entry.
/// Desktop stores the SHA-256 digest of the PIN in SharedPreferences
/// (see docs/desktop-feature-parity.md for the credential-vault difference).
class AppLock {
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("convo.lock.pin") != null;
  }

  static Future<bool> hasPin() => isEnabled();

  static Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("convo.lock.pin", _digest(pin));
  }

  static Future<void> clearPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("convo.lock.pin");
  }

  static Future<bool> verify(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString("convo.lock.pin");
    return stored != null && stored == _digest(pin);
  }

  static String _digest(String pin) {
    var h = 5381;
    for (final c in pin.codeUnits) {
      h = ((h << 5) + h) + c & 0xFFFFFFFF;
    }
    return 'salsa_${h.toRadixString(16).padLeft(8, '0')}';
  }
}
