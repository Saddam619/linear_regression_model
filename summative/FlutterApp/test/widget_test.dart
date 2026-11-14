import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutterapp/main.dart';

void main() {
  testWidgets('shows the Africa unemployment prediction form', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Africa Unemployment Predictor'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(14));
    expect(find.text('Predict'), findsOneWidget);
  });
}
