import 'package:flutter_test/flutter_test.dart';

import 'package:untitled1/app/waiter_app.dart';

void main() {
  testWidgets('waiter home renders three actions', (WidgetTester tester) async {
    await tester.pumpWidget(const WaiterApp());

    expect(find.text('Επιλέξτε Ενέργεια'), findsOneWidget);
    expect(find.text('Νέα Παραγγελία'), findsOneWidget);
    expect(find.text('Προσθήκη Έξτρα'), findsOneWidget);
    expect(find.text('Δείτε Παραγγελία'), findsOneWidget);
  });
}
