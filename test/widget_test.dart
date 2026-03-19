import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quanta/main.dart';
import 'package:quanta/models/quanta_state.dart';

void main() {
  testWidgets('Quanta app smoke test', (WidgetTester tester) async {
    final state = QuantaState();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const QuantaApp(),
      ),
    );
    expect(find.text('Quanta'), findsOneWidget);
  });
}
