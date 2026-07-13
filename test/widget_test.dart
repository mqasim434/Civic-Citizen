import 'package:civic_citizen/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppButton renders its label', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            label: 'Sign in',
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Sign in'), findsOneWidget);
  });
}
