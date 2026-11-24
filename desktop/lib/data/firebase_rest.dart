import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../core/app_config.dart';

/// Firebase Auth (Identity Toolkit REST) + Realtime Database REST +
/// Firestore REST client used by the desktop port. Desktop Flutter plugins for
/// Firebase do not exist upstream, so the app talks to Google's REST/EventSource
/// surface with the exact same wire payload as the Android client.
class FirebaseRest {
  static const String _authBase =
      "https://identitytoolkit.googleapis.com/v1/accounts";
  static const String _secureToken = "https://securetoken.googleapis.com/v1/token";

  static String get rtdbBase => AppConfig.rtdbUrl;

  String? _idToken;
  String? _refreshToken;
  String? _uid;
  DateTime _expiresAt = DateTime.fromMillisecondsSinceEpoch(0);
  final http.Client _client = http.Client();
  final _authStateCtrl = StreamController<String?>.broadcast();
  Timer? _refreshTimer;

  Stream<String?> get authState => _authStateCtrl.stream;
  String? get uid => _uid;
  String? get idToken => _idToken;
  bool get signedIn => _uid != null;

  Future<Map<String, dynamic>> signUpEmail(String email, String password) async {
    final r = await _post(":signUp",
        {"email": email, "password": password, "returnSecureToken": true});
    _applyToken(r);
    return r;
  }

  Future<Map<String, dynamic>> signInEmail(String email, String password) async {
    final r = await _post(":signInWithPassword",
        {"email": email, "password": password, "returnSecureToken": true});
    _applyToken(r);
    return r;
  }

  Future<Map<String, dynamic>> sendPasswordReset(String email) =>
      _post(":sendOobCode", {"requestType": "PASSWORD_RESET", "email": email});

  Future<Map<String, dynamic>> updateProfile(
      {String? displayName, String? photoUrl}) {
    final body = <String, dynamic>{"idToken": _idToken, "returnSecureToken": true};
    if (displayName != null) body["displayName"] = displayName;
    if (photoUrl != null) body["photoUrl"] = photoUrl;
    return _post(":update", body);
  }

  Future<void> signOut() async {
    _idToken = null;
    _refreshToken = null;
    _uid = null;
    _refreshTimer?.cancel();
    _authStateCtrl.add(null);
  }

  Future<String?> freshToken() async {
    if (_idToken == null) return null;
    if (DateTime.now().isAfter(_expiresAt.subtract(const Duration(seconds: 30)))) {
      try {
        await _refresh();
      } catch (_) {}
    }
    return _idToken;
  }

