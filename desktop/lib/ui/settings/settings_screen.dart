import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../data/firebase_rest.dart';
import '../../data/worker_router.dart';
import '../../security/app_lock.dart';
import '../../state/auth_controller.dart';
import '../theme.dart';

/// Desktop port of SettingsUi.kt / SecurityUi.kt essentials: profile summary,
/// app lock (PIN), device sessions list, user report and sign-out.
class SettingsScreen extends StatefulWidget {
  final String uid;
  final AuthController auth;
  final VoidCallback onChanged;

  const SettingsScreen({
    super.key,
    required this.uid,
    required this.auth,
    required this.onChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool lockEnabled = false;
  List<String> sessions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    lockEnabled = await AppLock.isEnabled();
    try {
      final base = workerRouter.resolve("database");
      final token = await firebase.freshToken();
      final res = await _post("$base/sessions/list", {"uid": widget.uid}, token);
      final ss = (res["sessions"] as List? ?? [])
          .map((e) => (e as Map)["device"]?.toString() ?? e.toString())
          .toList();
      setState(() => sessions = ss);
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<Map<String, dynamic>> _post(
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
      final text = await utf8.decoder.bind(res).join();
      if (res.statusCode >= 200 && res.statusCode < 300 && text.isNotEmpty) {
        try {
          return Map<String, dynamic>.from(jsonDecode(text) as Map);
        } catch (_) {}
      }
      return {"error": "HTTP ${res.statusCode}"};
    } catch (e) {
      return {"error": "$e"};
    } finally {
      client.close();
    }
  }

  Future<void> _toggleLock() async {
    if (lockEnabled) {
      await AppLock.clearPin();
      setState(() => lockEnabled = false);
      return;
    }
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Aurora.ink900,
        title: const Text("Set a 4-6 digit PIN"),
        content: TextField(
          controller: controller,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "PIN"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Save")),
        ],
      ),
    );
    if (ok == true && controller.text.length >= 4 && controller.text.length <= 6) {
      await AppLock.setPin(controller.text);
      setState(() => lockEnabled = true);
    }
  }

  Future<void> _report() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Aurora.ink900,
        title: const Text("Report a problem to ADMIN RAKIB"),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(hintText: "Describe the issue"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Send")),
        ],
      ),
    );
    if (ok != true || controller.text.trim().isEmpty) return;
    final base = workerRouter.resolve("database");
    final token = await firebase.freshToken();
    final res = await _post("$base/reports/create", {
      "targetUid": widget.uid,
      "category": "desktop_report",
      "description": controller.text.trim(),
    }, token);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              res["error"] == null ? "Report sent to ADMIN RAKIB" : "Report failed")));
    }
  }

  Future<void> _signOut() async {
    await widget.auth.signOut(clearRemembered: true);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const Text("Settings",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text("Convo Desktop ${AppConfig.appVersion} (${AppConfig.packageName})",
            style: TextStyle(color: Aurora.mist700)),
        const SizedBox(height: 24),
        _card(
          title: "App lock",
          subtitle: "Require a PIN at launch",
          trailing: Switch(value: lockEnabled, onChanged: (_) => _toggleLock()),
        ),
        _card(
          title: "Signed in as",
          subtitle: widget.auth.me?.name ?? "",
        ),
        _card(
          title: "Active sessions",
          subtitle: sessions.isEmpty
              ? "Signed-in devices appear here"
              : sessions.join(", "),
        ),
        _card(
          title: "Report a problem",
          subtitle: "Send a report to ADMIN RAKIB",
          trailing: OutlinedButton(onPressed: _report, child: const Text("Report")),
        ),
        _card(
          title: "Sign out",
          subtitle: "Clears the remembered desktop session",
          trailing: OutlinedButton(
              style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF5C5C)),
              onPressed: _signOut,
              child: const Text("Sign out")),
        ),
      ],
    );
  }

  Widget _card({required String title, dynamic subtitle, Widget? trailing}) => Card(
        color: Aurora.ink900,
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          title: Text(title),
          subtitle: subtitle is Widget ? subtitle : (subtitle == null ? null : Text('$subtitle')),
          trailing: trailing,
        ),
      );
}
