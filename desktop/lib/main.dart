import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'core/app_config.dart';
import 'security/app_lock.dart';
import 'state/auth_controller.dart';
import 'ui/auth/auth_screen.dart';
import 'ui/home/home_shell.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  final options = const WindowOptions(
    size: Size(AppConfig.defaultWidth, AppConfig.defaultHeight),
    minimumSize: Size(AppConfig.minWidth, AppConfig.minHeight),
    center: true,
    title: AppConfig.appName,
    backgroundColor: Color(0xFF06070B),
    titleBarStyle: TitleBarStyle.normal,
  );
  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  runApp(const ConvoDesktopApp());
}

class ConvoDesktopApp extends StatelessWidget {
  const ConvoDesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: buildConvoTheme(),
      home: const _RootGate(),
    );
  }
}

/// Splash → AppLock gate → Auth/Home routing (Android ConvoApp flow).
class _RootGate extends StatefulWidget {
  const _RootGate();

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  final auth = AuthController();
  bool restored = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await auth.tryRestoreSession();
    setState(() => restored = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!restored) return const _Splash();
    return AnimatedBuilder(
      animation: auth,
      builder: (c, _) {
        Widget body = auth.signedIn
            ? HomeShell(auth: auth)
            : AuthScreen(auth: auth);
        return _LockGate(child: body);
      },
    );
  }
}

class _Splash extends StatefulWidget {
  const _Splash();

  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> {
  // SplashScreen.kt parity: branded splash while sessions restore.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06070B),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset("assets/convo_icon.png", height: 128, width: 128),
            const SizedBox(height: 24),
            const Text(
              AppConfig.appName,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFFF8F9FF)),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 200,
              child: LinearProgressIndicator(color: Color(0xFF7C5CFC)),
            ),
          ],
        ),
      ),
    );
  }
}

/// App lock gate: shown when a PIN is configured (AppLock.kt port).
class _LockGate extends StatefulWidget {
  final Widget child;
  const _LockGate({required this.child});

  @override
  State<_LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<_LockGate> {
  bool? locked;

  @override
  void initState() {
    super.initState();
    AppLock.isEnabled().then((v) => setState(() => locked = v));
  }

  @override
  Widget build(BuildContext context) {
    if (locked == null) return const SizedBox.shrink();
    if (locked == false) return widget.child;
    return _PinPrompt(
      onUnlocked: () => setState(() => locked = false),
      child: widget.child,
    );
  }
}

class _PinPrompt extends StatefulWidget {
  final VoidCallback onUnlocked;
  final Widget child;

  const _PinPrompt({required this.onUnlocked, required this.child});

  @override
  State<_PinPrompt> createState() => _PinPromptState();
}

class _PinPromptState extends State<_PinPrompt> {
  final controller = TextEditingController();
  String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Card(
            color: const Color(0xFF0C0E15),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock, size: 40, color: Color(0xFF7C5CFC)),
                  const SizedBox(height: 14),
                  const Text("Enter your PIN"),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    obscureText: true,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(hintText: "PIN", errorText: error),
                    onSubmitted: _check,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => _check(controller.text), child: const Text("Unlock")),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _check(String pin) async {
    final ok = await AppLock.verify(pin);
    if (ok) {
      widget.onUnlocked();
    } else {
      controller.clear();
      setState(() => error = "Wrong PIN");
    }
  }
}
