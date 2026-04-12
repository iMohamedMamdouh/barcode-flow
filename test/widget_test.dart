import 'package:flutter_test/flutter_test.dart';
import 'package:wasilaah_finishing/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const WasilaahApp());
    await tester.pump();

    expect(find.text('تغليف وسيلة'), findsOneWidget);
  });
}
