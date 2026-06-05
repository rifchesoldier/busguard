import 'package:flutter_test/flutter_test.dart';
import 'package:busguard/main.dart';

void main() {
  testWidgets('BusGuard app smoke test', (tester) async {
    await tester.pumpWidget(const BusGuardApp());
    expect(find.text('BusGuard'), findsOneWidget);
  });
}
