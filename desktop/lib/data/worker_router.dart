import 'dart:math';

import '../core/app_config.dart';

/// Direct Dart port of app/src/main/java/com/example/data/WorkerRouter.kt:
/// smart multi-worker routing with weighted-random selection, health cooldown
/// and primary-worker fallback for every service byte the Android app routes.
class WorkerRouter {
  static const Duration cooldown = Duration(seconds: 120);

  static const List<WorkerService> services = [
    WorkerService("push", "Messages & push", "Chat/notification FCM delivery"),
    WorkerService("calls", "Calls", "Call ringing push, TURN credentials and SFU"),
    WorkerService("ai", "AI assistant", "/ai/chat requests"),
    WorkerService("storage", "Storage / media", "Uploads, deletes, reels media"),
    WorkerService("database", "Database & admin", "Sessions, reports, bans and other server writes"),
    WorkerService("location", "Live location", "Location share relays (reserved)"),
  ];

  final Map<String, DateTime> _down = {};
  final Set<String> _outdated = {};
  final List<WorkerNode> _nodes = [];

  /// The one canonical primary worker URL (WorkerHealth.DEFAULT_PRIMARY).
  static String get canonicalPrimary => AppConfig.defaultWorkerPrimary;

  /// True for retired primary URLs that must never stay primary.
  static bool isRetired(String url) {
    final host = url
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'^https?://'), '')
        .split('/')
        .first;
    return host.contains("solitary-hill-dcdc") ||
        host.endsWith(".mr44253990.workers.dev") ||
        host == "mr44253990.workers.dev";
  }

  bool isPrimary(String url) =>
      url.trim().replaceAll(RegExp(r'/+$'), "") == canonicalPrimary;

  void setOutdated(String url, bool value) {
    final c = url.trim().replaceAll(RegExp(r'/+$'), "");
    if (value && !isPrimary(c)) {
      _outdated.add(c);
    } else {
      _outdated.remove(c);
    }
  }

  bool isOutdated(String url) =>
      _outdated.contains(url.trim().replaceAll(RegExp(r'/+$'), ""));

  void setNodes(List<WorkerNode> nodes) => _nodes
    ..clear()
    ..addAll(nodes.where((n) => n.valid && !isPrimary(n.url)));

  void markDown(String url) {
    _down[url.trim().replaceAll(RegExp(r'/+$'), "")] = DateTime.now().add(cooldown);
  }

  bool resting(WorkerNode n) {
    final until = _down[n.url];
    return until != null && DateTime.now().isBefore(until);
  }

  /// Workers a request may go to right now: healthy first, resting ones last.
  List<String> candidates(String service) {
    final nodes = _nodes.where((n) => n.enabled).toList();
    final healthyNodes =
        nodes.where((n) => !resting(n) && n.valid).toList();
    final restingNodes = nodes.where((n) => resting(n)).toList();
    final all = <String>[canonicalPrimary, ...healthyNodes.map((n) => n.url)];
    final smart = _smartWeighted(all, healthyNodes);
    return [...smart, ...restingNodes.map((n) => n.url)];
  }

  List<String> _smartWeighted(List<String> all, List<WorkerNode> nodes) {
    final rnd = Random();
    final weighted = all.toList();
    final extras = nodes.where((n) => weighted.contains(n.url)).toList();
    if (extras.length < 2) {
      weighted.shuffle(rnd);
      return weighted;
    }
    for (var i = weighted.length - 1; i > 1; i--) {
      final node = extras.firstWhere((n) => n.url == weighted[i],
          orElse: () => WorkerNode("x", url: weighted[i]));
      final w = node.weight.clamp(1, 10);
      if (rnd.nextInt(w) == 0) continue;
      final j = 1 + rnd.nextInt(i);
      final tmp = weighted[i];
      weighted[i] = weighted[j];
      weighted[j] = tmp;
    }
    return weighted;
  }

  /// Resolve the first live URL for a service; falls back to the primary.
  String resolve(String service) {
    final c = candidates(service);
    return c.isNotEmpty ? c.first : canonicalPrimary;
  }
}

class WorkerService {
  final String key;
  final String label;
  final String description;
  const WorkerService(this.key, this.label, this.description);
}

class WorkerNode {
  final String id;
  final String label;
  final String url;
  final bool enabled;
  final Set<String> services;
  final int weight;

  const WorkerNode(this.id,
      {this.label = "",
      this.url = "",
      this.enabled = true,
      this.services = const {},
      this.weight = 1});

  bool get valid =>
      url.toLowerCase().startsWith("https://") && url.length > 12;
}

final WorkerRouter workerRouter = WorkerRouter();
