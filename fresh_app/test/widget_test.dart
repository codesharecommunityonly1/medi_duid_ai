import 'package:flutter_test/flutter_test.dart';
import 'package:mediguide_ai/app.dart';

void main() {
  testWidgets('MediGuide AI app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MediGuideApp());
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });
}
