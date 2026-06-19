import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gowise_helper/app.dart';

void main() {
  testWidgets('App builds without throwing', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GoWiseApp()));
    expect(find.byType(GoWiseApp), findsOneWidget);
  });
}
