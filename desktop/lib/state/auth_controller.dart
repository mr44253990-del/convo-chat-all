import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_config.dart';
import '../data/firebase_rest.dart';
import '../data/models.dart';
import '../data/worker_router.dart';

/// Mirrors the auth-related responsibilities of ChatViewModel +
/// RememberedAccount.kt + AccountCredentialVault.kt (desktop keeps plaintext
/// session preference only; see docs/desktop-feature-parity.md).
class AuthController extends ChangeNotifier {
  User? me;
  String? uid;
  bool busy = false;
  String? error;
  bool networkOnline = true;

  Timer? _presenceTimer;
  Timer? _awayTimer;

  bool get signedIn => uid != null && me != null;
  bool get isAdmin => me?.role == "admin" ||
      (me?.role == "user" && me!.uid == ""); // only role==admin in this app

  Future<void> tryRestoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    await firebase.signOut();
    final savedEmail = prefs.getString("convo.email");
    final savedPass = prefs.getString("convo.pass");
    final remember = prefs.getBool("convo.remember") ?? true;
    if (savedEmail == null || savedPass == null || !remember) return;
    try {
      await signIn(savedEmail, savedPass, remember: true);
    } catch (_) {}
  }

  Future<bool> signIn(String email, String password,
      {bool remember = true}) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      await firebase.signInEmail(email.trim(), password);
      firestore.setIdToken(firebase.idToken);
      uid = firebase.uid;
      final data = await firestore.getDoc("users", uid!) ?? const {};
      me = User.fromJson(data, uid: uid!);
      await _stampDeviceMeta();
      await _registerDeviceSession();
      await _startPresence();
      final prefs = await SharedPreferences.getInstance();
      if (remember) {
        await prefs.setString("convo.email", email.trim());
        await prefs.setString("convo.pass", password);
        await prefs.setBool("convo.remember", true);
      }
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> signUp(String email, String password, String name) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      await firebase.signUpEmail(email.trim(), password);
      firestore.setIdToken(firebase.idToken);
      uid = firebase.uid;
      final now = DateTime.now().millisecondsSinceEpoch;
      final data = {
        "uid": uid,
        "name": name.trim(),
        "email": email.trim(),
        "username":
            name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_.]'), ""),
        "createdAt": now,
        "role": "user",
        "isOnline": true,
        "lastActive": now,
        "friends": <String>[],
        "followers": <String>[],
        "following": <String>[],
        "blockedUsers": <String>[],
        "appVersion": AppConfig.appVersion,
        "appVersionCode": AppConfig.appVersionCode,
        "appVersionAt": now,
        "deviceModel": "Convo Desktop",
        "androidVersion": Platform.operatingSystemVersion,
      };
      await firestore.setDoc("users", uid!, data);
      me = User.fromJson(data, uid: uid!);
      await _registerDeviceSession();
      await _startPresence();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("convo.email", email.trim());
      await prefs.setString("convo.pass", password);
      await prefs.setBool("convo.remember", true);
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await firebase.sendPasswordReset(email.trim());
  }

  Future<void> _stampDeviceMeta() async {
    if (me == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      await firebase.rtdbUpdate("status/$uid", {
        "state": "online",
        "lastChanged": now,
        "onlineUntil": now + 120000,
      });
      await firestore.updateDoc("users", uid!, {
        "appVersion": AppConfig.appVersion,
        "appVersionCode": AppConfig.appVersionCode,
        "appVersionAt": now,
        "deviceModel": "Convo Desktop",
        "androidVersion": Platform.operatingSystemVersion,
      });
      me = me!.copyWith(appVersion: AppConfig.appVersion);
    } catch (_) {}
  }

  /// Port of `subscriptions/session` manager — registers/request device
  /// sessions at the Worker's `/sessions/register` endpoint (documented flow).
  Future<void> _registerDeviceSession() async {
    try {
      final base = workerRouter.resolve("database");
      await post(
        "$base/sessions/register",
        <String, dynamic>{
          "uid": uid,
          "idToken": await firebase.freshToken(),
          "device": {"model": "Convo Desktop", "platform": Platform.operatingSystem,
            "version": AppConfig.appVersion},
        },
      );
    } catch (_) {}
  }

  /// ChatViewModel.setActiveUserPresence equivalents (RTDB status + Firestore onlineUntil).
  Future<void> _startPresence() async {
    _presenceTimer?.cancel();
    _awayTimer?.cancel();
    Future<void> ping() async {
      try {
        final now = DateTime.now().millisecondsSinceEpoch;
        await firebase.rtdbUpdate("status/$uid", {
          "state": "online",
          "lastChanged": now,
          "onlineUntil": now + 300000,
        });
        await firestore.updateDoc("users", uid!, {
          "isOnline": true,
          "onlineUntil": now + 300000,
        });
        me = me!.copyWith(isOnline: true);
      } catch (_) {}
    }

    await ping();
    _presenceTimer = Timer.periodic(const Duration(seconds: 90), (_) => ping());
    _awayTimer = Timer(const Duration(seconds: 300), () async {
      try {
        await firestore.updateDoc("users", uid!, {"isOnline": false, "offlineSince": DateTime.now().millisecondsSinceEpoch});
        me = me!.copyWith(isOnline: false);
        notifyListeners();
      } catch (_) {}
    });
  }

  Future<void> reloadMe() async {
    if (uid == null) return;
    try {
      final data = await firestore.getDoc("users", uid!) ?? const {};
      me = User.fromJson(data, uid: uid!);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> signOut({bool clearRemembered = false}) async {
    _presenceTimer?.cancel();
    _awayTimer?.cancel();
    try {
      await firebase.rtdbUpdate("status/$uid", {
        "state": "offline",
        "lastChanged": DateTime.now().millisecondsSinceEpoch,
      });
      await firestore.updateDoc("users", uid ?? "", {
        "isOnline": false,
        "offlineSince": DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {}
    await firebase.signOut();
    firestore.setIdToken(null);
    uid = null;
    me = null;
    if (clearRemembered) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("convo.email");
      await prefs.remove("convo.pass");
      await prefs.setBool("convo.remember", false);
    }
    notifyListeners();
  }
}

/// Thin HTTP post helper shared by all Worker calls.
Future<Map<String, dynamic>> post(String url, Map<String, dynamic> body) async {
  final client = HttpClient();
  try {
    final req = await client.postUrl(Uri.parse(url));
    req.headers.contentType = ContentType.json;
    req.write(body);
    final res = await req.close();
    final text = await utf8.decoder.bind(res).join();
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (text.isEmpty) return {"ok": true};
      try {
        return Map<String, dynamic>.from(jsonDecode(text) as Map);
      } catch (_) {
        return {"ok": true};
      }
    }
    return {"error": "HTTP ${res.statusCode}"};
  } catch (e) {
    return {"error": e.toString()};
  } finally {
    client.close();
  }
}
