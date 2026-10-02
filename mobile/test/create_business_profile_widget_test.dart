import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eco_loop/core/theme/app_theme.dart';
import 'package:eco_loop/features/business_hub/presentation/pages/create_business_profile_page.dart';

void main() {
  testWidgets('Create Business Profile form renders inputs, profile media, and validates fields',
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

    // Verify Profile Media section is rendered with optional indicators and helpers
    expect(find.text('Profile Media'), findsOneWidget);
    expect(find.text('Optional'), findsOneWidget);
    expect(find.text('Add Cover'), findsOneWidget);
    expect(find.text('Upload'), findsOneWidget);
    expect(find.text('Add Cover Photo (Optional)'), findsOneWidget);
    expect(find.text('PNG or JPEG, less than 5 MB'), findsOneWidget);
    expect(find.text('PNG or JPEG. Less than 5 MB.'), findsOneWidget);

    // Verify Business Identity section
    expect(find.text('Business Identity'), findsOneWidget);
    expect(find.text('Business / Company Name *'), findsOneWidget);
    expect(find.text('Registration Number (eROC/ROC) *'), findsOneWidget);

    // Scroll to submit button using main scrollable
    final scrollableFinder = find.byType(Scrollable).first;
    final submitButtonFinder =
        find.widgetWithText(ElevatedButton, 'Create Business Profile');
    await tester.scrollUntilVisible(
      submitButtonFinder,
      300.0,
      scrollable: scrollableFinder,
    );
    await tester.pumpAndSettle();
    expect(submitButtonFinder, findsOneWidget);

    // Tap submit button with empty form to trigger validation
    await tester.tap(submitButtonFinder);
    await tester.pumpAndSettle();

    // Scroll back to top field
    final nameFieldFinder = find.text('Business / Company Name *');
    await tester.scrollUntilVisible(
      nameFieldFinder,
      -300.0,
      scrollable: scrollableFinder,
    );
    await tester.pumpAndSettle();

    // Verify validation error messages are displayed
    expect(find.text('Business name is required'), findsOneWidget);
    expect(find.text('Business registration number is required'), findsOneWidget);
  });

  testWidgets('Avatar initial updates dynamically when business name is typed',
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

    // Initial avatar placeholder is 'B'
    expect(find.text('B'), findsOneWidget);

    // Enter name starting with 'G'
    final nameFieldFinder =
        find.widgetWithText(TextFormField, 'Business / Company Name *');
    await tester.enterText(nameFieldFinder, 'Green Innovations');
    await tester.pump();

    // Avatar text updates to 'G'
    expect(find.text('G'), findsOneWidget);

    // Enter name starting with 'Z'
    await tester.enterText(nameFieldFinder, 'Zero Waste LK');
    await tester.pump();

    // Avatar text updates to 'Z'
    expect(find.text('Z'), findsOneWidget);
  });

  testWidgets('Phone number validation rejects < 10, > 10, and accepts exactly 10 numbers',
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

    final scrollableFinder = find.byType(Scrollable).first;
    final phoneFieldFinder =
        find.widgetWithText(TextFormField, 'Contact Phone *');

    // Scroll to phone field
    await tester.scrollUntilVisible(
      phoneFieldFinder,
      300.0,
      scrollable: scrollableFinder,
    );
    await tester.pumpAndSettle();

    final submitButtonFinder =
        find.widgetWithText(ElevatedButton, 'Create Business Profile');
    await tester.scrollUntilVisible(
      submitButtonFinder,
      300.0,
      scrollable: scrollableFinder,
    );
    await tester.pumpAndSettle();

    // 1. Submit empty -> Phone number is required
    await tester.tap(submitButtonFinder);
    await tester.pumpAndSettle();
    expect(find.text('Phone number is required'), findsOneWidget);

    // 2. Enter less than 10 numbers (e.g. 7 digits)
    await tester.scrollUntilVisible(
      phoneFieldFinder,
      -300.0,
      scrollable: scrollableFinder,
    );
    await tester.pumpAndSettle();
    await tester.enterText(phoneFieldFinder, '0771234');
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      submitButtonFinder,
      300.0,
      scrollable: scrollableFinder,
    );
    await tester.pumpAndSettle();
    await tester.tap(submitButtonFinder);
    await tester.pumpAndSettle();
    expect(find.text('Phone number must be exactly 10 digits'), findsOneWidget);

    // 3. Enter more than 10 numbers (e.g. 11 digits)
    await tester.scrollUntilVisible(
      phoneFieldFinder,
      -300.0,
      scrollable: scrollableFinder,
    );
    await tester.pumpAndSettle();
    await tester.enterText(phoneFieldFinder, '07712345678');
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      submitButtonFinder,
      300.0,
      scrollable: scrollableFinder,
    );
    await tester.pumpAndSettle();
    await tester.tap(submitButtonFinder);
    await tester.pumpAndSettle();
    expect(find.text('Phone number must be exactly 10 digits'), findsOneWidget);

    // 4. Enter exactly 10 numbers (valid)
    await tester.scrollUntilVisible(
      phoneFieldFinder,
      -300.0,
      scrollable: scrollableFinder,
    );
    await tester.pumpAndSettle();
    await tester.enterText(phoneFieldFinder, '0771234567');
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      submitButtonFinder,
      300.0,
      scrollable: scrollableFinder,
    );
    await tester.pumpAndSettle();
    await tester.tap(submitButtonFinder);
    await tester.pumpAndSettle();
    expect(find.text('Phone number must be exactly 10 digits'), findsNothing);
    expect(find.text('Phone number is required'), findsNothing);
  });
}

