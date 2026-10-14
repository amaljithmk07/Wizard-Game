import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizard_flutter/main.dart';

void main() {
  testWidgets('WizardApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: WizardApp(),
      ),
    );
    expect(find.text('WIZARD'), findsOneWidget);
  });
}
