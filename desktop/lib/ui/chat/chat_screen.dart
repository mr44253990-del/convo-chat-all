import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/chat_repository.dart';
import '../../data/models.dart';
import '../theme.dart';

/// Desktop-adapted port of ChatScreen.kt: full-height conversation pane with
/// top bar (recipient presence), message bubbles with sent/delivered/seen
/// ticks (MessageTicks.kt), reply composer and typing indicator.
class ChatScreen extends StatefulWidget {
  final User me;
  final User recipient;
  final ChatRepository repository;

  const ChatScreen({
    super.key,
    required this.me,
    required this.recipient,
    required this.repository,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _composer = TextEditingController();
  final _scroll = ScrollController();
  List<Message> messages = [];
  bool peerTyping = false;
  Timer? _typingStop;
  StreamSubscription? _msgSub;
  StreamSubscription? _typingSub;
  Message? _replyTarget;
  bool _sending = false;
  String? _errorBanner;

  String get chatId => ChatRepository.chatIdWith(widget.me.uid, widget.recipient.uid);

  @override
  void initState() {
    super.initState();
    _msgSub = widget.repository.watchMessages(chatId).listen((list) {
      if (mounted) {
        setState(() => messages = list);
        _autoScroll();
        _markSeen(list);
      }
    });
    _typingSub = widget.repository
        .watchTyping(chatId, widget.me.uid)
        .listen((t) {
      if (mounted) setState(() => peerTyping = t > 0);
    });
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _typingSub?.cancel();
    _typingStop?.cancel();
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _autoScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _markSeen(List<Message> list) async {
    await widget.repository.markSeen(chatId, widget.me.uid, list);
  }

  Future<void> _send() async {
    final text = _composer.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _errorBanner = null;
    });
    _composer.clear();
    final reply = _replyTarget;
    setState(() => _replyTarget = null);
    final sent = await widget.repository.sendMessage(
      me: widget.me,
      recipient: widget.recipient,
      text: text,
      replyToId: reply?.messageId,
      replyToText: reply?.text,
      replyToSenderName: reply?.senderName,
    );
    setState(() => _sending = false);
    if (sent == null) {
      setState(() => _errorBanner =
          "Not friends yet — a message request was sent to ${widget.recipient.name}.");
    }
  }

  void _onTyping() {
    widget.repository.setTyping(chatId, widget.me.uid, true);
    _typingStop?.cancel();
    _typingStop = Timer(const Duration(seconds: 4), () {
      widget.repository.setTyping(chatId, widget.me.uid, false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.recipient;
    return Container(
      color: Aurora.ink950,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Aurora.ink900,
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(.05))),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Aurora.ink800,
                  backgroundImage: r.profileImageUrl.isNotEmpty
                      ? NetworkImage(r.profileImageUrl)
                      : null,
                  child: r.profileImageUrl.isEmpty
                      ? Text(r.name.isNotEmpty ? r.name[0].toUpperCase() : "?")
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      Text(
                        peerTyping ? "typing…" : (r.isOnline ? "Online" : "offline"),
                        style: TextStyle(
                            color: peerTyping || r.isOnline
                                ? Aurora.success
                                : Aurora.mist700,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                    tooltip: "Call (requires a mobile companion)",
                    onPressed: null,
                    icon: const Icon(Icons.phone_disabled,
                        color: Aurora.mist700)),
                const SizedBox(width: 8),
                IconButton(
                    tooltip: "Video (requires a mobile companion)",
                    onPressed: null,
                    icon: const Icon(Icons.videocam_off,
                        color: Aurora.mist700)),
              ],
            ),
          ),
          if (_errorBanner != null)
            Container(
              width: double.infinity,
              color: Aurora.amber.withOpacity(.15),
              padding: const EdgeInsets.all(10),
              child: Text(
                _errorBanner!,
                style:
                    const TextStyle(fontSize: 12, color: Aurora.amber),
              ),
            ),
          Expanded(
            child: messages.isEmpty
                ? const Center(child: Text("Say hi 👋"))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (c, i) => _bubble(messages[i]),
                  ),
          ),
          if (_replyTarget != null)
            Container(
              color: Aurora.ink900,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Replying to ${_replyTarget!.senderName}: ${_replyTarget!.text}",
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _replyTarget = null),
                  ),
                ],
              ),
            ),
          SafeArea(
            child: Container(
              color: Aurora.ink900,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _composer,
                      onChanged: (_) => _onTyping(),
                      onSubmitted: (_) => _send(),
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Message ${r.name}…",
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: "Send",
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                    color: Aurora.violet,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(Message m) {
    final mine = m.senderId == widget.me.uid;
    final seen = m.seenByRecipient;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onDoubleTap: () => setState(() => _replyTarget = m),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: mine ? Aurora.violet : Aurora.ink800,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(mine ? 14 : 4),
                bottomRight: Radius.circular(mine ? 4 : 14),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (m.replyToId != null && (m.replyToText ?? "").isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${m.replyToSenderName ?? ""}: ${m.replyToText ?? ""}",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                if (m.text.isNotEmpty) Text(m.text),
                if (m.imageUrl != null && m.imageUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(m.imageUrl!,
                          width: 320,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox()),
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _time(m.timestamp),
                      style: TextStyle(
                          fontSize: 10, color: Colors.white.withOpacity(.6)),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      mine
                          ? (seen
                              ? Icons.done_all
                              : Icons.done)
                          : Icons.circle,
                      size: 14,
                      color: seen ? Aurora.cyan : Colors.white60,
                    ),
                    if (m.edited) ...[
                      const SizedBox(width: 4),
                      Text("(edited)",
                          style: TextStyle(fontSize: 10, color: Colors.white54)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _time(int ts) {
    if (ts <= 0) return "";
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
