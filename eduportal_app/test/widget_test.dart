// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:eduportal_app/main.dart';

void main() {
  testWidgets('EduPortalApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EduPortalApp());
    expect(find.byType(EduPortalApp), findsOneWidget);
  });
}
