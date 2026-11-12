import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_house/main.dart';

void main() {
  testWidgets('App renders HomeScreen without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GreenHouseApp());
    expect(find.byType(Scaffold), findsWidgets);
  });
}
