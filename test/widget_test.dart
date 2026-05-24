import 'package:flutter_test/flutter_test.dart';
import 'package:papercode/main.dart';

void main() {
  testWidgets('App renders connect screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PaperCodeApp());
    expect(find.text('Connect Screen'), findsOneWidget);
  });
}
