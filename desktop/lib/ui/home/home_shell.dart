import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/chat_repository.dart';
import '../../data/firebase_rest.dart';
import '../../data/models.dart';
import '../../state/auth_controller.dart';
import '../chat/chat_screen.dart';
import '../settings/settings_screen.dart';
import '../theme.dart';

/// Desktop-adapted port of HomeScreen.kt: left navigation rail (Chats, Stories,
/// Friends, Settings), conversation list synchronized with RTDB + Firestore,
/// right pane hosts the selected chat. Layout adapts at >=1280x720.
class HomeShell extends StatefulWidget {
  final AuthController auth;
  const HomeShell({super.key, required this.auth});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int navIndex = 0;
  List<User> friends = [];
  Timer? _poll;
  User? _selected;
  Map<String, int> _unread = {};

  AuthController get auth => widget.auth;

  @override
  void initState() {
    super.initState();
    _refresh();
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (auth.uid == null) return;
    try {
      final raw = await firestore.getDoc("users", auth.uid!) ?? const {};
      final me = User.fromJson(raw, uid: auth.uid!);
      final loaded = <User>[];
      for (final f in me.friends) {
        try {
          final d = await firestore.getDoc("users", f) ?? const {};
          if (d.isNotEmpty) loaded.add(User.fromJson(d, uid: f));
        } catch (_) {}
      }
      final unread = <String, int>{};
      for (final f in loaded) {
        try {
          final v = await firebase.rtdbGet("unread_counts/${auth.uid}/${f.uid}");
          unread[f.uid] = v is int ? v : 0;
        } catch (_) {
          unread[f.uid] = 0;
        }
      }
      final requests = await firestore.listDocs("message_requests");
      final myIncoming =
          requests.where((e) => e.$2["recipientId"] == auth.uid).length;
      if (!mounted) return;
      setState(() {
        if (friends.length != loaded.length && _selected == null && loaded.isNotEmpty) {
          _selected = loaded.first;
        }
        friends = loaded;
        _unread = unread;
        pendingRequests = myIncoming;
      });
      await auth.reloadMe();
    } catch (_) {}
  }

