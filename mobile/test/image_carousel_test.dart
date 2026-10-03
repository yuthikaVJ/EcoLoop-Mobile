import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eco_loop/shared/widgets/image_carousel.dart';

void main() {
  Future<void> pump(WidgetTester tester, int count) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 300,
            child: ImageCarousel(
              itemCount: count,
              itemBuilder: (context, index) => Center(child: Text('Photo ${index + 1}')),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('one photo shows no dots or counter', (tester) async {
    await pump(tester, 1);
    expect(find.text('Photo 1'), findsOneWidget);
    expect(find.text('1/1'), findsNothing);
    expect(find.bySemanticsLabel('Photo 1 of 1'), findsNothing);
  });

  testWidgets('swiping moves the counter and the active dot', (tester) async {
    await pump(tester, 3);
    expect(find.text('1/3'), findsOneWidget);
    expect(find.bySemanticsLabel('Photo 1 of 3'), findsOneWidget);
    expect(find.byType(AnimatedContainer), findsNWidgets(3));

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Photo 2'), findsOneWidget);
    expect(find.text('2/3'), findsOneWidget);
    expect(find.bySemanticsLabel('Photo 2 of 3'), findsOneWidget);
  });
}
