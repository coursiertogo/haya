import 'package:flutter_test/flutter_test.dart';
import 'package:haya/main.dart';

void main() {
  testWidgets('Haya app test', (WidgetTester tester) async {
    await tester.pumpWidget(const HayaApp());
    expect(find.text('haya'), findsOneWidget);
  });
}
