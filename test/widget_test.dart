import 'package:flutter_test/flutter_test.dart';
import 'package:syno_quiz_game/main.dart';  // ensure this matches your package name

void main() {
  testWidgets('App launches without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SynoSRSApp());

    // Verify that the home screen title is displayed.
    expect(find.text('🎯 Syno Quiz Game'), findsOneWidget);
  });
}
