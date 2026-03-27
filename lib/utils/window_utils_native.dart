import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

export 'package:window_manager/window_manager.dart' show DragToMoveArea;

Future<void> setupWindow() async {
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
}

Future<void> closeWindow() async => windowManager.close();
Future<void> minimizeWindow() async => windowManager.minimize();
bool isNativeMacOS() => Platform.isMacOS;
