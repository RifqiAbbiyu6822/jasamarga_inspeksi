import 'package:flutter_test/flutter_test.dart';

import 'package:jasamarga_inspeksi/main.dart';

void main() {
  testWidgets('App shows HomeScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const JasaMargaApp(onboardingDone: true));

    expect(find.text('Buat Form Inspeksi Baru'), findsOneWidget);
    expect(find.text('Riwayat Inspeksi'), findsOneWidget);
  });
}
