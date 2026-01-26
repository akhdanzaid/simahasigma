// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
//
// import 'package:sim/main.dart'; // Ganti dengan nama package Anda
//
// void main() {
//   testWidgets('Counter increments smoke test', (WidgetTester tester) async {
//     // Build our app and trigger a frame.
//     await tester.pumpWidget(const StudentManagementApp());
//
//     // Verify that our counter starts at 0.
//     expect(find.text('EduTask'), findsOneWidget);
//     expect(find.text('Organize Your Academic Journey'), findsOneWidget);
//
//     // Tap the '+' icon and trigger a frame.
//     await tester.tap(find.byType(ElevatedButton).first);
//     await tester.pump();
//
//     // Verify that our counter has incremented.
//     expect(find.text('Get Started'), findsOneWidget);
//   });
// }