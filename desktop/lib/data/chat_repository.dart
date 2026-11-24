import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../core/app_config.dart';
import 'firebase_rest.dart';
import 'models.dart';
import 'worker_router.dart';

/// Port of the RTDB/Firestore/Worker portions of ChatViewModel.kt used by the
/// direct-chat flow: message relay (identical wire payload), unread counters,
/// the /notifications instant ping, FCM gateway push via the Worker,
/// typing indicators, seen receipts and call state.
class ChatRepository {
  final FirebaseRest fb = firebase;
  final FirestoreRest fs = firestore;

  static String chatIdWith(String a, String b) =>
      ([a, b]..sort()).join("_");

  Stream<void> start() async* {}

  /// ChatViewModel.sendMessage() port (text-only fast path used by the desktop
  /// composer; media paths are relayed with the exact same fields).
  Future<String?> sendMessage({
    required User me,
    required User recipient,
    required String text,
    String? imageUrl,
    String? voiceUrl,
    int? voiceDurationSec,
    String? fileUrl,
    String? fileName,
    String? fileMimeType,
    int? fileSize,
    String? replyToId,
    String? replyToText,
    String? replyToSenderName,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && imageUrl == null && voiceUrl == null && fileUrl == null) {
      return null;
    }
    final chatId = chatIdWith(me.uid, recipient.uid);

    // Non-friend cold start → message_requests (Android parity).
    final established =
        me.friends.contains(recipient.uid) || (await lastMessages(chatId, 1)).isNotEmpty;
    if (!established) {
      final preview = trimmed.isNotEmpty
          ? trimmed
          : imageUrl != null
              ? "Photo request"
              : voiceUrl != null
                  ? "Voice message request"
                  : fileUrl != null
                      ? "File request"
                      : "Message request";
      final requestId = "${me.uid}_${recipient.uid}";
      final req = MessageRequest(
        id: requestId,
        senderId: me.uid,
        recipientId: recipient.uid,
        senderName: me.name,
        preview: preview,
        status: "pending",
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      await fs.upsertDoc("message_requests", requestId, req.toJson());
      await _createActivityNotification(
          recipient.uid, "message_request", requestId, "sent you a message request");
      return requestId;
    }

    await _ensureMembership(chatId, me.uid, recipient.uid);
    final messageId = FirebaseRest.newPushId();
    final sentAt = DateTime.now().millisecondsSinceEpoch;
    final message = Message(
      messageId: messageId,
      senderId: me.uid,
      senderName: me.name,
      senderUsername: me.username,
      text: trimmed,
      timestamp: sentAt,
      edited: false,
      replyToId: replyToId,
      replyToText: replyToText,
      replyToSenderName: replyToSenderName,
      imageUrl: imageUrl,
      voiceUrl: voiceUrl,
      voiceDurationSec: voiceDurationSec,
      remoteVoiceUrl: voiceUrl,
      fileUrl: fileUrl,
      remoteFileUrl: fileUrl,
      fileName: fileName,
      fileMimeType: fileMimeType,
      fileSize: fileSize,
      deliveredToRecipient: false,
    );

    final body = message.toJson()..remove("seenByRecipient");
    await fb.rtdbSet("chats/$chatId/messages/$messageId", body);

    // Unread count increment for recipient (same as Android on success).
    try {
      final current = await fb.rtdbGet("unread_counts/${recipient.uid}/${me.uid}");
      await fb.rtdbSet(
          "unread_counts/${recipient.uid}/${me.uid}", (current as int? ?? 0) + 1);
    } catch (_) {}

    // Instant /notifications ping (identical payload).
    try {
      final body = trimmed.isNotEmpty
          ? trimmed
          : fileUrl != null
              ? "File: ${fileName ?? "attachment"}"
              : voiceUrl != null
                  ? "Voice message"
                  : imageUrl != null
                      ? "Photo"
                      : "";
      await fb.rtdbSet("notifications/${recipient.uid}", {
        "senderId": me.uid,
        "senderName": me.name,
        "text": message.cloudText ? "New message" : body,
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {}

    // Rich push through the Worker FCM gateway (triggerFcmGatewayNotification).
    await triggerPush(
      targetToken: recipient.fcmToken,
      senderName: me.name,
      messageBody: fileUrl != null
          ? "File: ${fileName ?? "attachment"}"
          : voiceUrl != null
              ? "Voice message"
              : imageUrl != null
                  ? "Photo"
                  : trimmed,
      senderId: me.uid,
      senderProfileUrl: me.profileImageUrl,
      notificationType: "message",
      targetId: messageId,
      imageUrl: (imageUrl != null && imageUrl.startsWith("https://")) ? imageUrl : null,
    );
    return messageId;
  }

  /// triggerFcmGatewayNotification() port — Worker /push (FCM HTTP v1 upload).
  Future<void> triggerPush({
    required String targetToken,
    required String senderName,
    required String messageBody,
    required String senderId,
    String senderProfileUrl = "",
    String notificationType = "message",
    String targetId = "",
    String? imageUrl,
  }) async {
    if (targetToken.isEmpty) return;
    final token = await fb.freshToken();
    if (token == null) return;
    final gateway = workerRouter.resolve("push");
    try {
      final client = HttpClient();
      try {
        final req = await client.postUrl(Uri.parse("$gateway/push"));
        req.headers.contentType = ContentType.json;
        req.headers.set(HttpHeaders.authorizationHeader, "Bearer $token");
        req.write(jsonEncode({
          "token": targetToken,
          "title": notificationType == "message"
              ? "Convo Chat • $senderName"
              : "$senderName • Convo Chat",
          "body": messageBody,
          "text": messageBody,
          "senderId": senderId,
          "senderName": senderName,
          "senderProfileUrl": senderProfileUrl,
          "notificationType": notificationType,
          "targetId": targetId,
          if (imageUrl != null) "imageUrl": imageUrl,
          if (imageUrl != null) "previewKind": "photo",
          "timestamp": DateTime.now().millisecondsSinceEpoch,
        }));
        final res = await req.close();
        await res.drain<void>();
        if (res.statusCode >= 500 || res.statusCode == 429) {
          workerRouter.markDown(gateway);
        } else if (res.statusCode == 404 || res.statusCode == 400) {
          workerRouter.setOutdated(gateway, res.statusCode == 404);
        }
      } finally {
        client.close();
      }
    } catch (_) {
      workerRouter.markDown(gateway);
    }
  }

  Future<void> _ensureMembership(String chatId, String a, String b) async {
    try {
      await fb.rtdbUpdate("chats/$chatId/members", {a: true, b: true});
    } catch (_) {}
  }

  /// Full history load (orderByChild("timestamp") in Android; REST equivalent).
  Future<List<Message>> lastMessages(String chatId, int limitToLast) async {
    try {
      final raw = await fb.rtdbGet(
        "chats/$chatId/messages",
        orderBy: "timestamp",
        limitToLast: limitToLast,
      );
      return _fromRTDB(raw);
    } catch (e) {
      return [];
    }
  }

  /// Streamed listener (addChildEventListener parity, 300 last msgs kept).
  Stream<List<Message>> watchMessages(String chatId) async* {
    var current = await lastMessages(chatId, 300);
    yield current;
    final sinceEpoch = DateTime.now().millisecondsSinceEpoch;
    final sse = fb.rtdbStream("chats/$chatId/messages", since: sinceEpoch);
    await sse.start();
    await for (final data in sse.events) {
      if (data == null) continue;
      final path = (data["path"] as String?) ?? "";
      final d = data["data"];
      if (path.contains(RegExp("/messages/-"))) {
        final id = path.split("/").lastOrNull ?? "";
        if (id.isEmpty || d == null) continue;
        final m = Message.fromJson(Map<String, dynamic>.from(d), messageId: id);
        if (!_isVisible(m)) continue;
        if (current.any((e) => e.messageId == id)) {
          current = [
            for (final e in current)
              if (e.messageId == id) m else e
          ];
        } else {
          current = [...current, m]
            ..sort((x, y) => x.timestamp.compareTo(y.timestamp));
          if (current.length > 300) current = current.sublist(current.length - 300);
        }
        yield current;
      } else if (path.contains(RegExp("/messages/-[^/]*/(seenByRecipient|deliveredToRecipient)"))) {
        final segs = path.split("/");
        final id = segs[segs.length - 2];
        final field = segs.last;
        current = [
          for (final e in current)
            if (e.messageId == id)
              Message(
                  messageId: e.messageId,
                  senderId: e.senderId,
                  senderName: e.senderName,
                  senderUsername: e.senderUsername,
                  text: e.text,
                  timestamp: e.timestamp,
                  edited: e.edited,
                  replyToId: e.replyToId,
                  replyToText: e.replyToText,
                  replyToSenderName: e.replyToSenderName,
                  imageUrl: e.imageUrl,
                  voiceUrl: e.voiceUrl,
                  voiceDurationSec: e.voiceDurationSec,
                  remoteVoiceUrl: e.remoteVoiceUrl,
                  fileUrl: e.fileUrl,
                  remoteFileUrl: e.remoteFileUrl,
                  fileName: e.fileName,
                  fileMimeType: e.fileMimeType,
                  fileSize: e.fileSize,
                  seenByRecipient: field == "seenByRecipient" ? d == true : e.seenByRecipient,
                  deliveredToRecipient: field == "deliveredToRecipient" ? d == true : e.deliveredToRecipient,
                  expiresAt: e.expiresAt,
                  editHistory: e.editHistory,
                  reactions: e.reactions,
                  cloudText: e.cloudText)
            else
              e
        ];
        yield current;
      }
    }
  }

  List<Message> _fromRTDB(dynamic raw) {
    if (raw is! Map) return const [];
    final out = <Message>[];
    final keys = raw.keys.map((k) => k.toString()).toList()..sort();
    for (final k in keys) {
      final v = raw[k];
      if (v is! Map) continue;
      final m = Message.fromJson(Map<String, dynamic>.from(v), messageId: k);
      if (!_isVisible(m)) continue;
      out.add(m);
    }
    return out;
  }

  bool _isVisible(Message m) => m.timestamp > 0 && m.visible;

  /// Mark incoming messages delivered+seen (DeliveryAck + seen tick flows).
  Future<void> markSeen(String chatId, String myUid, List<Message> messages) async {
    for (final m in messages) {
      if (m.senderId == myUid) continue;
      try {
        await fb.rtdbUpdate("chats/$chatId/messages/${m.messageId}", {
          "seenByRecipient": true,
          "deliveredToRecipient": true,
        });
        await fb.rtdbSet("delivery_receipts/${m.senderId}/${m.messageId}", {
          "seen": true,
          "delivered": true,
          "seenAt": DateTime.now().millisecondsSinceEpoch,
        });
      } catch (_) {}
    }
    try {
      final parts = chatId.split("_");
      final peer = parts.firstWhere((p) => p != myUid, orElse: () => "");
      if (peer.isNotEmpty) {
        await fb.rtdbSet("unread_counts/$myUid/$peer", 0);
      }
    } catch (_) {}
  }

  /// Typing indicator (typing/{chatId}/{uid}) with auto-expiry.
  Future<void> setTyping(String chatId, String myUid, bool typing) async {
    try {
      if (typing) {
        await fb.rtdbSet("typing/$chatId/$myUid", DateTime.now().millisecondsSinceEpoch);
      } else {
        await fb.rtdbDelete("typing/$chatId/$myUid");
      }
    } catch (_) {}
  }

  Stream<int> watchTyping(String chatId, String myUid) async* {
    Timer? clearTimer;
    int lastTs = 0;
    while (true) {
      try {
        final raw = await fb.rtdbGet("typing/$chatId");
        var typing = false;
        int newest = 0;
        if (raw is Map) {
          for (final e in raw.entries) {
            if (e.key.toString() == myUid) continue;
            final ts = e.value is int ? e.value as int : 0;
            if (ts > newest && DateTime.now().millisecondsSinceEpoch - ts < 5000) {
              newest = ts;
              typing = true;
            }
          }
        }
        if (typing != (lastTs > 0) || newest != lastTs) {
          lastTs = typing ? newest : 0;
          yield typing ? 1 : 0;
        }
      } catch (_) {}
      clearTimer ??= Timer.periodic(const Duration(seconds: 2), (_) {});
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  Stream<int> watchUnread(String myUid, String peerUid) async* {
    while (true) {
      try {
        final raw = await fb.rtdbGet("unread_counts/$myUid/$peerUid");
        yield raw is int ? raw : 0;
      } catch (_) {
        yield 0;
      }
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  /// Incoming-call watcher for the desktop port (RTDB `calls` tree).
  Stream<CallState> watchIncomingCalls(String myUid) async* {
    while (true) {
      try {
        final raw = await fb.rtdbGet("calls");
        if (raw is Map) {
          for (final e in raw.entries) {
            final v = e.value;
            if (v is Map) {
              final c = CallState.fromJson(Map<String, dynamic>.from(v));
              if (c.active && c.calleeId == myUid) {
                yield c;
                return;
              }
            }
          }
        }
      } catch (_) {}
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  Future<void> _createActivityNotification(
      String targetUid, String type, String targetId, String text) async {
    try {
      final base = workerRouter.resolve("database");
      final token = await fb.freshToken();
      final client = HttpClient();
      try {
        final endpoint = type == "message_request" || type == "message_accepted"
            ? "$base/auto-notify"
            : "$base/activity";
        final req = await client.postUrl(Uri.parse(endpoint));
        req.headers.contentType = ContentType.json;
        if (token != null) {
          req.headers.set(HttpHeaders.authorizationHeader, "Bearer $token");
        }
        req.write(jsonEncode({
          "targetUid": targetUid,
          "type": type,
          "targetId": targetId,
          "text": text,
          "device": "convo-desktop-${AppConfig.appVersion}",
        }));
        final res = await req.close();
        await res.drain<void>();
      } finally {
        client.close();
      }
    } catch (_) {}
  }

  /// Worker reports flow (SecurityUi + admin parity).
  Future<bool> submitUserReport(
      String targetUid, String category, String description) async {
    final base = workerRouter.resolve("database");
    final token = await fb.freshToken();
    final res = await _workerPost("$base/reports/create", {
      "targetUid": targetUid,
      "category": category,
      "description": description,
    }, token);
    return res["error"] == null;
  }

  Future<List<UserReport>> loadAdminReports(String base) async {
    final token = await fb.freshToken();
    final res = await _workerGet("$base/admin/reports/list", token);
    if (res["error"] != null) return const [];
    final arr = res["reports"] as List? ?? [];
    return arr
        .map((e) => UserReport.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Device session listing (SecurityUi "active sessions" port).
  Future<List<SessionInfo>> listSessions(String deviceBase) async {
    final token = await fb.freshToken();
    final res = await _workerPost("$deviceBase/sessions/list",
        {"device": "convo-desktop-${AppConfig.appVersion}"}, token);
    if (res["error"] != null) return const [];
    final arr = res["sessions"] as List? ?? [];
    return arr
        .map((e) => SessionInfo.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

Future<Map<String, dynamic>> _workerPost(
    String url, Map<String, dynamic> body, String? token) async {
  final client = HttpClient();
  try {
    final req = await client.postUrl(Uri.parse(url));
    req.headers.contentType = ContentType.json;
    if (token != null) {
      req.headers.set(HttpHeaders.authorizationHeader, "Bearer $token");
    }
    req.write(jsonEncode(body));
    final res = await req.close();
    final text = await _readBody(res);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      try {
        return Map<String, dynamic>.from(jsonDecode(text) as Map);
      } catch (_) {
        return {"ok": true};
      }
    }
    return {"error": "HTTP ${res.statusCode}: $text"};
  } catch (e) {
    return {"error": e.toString()};
  } finally {
    client.close();
  }
}

Future<Map<String, dynamic>> _workerGet(String url, String? token) async {
  final client = HttpClient();
  try {
    final req = await client.getUrl(Uri.parse(url));
    if (token != null) {
      req.headers.set(HttpHeaders.authorizationHeader, "Bearer $token");
    }
    final res = await req.close();
    final text = await _readBody(res);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      try {
        return Map<String, dynamic>.from(jsonDecode(text) as Map);
      } catch (_) {
        return {"ok": true};
      }
    }
    return {"error": "HTTP ${res.statusCode}: $text"};
  } catch (e) {
    return {"error": e.toString()};
  } finally {
    client.close();
  }
}

Future<String> _readBody(HttpClientResponse res) async {
  try {
    return await res.transform(utf8.decoder).join();
  } catch (_) {
    return "";
  }
}

extension<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}

/// The Android `chatIdWith` rule, kept as a named API for tests and UI.
class ChatId {
  static String of(String a, String b) => ([a, b]..sort()).join("_");
}

final chatRepository = ChatRepository();
