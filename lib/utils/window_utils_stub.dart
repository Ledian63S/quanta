import 'package:flutter/widgets.dart';

Future<void> setupWindow() async {}
Future<void> closeWindow() async {}
Future<void> minimizeWindow() async {}
Future<void> zoomWindow() async {}
bool isNativeMacOS() => false;

class DragToMoveArea extends StatelessWidget {
  final Widget child;
  const DragToMoveArea({super.key, required this.child});
  @override
  Widget build(BuildContext context) => child;
}
