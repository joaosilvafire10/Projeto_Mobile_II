import 'package:flutter_test/flutter_test.dart';
import 'package:chamados_inteligentes/main.dart';

void main() {
  testWidgets('App should render', (WidgetTester tester) async {
    await tester.pumpWidget(const ChamadosInteligentesApp());
    expect(find.text('Chamados\nInteligentes'), findsOneWidget);
  });
}
