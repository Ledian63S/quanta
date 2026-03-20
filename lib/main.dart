import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'models/quanta_state.dart';
import 'theme/app_theme.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(430, 860),
      minimumSize: Size(430, 860),
      maximumSize: Size(430, 860),
      center: true,
      titleBarStyle: TitleBarStyle.hidden,
      title: 'Quanta',
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      if (Platform.isMacOS) {
        await windowManager.setTitleBarStyle(
          TitleBarStyle.hidden,
          windowButtonVisibility: false,
        );
      }
      await windowManager.setResizable(false);
      await windowManager.show();
      await windowManager.focus();
    });
  }

  final state = QuantaState();
  await state.load();
  runApp(
    ChangeNotifierProvider.value(
      value: state,
      child: const QuantaApp(),
    ),
  );
}

class QuantaApp extends StatelessWidget {
  const QuantaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<QuantaState>().themeMode;
    return MaterialApp(
      title: 'Quanta',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      themeAnimationDuration: Duration.zero,
      home: const _ThemeFade(child: MainShell()),
    );
  }
}

class _ThemeFade extends StatefulWidget {
  final Widget child;
  const _ThemeFade({required this.child});
  @override
  State<_ThemeFade> createState() => _ThemeFadeState();
}

class _ThemeFadeState extends State<_ThemeFade>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  QuantaState? _state;
  ThemeMode? _lastMode;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, value: 1.0,
        duration: const Duration(milliseconds: 300));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _state?.removeListener(_onChanged);
    _state = context.read<QuantaState>()..addListener(_onChanged);
    _lastMode ??= _state!.themeMode;
  }

  void _onChanged() {
    if (!mounted) return;
    final mode = _state!.themeMode;
    if (mode != _lastMode) {
      _lastMode = mode;
      _ctrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _state?.removeListener(_onChanged);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _ctrl, child: widget.child);
  }
}