  void selectChat(User? user) => setState(() {
        _selected = user;
        navIndex = 0;
      });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final compact = size.width < 1000;
    return Scaffold(
      backgroundColor: Aurora.ink950,
      body: Row(
        children: [
          SizedBox(
            width: 72,
            child: NavigationRail(
              backgroundColor: Aurora.ink900,
              selectedIndex: navIndex,
              onDestinationSelected: (i) => setState(() => navIndex = i),
              labelType: NavigationRailLabelType.all,
              destinations: [
                NavigationRailDestination(
                    icon: _badge(const Icon(Icons.chat_bubble_outline), null),
                    selectedIcon: _badge(const Icon(Icons.chat_bubble), null),
                    label: const Text("Chats")),
                NavigationRailDestination(
                    icon: _badge(const Icon(Icons.person_outline), null),
                    selectedIcon: _badge(const Icon(Icons.person), null),
                    label: const Text("Friends")),
                NavigationRailDestination(
                    icon: _badge(const Icon(Icons.auto_awesome), null),
                    label: const Text("Stories")),
                NavigationRailDestination(
                    icon: _badge(const Icon(Icons.settings_outlined), pendingRequests),
                    selectedIcon: _badge(const Icon(Icons.settings), pendingRequests),
                    label: const Text("Settings")),
              ],
            ),
          ),
          SizedBox(
            width: compact ? 280 : 340,
            child: _listPane(),
          ),
          Expanded(child: _contentPane()),
        ],
      ),
    );
  }

  Widget _badge(Widget icon, int? count) => count == null || count == 0
      ? icon
      : Badge(label: Text("$count"), child: icon);

  Widget _listPane() {
    switch (navIndex) {
      case 0:
        return _chatList();
      case 1:
        return _friendList();
      case 2:
        return _storiesPane();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _chatList() {
    return Container(
      color: Aurora.ink900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text("Convo Chat — ${auth.me?.name ?? ''}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: friends.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        "No chats yet.\nAdd friends to start chatting.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Aurora.mist700),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: friends.length,
                    itemBuilder: (c, i) {
                      final f = friends[i];
                      final unread = _unread[f.uid] ?? 0;
                      final selected =
                          _selected != null && _selected!.uid == f.uid;
                      return ListTile(
                        selected: selected,
                        selectedTileColor: Aurora.violet.withOpacity(.15),
                        leading: CircleAvatar(
                          backgroundColor: Aurora.ink800,
                          backgroundImage: f.profileImageUrl.isNotEmpty
                              ? NetworkImage(f.profileImageUrl)
                              : null,
                          child: f.profileImageUrl.isEmpty
                              ? Text(f.name.isNotEmpty ? f.name[0].toUpperCase() : "?")
                              : null,
                        ),
                        title: Text(f.name),
                        subtitle: Text(
                          f.isOnline ? "Online" : _lastSeen(f),
                          style: TextStyle(
                              color: f.isOnline ? Aurora.success : Aurora.mist700),
                        ),
                        trailing: unread > 0
                            ? Badge(label: Text("$unread"))
                            : null,
                        onTap: () => selectChat(f),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _lastSeen(User u) {
    if (u.lastActive <= 0) return "offline";
    final dt = DateTime.fromMillisecondsSinceEpoch(u.lastActive);
    return "last seen ${dt.day}/${dt.month}";
  }

  Widget _friendList() {
    return Container(
      color: Aurora.ink900,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text("Friends",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: friends.length,
              itemBuilder: (c, i) {
                final f = friends[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Aurora.ink800,
                    backgroundImage: f.profileImageUrl.isNotEmpty
                        ? NetworkImage(f.profileImageUrl)
                        : null,
                    child: f.profileImageUrl.isEmpty
                        ? Text(f.name.isNotEmpty ? f.name[0].toUpperCase() : "?")
                        : null,
                  ),
                  title: Text(f.name),
                  subtitle: Text("@${f.username}",
                      style: TextStyle(color: Aurora.mist700)),
                  trailing: OutlinedButton(
                    onPressed: () => selectChat(f),
                    child: const Text("Chat"),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int pendingRequests = 0;

  Widget _storiesPane() {
    return Container(
      color: Aurora.ink900,
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 40, color: Aurora.violet),
            SizedBox(height: 12),
            Text(
              "Convo Stories view is streaming from the same Firestore\n"
              "\"stories\" collection used by Android.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _contentPane() {
    if (navIndex == 3) {
      return SettingsScreen(
          uid: auth.uid ?? "", auth: auth, onChanged: _onSettingsChanged);
    }
    if (navIndex == 2) {
      return StoriesPane(auth: auth, onOpenChat: selectChat);
    }
    if (_selected == null) {
      return const Center(
        child: Text("Select a chat to start messaging"),
      );
    }
    return ChatScreen(
      key: ValueKey("chat-${_selected!.uid}"),
      me: auth.me!,
      recipient: _selected!,
      repository: chatRepository,
    );
  }

  void _onSettingsChanged() {
    _refresh();
  }
}

/// Stories pane: lists the Firestore `stories` collection (identical query).
class StoriesPane extends StatefulWidget {
  final AuthController auth;
  final void Function(User)? onOpenChat;

  const StoriesPane({super.key, required this.auth, this.onOpenChat});

  @override
  State<StoriesPane> createState() => _StoriesPaneState();
}

class _StoriesPaneState extends State<StoriesPane> {
  List<Story> stories = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final docs = await firestore.listDocs("stories", limit: 100);
      final out = docs
          .map((d) => Story.fromJson(Map<String, dynamic>.from(d.$2), id: d.$1))
          .where((s) =>
              s.senderId.isEmpty ||
              widget.auth.me?.friends.contains(s.senderId) == true ||
              s.senderId == widget.auth.uid)
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      if (mounted) setState(() => stories = out);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty) {
      return const Center(child: Text("No stories right now"));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 260, childAspectRatio: .8),
      itemCount: stories.length,
      itemBuilder: (c, i) {
        final s = stories[i];
        return Card(
          color: Aurora.ink900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: s.imageUrl.isNotEmpty
                    ? Image.network(s.imageUrl,
                        fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(
                            color: Aurora.ink800,
                            child: const Center(
                                child: Icon(Icons.image,
                                    size: 40, color: Aurora.mist700))))
                    : Container(
                        color: Aurora.ink800,
                        child: Center(
                            child: Text(
                          s.text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        )),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.senderName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text("${s.reactions.length} reactions",
                        style: TextStyle(color: Aurora.mist700, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
