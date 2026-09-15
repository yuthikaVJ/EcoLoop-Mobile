import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eco_loop/core/theme/app_theme.dart';
import 'package:eco_loop/features/business_hub/presentation/pages/create_business_profile_page.dart';

void main() {
  testWidgets('Create Business Profile form renders inputs and validates fields',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const CreateBusinessProfilePage(),
      ),
    );


    // Verify AppBar title
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Create Business Profile'),
      ),
      findsOneWidget,
    );


    // Verify Business Identity section
    expect(find.text('Business Identity'), findsOneWidget);
    expect(find.text('Business / Company Name *'), findsOneWidget);
    expect(find.text('Registration Number (eROC/ROC) *'), findsOneWidget);

    final submitButtonFinder = find.widgetWithText(ElevatedButton, 'Create Business Profile');
    await tester.ensureVisible(submitButtonFinder);
    await tester.pumpAndSettle();
    expect(submitButtonFinder, findsOneWidget);

    // Tap submit button with empty form to trigger validation
    await tester.tap(submitButtonFinder);
    await tester.pumpAndSettle();

    // Scroll back to top field
    final nameFieldFinder = find.text('Business / Company Name *');
    await tester.ensureVisible(nameFieldFinder);
    await tester.pumpAndSettle();


    // Verify validation error messages are displayed
    expect(find.text('Business name is required'), findsOneWidget);
    expect(find.text('Business registration number is required'), findsOneWidget);
  });
}


