import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theoriginallab_v2/features/home/presentation/providers/home_data_provider.dart';
import 'package:theoriginallab_v2/features/home/presentation/screens/services_screen.dart';

void main() {
  testWidgets('Performance: Services Screen Scroll Benchmark',
      (WidgetTester tester) async {
    // Anula el provider de servicios con datos locales estáticos para
    // evitar el timeout de pumpAndSettle esperando llamadas de red.
    final staticServices = List.generate(
      6,
      (i) => {
        'titulo': 'Servicio ${i + 1}',
        'descripcion': 'Descripción del servicio ${i + 1}',
        'url': 'https://theoriginallab.com',
        'image_url': '',
        'badge': '',
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Sobrescribe el provider para que devuelva datos inmediatamente
          // sin llamadas de red, previniendo el pumpAndSettle timeout.
          homeServicesProvider.overrideWith((ref) async => staticServices),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (ctx, child) => const MaterialApp(
            home: Scaffold(
              // ServicesScreen usa Navigator.pop() — necesita un contexto completo
              body: ServicesScreen(),
            ),
          ),
        ),
      ),
    );

    // Deja que el FutureProvider resuelva (sin llamadas de red)
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 2. Verificar que el ScrollView existe
    final scrollFinder = find.byKey(const Key('services_scroll_view'));
    expect(scrollFinder, findsOneWidget,
        reason: 'El CustomScrollView debe estar visible');

    // 3. Acción — scroll hacia abajo y arriba
    final stopwatch = Stopwatch()..start();

    await tester.fling(scrollFinder, const Offset(0, -300), 800);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.fling(scrollFinder, const Offset(0, 300), 800);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    stopwatch.stop();

    // 4. Verificaciones
    debugPrint('Scroll Action Duration: ${stopwatch.elapsedMilliseconds}ms');

    expect(
      stopwatch.elapsedMilliseconds,
      lessThan(5000),
      reason:
          'El scroll fue demasiado lento — posible bloqueo del main thread.',
    );
  });
}
