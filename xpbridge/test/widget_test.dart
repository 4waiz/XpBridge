import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xpbridge/app.dart';
import 'package:xpbridge/screens/onboarding/intro_screen.dart';

void main() {
  testWidgets('XPBridge boots from splash into onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const XPBridgeApp());
    expect(find.text('XPBridge'), findsWidgets);
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('The Experience Gap'), findsOneWidget);
  });

  testWidgets('IntroScreen stays stable on narrow widths', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(280, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MaterialApp(home: IntroScreen()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(find.text('Log In'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
