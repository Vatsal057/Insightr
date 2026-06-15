import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insightr/main.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const InsightrApp(showOnboarding: false));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
