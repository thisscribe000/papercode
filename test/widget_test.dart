import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papercode/widgets/bottom_nav.dart';

void main() {
  testWidgets('Bottom nav exposes primary workspace flow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNav(currentIndex: 0, onTap: (_) {}),
        ),
      ),
    );

    expect(find.text('Workspace'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Terminal'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Files'), findsNothing);
  });
}
