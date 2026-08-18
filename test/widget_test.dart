import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edutech_smk/main.dart';

void main() {
  testWidgets('EduTech SMK app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EduTechApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
