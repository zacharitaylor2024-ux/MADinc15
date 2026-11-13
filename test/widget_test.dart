
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inc15/main.dart';

void main() {
  testWidgets('Science Signal app starts correctly', (tester) async {
    await tester.pumpWidget(const ScienceSignalApp());

    expect(find.text('Science Signal'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
