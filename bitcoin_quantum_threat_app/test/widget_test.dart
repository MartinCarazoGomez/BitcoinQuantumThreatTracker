import 'package:flutter_test/flutter_test.dart';

import 'package:bitcoin_quantum_threat_tracker/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const BitcoinQuantumApp());
    expect(find.text('Home'), findsOneWidget);
  });
}
