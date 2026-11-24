import 'package:flutter_test/flutter_test.dart';

import 'package:convo_chat/data/chat_repository.dart';
import 'package:convo_chat/data/models.dart';
import 'package:convo_chat/data/worker_router.dart';

void main() {
  test('User model round-trips the Android wire format', () {
    final u = User(uid: "abc", name: "Demo", friends: ["x"], isOnline: true);
    final j = u.toJson();
    expect(j['uid'], 'abc');
    expect(j['friends'], ['x']);
    final back = User.fromJson(j);
    expect(back.name, 'Demo');
    expect(back.isOnline, true);
  });

  test('Message visibility honours expiresAt', () {
    final alive = Message(messageId: "m1", text: "hi", expiresAt: 0);
    final gone = Message(
        messageId: "m2",
        text: "hi",
        expiresAt: DateTime.now().millisecondsSinceEpoch - 1000);
    expect(alive.visible, isTrue);
    expect(gone.visible, isFalse);
  });

  test('chatId matches the Android sorted-uid rule', () {
    final a = ChatId.of("zeta", "alpha");
    expect(a, "alpha_zeta");
  });

  test('worker router falls back to the canonical primary', () {
    expect(WorkerRouter.canonicalPrimary,
        'https://convo-chat-companion.mr4425390.workers.dev');
    expect(WorkerRouter.isRetired('https://solitary-hill-dcdc.workers.dev'), isTrue);
  });
}
