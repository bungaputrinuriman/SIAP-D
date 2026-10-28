import 'package:flutter_test/flutter_test.dart';
import 'package:si_pkl_diskominfo/main.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SiPklApp());

    // Verify app renders AuthWrapper / Login screen title
    expect(find.text('SI-PKL DISKOMINFO'), findsOneWidget);
  });
}
