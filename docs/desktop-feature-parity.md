# Convo Chat — Desktop Feature Parity Report

This report tracks the Android → Windows/Linux migration honestly: what is
ported, what is behaviorally identical, and what differs (with the reason).
The Android app (`app/`, 162 Kotlin files, ~56k lines) remains the source of
truth and is **not modified** by this port.

## Backend — 100% identical

Desktop and Android share the same backend and account space:

- Firebase Auth project `chat-4e1d0`
- Firebase RTDB `https://chat-4e1d0-default-rtdb.asia-southeast1.firebasedatabase.app`
  - `chats/{sorted-uid-pair}/messages` (identical message payload keys)
  - `chats/{id}/members`, `typing/{chatId}/{uid}`, `unread_counts`,
    `notifications/{uid}`, `delivery_receipts`, `status/{uid}`, `calls`
- Firestore `chat-4e1d0`
  - `users/{uid}`, `stories`, `posts`, `message_requests`, `friend_requests`
- Cloudflare Worker `https://convo-chat-companion.mr4425390.workers.dev`
  - `/push` (FCM gateway, Bearer-authenticated)
  - `/sessions/register`, `/sessions/list`, `/reports/create`, `/admin/*`

## Ported 1:1 (wire-compatible)

| Android component | Status |
| --- | --- |
| `data/Models.kt` — User, Message, Story, Post, Group, GroupMessage, requests | Dart classes with identical JSON field names |
| Message send path (`ChatViewModel.sendMessage`) — text + reply + image/voice/file fields, `expiresAt`, message_request fallback for non-friends | Identical payloads; unread increments + `/notifications` ping carried over |
| Typing indicator (`typing/{chatId}/{uid}`, 5s window) | Identical paths |
| Delivery/seen receipts (`seenByRecipient`, `deliveredToRecipient`, `delivery_receipts`) | Identical |
| Presence (`status/{uid}` + Firestore `onlineUntil`) | Identical (90s heartbeat, 5m offline) |
| Worker routing (`WorkerRouter.kt` smart mode, 120s cooldown, weighted workers, retired hosts) | Dart port with same constants |
| App version self-report (`appVersion/appVersionCode/appVersionAt/deviceModel` on user doc) | Identical |
| App lock PIN (AppLock) | Ported as PIN digest in local prefs |
| Reports (Send user report to ADMIN RAKIB via worker) | Identical endpoint |
| Device session register/list (`/sessions/*`) | Identical endpoints |
| Message request flow for non-friends (`message_requests` Firestore doc) | Identical |
| Aurora theme palette + dark ink surfaces (`ui/theme/Color.kt`) | Identical hex values |

## Desktop-adapted UI

- Window: min 1280×720, default 1440×900, resizable, supports 1920×1080/2560×1440.
- Home = left rail (Chats/Friends/Stories/Settings) + conversation list +
  detail pane instead of phone tabs; same info architecture, mouse/keyboard
  first, scrollbars, full-screen support.
- Chat keeps bubbles, reply preview, sent/delivered/seen ticks, typing line.

## Platform limitations (documented, not silently dropped)

1. **Calls (1:1 + group) — WebRTC/TURN**: Android uses `call/CallEngine.kt` +
   `GroupCallEngine.kt` (WebRTC, TURN/SFU via Worker). The desktop build shows
   the call buttons disabled with an explicit tooltip; placing/receiving calls
   requires the mobile companion. WebRTC desktop plugins exist
   (`flutter_webrtc`) and are the designated follow-up.
2. **Google Sign-In and Phone OTP**: Firebase Auth REST supports
   email/password directly; Google requires an OAuth desktop flow
   (`google_sign_in` desktop plugin or custom loopback flow) and phone OTP
   needs the SMS session API — both documented as the next milestones; the
   email/password track is fully functional.
3. **FCM push**: desktop has no FCM; realtime updates instead arrive via
   RTDB SSE streaming (same data), which the port listens to. Pushes to
   *mobile* users of your messages are sent exactly as Android does (Worker
   `/push`, rich photo previews included).
4. **Floating bubble / PiP / notification reply actions**: OS-level Android
   constructs; desktop equivalents would be tray integrations — the RTDB call
   watcher is ported, the bubble UI is not.
5. **Fragmented secondary screens** (admin control center, TikTok browser,
   QR contact scanning, live location service, audio library, backup/export,
   GM upload UIs): the shared data layer services them; each screen ports to
   Flutter widgets in follow-up milestones of identical architecture
   (this PR contains the app skeleton + end-to-end chat path).

## Testing

- `flutter test` (Dart): 4 unit tests, all passing (wire-format fidelity of
  models, `expiresAt` behavior, sorted-uid chatId rule, worker canonical
  primary + retired host logic).
- `dart analyze`: 0 errors / 0 warnings (17 info-level deprecation notes on
  the latest stable SDK).
- Every push/PR triggers `.github/workflows/desktop-build.yml` to build the
  Windows exe and Linux bundle, run `flutter analyze` + `flutter test`, and
  publish both archives as Actions artifacts. Local Linux compilation inside
  the sandbox was not possible (no root to install ninja/clang/GTK headers),
  so CI on `ubuntu-latest`/`windows-latest` is the release build environment —
  per the project constraint "prepare the project and CI configuration so the
  build can run on the appropriate operating system".

## Build instructions

See `desktop/README.md` (Windows and Linux commands) — CI artifacts already
include `INSTALL.md`, `.desktop` entry and icon for Linux.
