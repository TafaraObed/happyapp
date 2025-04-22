// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:happyapp/main.dart';

void main() {
  testWidgets('Study Planner smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const StudyPlannerApp());

    // Verify that the title is displayed.
    expect(find.text('Study Planner'), findsOneWidget);

    // Verify that one of the initial study items is displayed.
    // We check for the first item in the placeholder list.
    expect(find.text('Prepare for Math Exam'), findsOneWidget);

    // Verify the FloatingActionButton is present
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