  Future<Map<String, dynamic>> _refresh() async {
    final r = await http.post(
      Uri.parse("$_secureToken?key=${AppConfig.firebaseApiKey}"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"grantType": "refresh_token", "refreshToken": _refreshToken}),
    );
    if (r.statusCode != 200) {
      throw Exception("token refresh failed: ${r.body}");
    }
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    _idToken = j["idToken"] as String?;
    _refreshToken = j["refresh_token"] as String?;
    _uid = (j["user_id"] as String?) ?? _uid;
    _expiresAt = DateTime.now()
        .add(Duration(seconds: int.tryParse("${j["expires_in"]}") ?? 3600));
    _scheduleRefresh();
    return j;
  }

  void _applyToken(Map<String, dynamic> j) {
    _idToken = j["idToken"] as String?;
    _refreshToken = j["refreshToken"] as String?;
    _uid = (j["localId"] as String?)?.toLowerCase();
    final expiresIn = int.tryParse("${j["expiresIn"]}") ?? 3600;
    _expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
    _scheduleRefresh();
    _authStateCtrl.add(_uid);
  }

  void _scheduleRefresh() {
    _refreshTimer?.cancel();
    if (_idToken == null) return;
    final refreshIn = _expiresAt.difference(DateTime.now()) - const Duration(minutes: 5);
    _refreshTimer = Timer(
        refreshIn.isNegative ? const Duration(seconds: 1) : refreshIn, () {
      _refresh().catchError((_) => <String, dynamic>{});
    });
  }

  Future<Map<String, dynamic>> _post(
      String action, Map<String, dynamic> body) async {
    final r = await _client.post(
      Uri.parse("$_authBase$action?key=${AppConfig.firebaseApiKey}"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    if (r.statusCode != 200) {
      throw Exception((j["error"] as Map?)?["message"] ?? "auth error ${r.statusCode}");
    }
    return j;
  }

  // ---------------- Realtime Database REST ----------------

  Uri _rtdbUri(String path,
      {String? orderBy, String? startAt, int? limitToLast}) {
    var p = path.startsWith("/") ? path : "/$path";
    p = p.replaceAll(RegExp("#"), "%23").replaceAll(RegExp(r"\?"), "%3F");
    final q = <String>["auth=$_idToken"];
    if (orderBy != null) q.add('orderBy="$orderBy"');
    if (startAt != null) q.add('startAt=$startAt');
    if (limitToLast != null) q.add("limitToLast=$limitToLast");
    return Uri.parse(
        "$rtdbBase$p.json?${q.join("&")}");
  }

  Future<dynamic> rtdbGet(String path,
      {String? orderBy, String? startAt, int? limitToLast}) async {
    await freshToken();
    final r = await _client.get(_rtdbUri(path,
        orderBy: orderBy, startAt: startAt, limitToLast: limitToLast));
    if (r.statusCode != 200) throw Exception("RTDB GET $path -> ${r.statusCode}");
    if (r.body == "null") return null;
    return jsonDecode(r.body);
  }

  Future<void> rtdbSet(String path, dynamic value) async {
    await freshToken();
    final r = await _client.put(
        Uri.parse(
            "$rtdbBase${(path.startsWith("/") ? path : "/$path")}.json?auth=$_idToken"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(value));
    if (r.statusCode != 200) throw Exception("RTDB SET $path -> ${r.statusCode}");
  }

  Future<void> rtdbUpdate(String path, Map<String, dynamic> patch) async {
    await freshToken();
    final r = await _client.patch(
        Uri.parse(
            "$rtdbBase${(path.startsWith("/") ? path : "/$path")}.json?auth=$_idToken"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(patch));
    if (r.statusCode != 200) throw Exception("RTDB UPDATE $path -> ${r.statusCode}");
  }

  Future<void> rtdbDelete(String path) async {
    await freshToken();
    final r = await _client.delete(Uri.parse(
        "$rtdbBase${(path.startsWith("/") ? path : "/$path")}.json?auth=$_idToken"));
    if (r.statusCode != 200) throw Exception("RTDB DELETE $path -> ${r.statusCode}");
  }

  /// Firebase push-style ID (chronological, 20 chars) mirroring push().getKey().
  static String newPushId() {
    const pushChars =
        "-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz";
    final rnd = Random();
    final now = DateTime.now().millisecondsSinceEpoch;
    final timeStampChars = List<String>.generate(8, (i) {
      final n = (now / pow(41, 7 - i)).floor() % 41;
      return pushChars[max(0, n)];
    });
    final id = List<String>.generate(12, (_) => pushChars[rnd.nextInt(64)]);
    return (timeStampChars..addAll(id)).join();
  }

  /// EventSource-style streaming listener over RTDB REST (Server-Sent Events).
  RtdbSse rtdbStream(String path, {int since = 0}) =>
      RtdbSse(_rtdbUri(path), this, since);
}

/// Streams `put` / `patch` events for one RTDB path.
class RtdbSse {
  final Uri _uri;
  final FirebaseRest _fb;
  final int since;
  http.StreamedResponse? _response;
  bool _closed = false;
  final _events = StreamController<Map<String, dynamic>?>.broadcast();

  RtdbSse(this._uri, this._fb, this.since);

  Stream<Map<String, dynamic>?> get events => _events.stream;

  Future<void> start() async {
    await _fb.freshToken();
    final req = http.Request("GET", _uri.replace(queryParameters: {
      ..._uri.queryParameters,
      "since": since > 0 ? DateTime.fromMillisecondsSinceEpoch(since).toUtc().toIso8601String() : "0"
    }));
    req.headers["Accept"] = "text/event-stream";
    try {
      _response = await _fb._client.send(req).timeout(const Duration(seconds: 15));
    } catch (e) {
      _events.addError(e);
      return;
    }
    if (_response!.statusCode != 200) {
      _events.addError(Exception("SSE ${_response!.statusCode}"));
      return;
    }
    final lines = <String>[];
    _response!.stream
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .listen((line) {
      if (line.startsWith("data: ")) {
        final data = line.substring(6);
        if (data.trim() == "null") return;
        lines.add(data);
        return;
      }
      if (line.isEmpty && lines.isNotEmpty) {
        for (final l in List.of(lines)) {
          try {
            _events.add(jsonDecode(l) as Map<String, dynamic>);
          } catch (_) {}
        }
        lines.clear();
      }
    }, onDone: () {
      if (!_closed) Future.delayed(const Duration(seconds: 2), () {
        if (!_closed) start();
      });
    }, onError: (Object e) {
      if (!_closed) Future.delayed(const Duration(seconds: 2), () {
        if (!_closed) start();
      });
    });
  }

  void close() {
    _closed = true;
    _events.close();
    _response = null;
  }
}

/// Firestore REST (v1) — Android collections map 1:1 to Firestore documents.
class FirestoreRest {
  static const String _base =
      "https://firestore.googleapis.com/v1/projects/${AppConfig.projectId}/databases/(default)/documents";

  final http.Client _client = http.Client();
  String? _idToken;

  void setIdToken(String? token) => _idToken = token;

  Map<String, String> get _headers => {
        "Content-Type": "application/json",
        if (_idToken != null) "Authorization": "Bearer $_idToken"
      };

  Map<String, dynamic> _encodeValue(dynamic v) {
    if (v == null) return {"nullValue": null};
    if (v is bool) return {"booleanValue": v};
    if (v is int) {
      if (v.abs() < 1 << 31) return {"integerValue": "$v"};
      return {"doubleValue": v};
    }
    if (v is num) return {"doubleValue": v};
    if (v is String) return {"stringValue": v};
    if (v is List) {
      return {
        "arrayValue": {"values": v.map(_encodeValue).toList()}
      };
    }
    if (v is Map) {
      return {
        "mapValue": {
          "fields": v.map((k, e) => MapEntry(k.toString(), _encodeValue(e)))
        }
      };
    }
    return {"stringValue": v.toString()};
  }

  dynamic _decodeValue(Map<String, dynamic> f) {
    if (f.containsKey("nullValue")) return null;
    if (f.containsKey("booleanValue")) return f["booleanValue"];
    if (f.containsKey("integerValue")) return int.tryParse(f["integerValue"]);
    if (f.containsKey("doubleValue")) return (f["doubleValue"] as num?)?.toDouble();
    if (f.containsKey("stringValue")) return f["stringValue"];
    if (f.containsKey("arrayValue")) {
      final values = (f["arrayValue"] as Map?)?["values"] as List? ?? [];
      return values.map((e) => _decodeValue(e as Map<String, dynamic>)).toList();
    }
    if (f.containsKey("mapValue")) {
      final fields = (f["mapValue"] as Map?)?["fields"] as Map? ?? {};
      return fields.map((k, e) =>
          MapEntry(k.toString(), _decodeValue(e as Map<String, dynamic>)));
    }
    if (f.containsKey("timestampValue")) return f["timestampValue"];
    return null;
  }

  Map<String, dynamic> _docBody(Map<String, dynamic> data) => {
        "fields": data.map((k, e) => MapEntry(k, _encodeValue(e)))
      };

  Map<String, dynamic> docToMap(Map<String, dynamic> doc) {
    final fields = (doc["fields"] as Map?) ?? {};
    return fields.map((k, e) =>
        MapEntry(k.toString(), _decodeValue(e as Map<String, dynamic>)));
  }

  String _pathOf(String collection, String? docId) {
    final p = "$_base/${collection.startsWith("/") ? collection.substring(1) : collection}";
    return docId == null ? p : "$p/$docId";
  }

  Future<Map<String, dynamic>?> getDoc(String collection, String docId,
      {String? idField}) async {
    await Future.microtask(() {});
    final r = await _client.get(Uri.parse("${_pathOf(collection, docId)}?key=${AppConfig.firebaseApiKey}"),
        headers: _headers);
    if (r.statusCode == 404) return null;
    if (r.statusCode != 200) throw Exception("Firestore GET $collection/$docId -> ${r.statusCode}");
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    return docToMap(j);
  }

  Future<List<(String, Map<String, dynamic>)>> listDocs(String collection,
      {int limit = 300}) async {
    await Future.microtask(() {});
    final r = await _client.get(
        Uri.parse("${_pathOf(collection, null)}?pageSize=$limit&key=${AppConfig.firebaseApiKey}"),
        headers: _headers);
    if (r.statusCode != 200) throw Exception("Firestore LIST $collection -> ${r.statusCode}");
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    final docs = (j["documents"] as List? ?? []);
    return docs.map((d) {
      final raw = d as Map<String, dynamic>;
      final name = raw["name"] as String;
      final id = name.split("/").last;
      return (id, docToMap(raw));
    }).toList();
  }

  Future<void> setDoc(String collection, String docId,
      Map<String, dynamic> data) async {
    final r = await _client.patch(
        Uri.parse(
            "${_pathOf(collection, docId)}?key=${AppConfig.firebaseApiKey}&exists=false"),
        headers: _headers,
        body: jsonEncode(_docBody(data)));
    if (r.statusCode == 200 || r.statusCode == 201 || r.statusCode == 409) return;
    throw Exception("Firestore SET $collection/$docId -> ${r.statusCode}");
  }

  Future<void> upsertDoc(String collection, String docId,
      Map<String, dynamic> data) async {
    final r = await _client.patch(
        Uri.parse(
            "${_pathOf(collection, docId)}?key=${AppConfig.firebaseApiKey}&currentDocument.exists=false"),
        headers: _headers,
        body: jsonEncode(_docBody(data)));
    if (r.statusCode == 200 || r.statusCode == 201) return;
    // Existed already: plain merge patch.
    final r2 = await _client.patch(
        Uri.parse("${_pathOf(collection, docId)}?key=${AppConfig.firebaseApiKey}"),
        headers: _headers,
        body: jsonEncode(_docBody(data)));
    if (r2.statusCode != 200) {
      throw Exception("Firestore UPSERT $collection/$docId -> ${r2.statusCode}");
    }
  }

  Future<void> updateDoc(String collection, String docId,
      Map<String, dynamic> data) async {
    final r = await _client.patch(
        Uri.parse("${_pathOf(collection, docId)}?key=${AppConfig.firebaseApiKey}"),
        headers: _headers,
        body: jsonEncode(_docBody(data)));
    if (r.statusCode != 200) {
      throw Exception("Firestore UPDATE $collection/$docId -> ${r.statusCode}");
    }
  }

  Future<void> deleteDoc(String collection, String docId) async {
    final r = await _client.delete(
        Uri.parse("${_pathOf(collection, docId)}?key=${AppConfig.firebaseApiKey}"),
        headers: _headers);
    if (r.statusCode != 200 && r.statusCode != 404) {
      throw Exception("Firestore DELETE $collection/$docId -> ${r.statusCode}");
    }
  }
}

/// Firebase Auth REST ids for Firestore REST calls. Kept shared so the same
/// idToken used by RTDB/Worker also authorizes Firestore documents.
final FirebaseRest firebase = FirebaseRest();
final FirestoreRest firestore = FirestoreRest();
