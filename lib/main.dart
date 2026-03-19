import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/quanta_state.dart';
import 'theme/app_theme.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    return MaterialApp(
      title: 'Quanta',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      home: const MainShell(),
    );
  }
}
