import 'package:flutter_test/flutter_test.dart';
import 'package:paluwagan_pro/main.dart';

void main() {
  testWidgets('App should load', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PaluwaganProApp());
    
    // Basic verification that the app starts
    expect(find.byType(PaluwaganProApp), findsOneWidget);
  });
}
