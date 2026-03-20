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
      size: Size(430, 780),
      minimumSize: Size(430, 700),
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
      home: const MainShell(),
    );
  }
}
