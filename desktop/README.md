# Convo Chat — Desktop (Windows & Linux)

Flutter Desktop port of the Convo Chat Android app (`app/`). It talks to the
exact same backend as Android — Firebase Auth, Firebase Realtime Database
(`chat-4e1d0-default-rtdb.asia-southeast1`), Firestore (`chat-4e1d0`) and the
Cloudflare Worker (`convo-chat-companion.mr4425390.workers.dev`) — with the same
wire payloads, so desktop and Android share accounts, chats and media.

## Build (Linux)

```bash
sudo apt-get install -y ninja-build libgtk-3-dev pkg-config clang cmake
cd desktop
flutter pub get
flutter build linux --release
# Output: build/linux/x64/release/bundle/convo_chat
```

## Build (Windows)

```powershell
# Visual Studio 2022 with "Desktop development with C++" workload required
cd desktop
flutter pub get
flutter build windows --release
# Output: build\windows\x64\runner\Release\convo_chat.exe
```

## Run from source

```bash
cd desktop && flutter run -d linux   # or -d windows
```

## Architecture

| Android source (Kotlin) | Desktop port (Dart) |
| --- | --- |
| `data/Models.kt` | `lib/data/models.dart` (1:1 fields) |
| `data/WorkerRouter.kt`, `data/WorkerHealth.kt` | `lib/data/worker_router.dart` (smart routing, cooldown, retired hosts) |
| Firebase SDK (RTDB/Firestore/Auth) | `lib/data/firebase_rest.dart` (REST + SSE; no desktop Firebase plugins exist) |
| `ui/ChatViewModel.kt` (send/receipts/typing/presence) | `lib/data/chat_repository.dart` + `lib/state/auth_controller.dart` |
| `ui/AuthScreen.kt` | `lib/ui/auth/auth_screen.dart` |
| `ui/HomeScreen.kt` | `lib/ui/home/home_shell.dart` (desktop-adaptive rail layout) |
| `ui/ChatScreen.kt` + `ui/MessageTicks.kt` | `lib/ui/chat/chat_screen.dart` |
| `ui/theme/Color.kt` / `Theme.kt` | `lib/ui/theme.dart` |
| `security/AppLock.kt` | `lib/security/app_lock.dart` |

CI builds both OSes on every change: `.github/workflows/desktop-build.yml`
(artifacts: `convo-desktop-windows-x64.zip`, `convo-desktop-linux-x64.tar.gz`
including a `.desktop` entry and install notes).

See `docs/desktop-feature-parity.md` for the full feature mapping, platform
limitations, and the honest list of Android-only behaviors.
