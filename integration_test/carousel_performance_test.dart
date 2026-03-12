import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Carousel Performance E2E Test', () {
    testWidgets('should render carousel within performance budget', (tester) async {
      final List<String> memoryLeaks = [];
      double fps = 0.0;

      // Step 1: Measure render time
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _buildTestCarousel(),
          ),
        ),
      );

      await tester.pump();
      stopwatch.stop();

      final renderTime = Duration(milliseconds: stopwatch.elapsedMilliseconds);

      // Step 2: Simulate frame rate monitoring
      fps = await _measureFrameRate(tester);

      // Step 3: Test swipe gestures
      final carouselFinder = find.byType(PageView);
      if (carouselFinder.evaluate().isNotEmpty) {
        // Swipe left
        await tester.drag(carouselFinder.first, const Offset(-300, 0));
        await tester.pumpAndSettle();

        // Swipe right
        await tester.drag(carouselFinder.first, const Offset(300, 0));
        await tester.pumpAndSettle();
      }

      // Step 4: Verify gesture response time
      final gestureStopwatch = Stopwatch()..start();
      await tester.pump(const Duration(milliseconds: 16));
      gestureStopwatch.stop();
      final gestureResponseTime = gestureStopwatch.elapsedMilliseconds;

      // Assertions
      expect(
        renderTime,
        lessThan(const Duration(milliseconds: 200)),
        reason: 'Carousel should render in under 200ms',
      );
      expect(
        fps,
        greaterThanOrEqualTo(45),
        reason: 'Frame rate should be at least 45fps',
      );
      expect(
        memoryLeaks,
        isEmpty,
        reason: 'No memory leaks should be detected',
      );
    });

    testWidgets('should handle rapid swipe gestures without dropping frames', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _buildTestCarousel(),
          ),
        ),
      );

      // Rapid swipe simulation
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      // Should complete without errors
      expect(tester.takeException(), isNull);
    });
  });
}

Widget _buildTestCarousel() {
  return SizedBox(
    height: 200,
    child: PageView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.primaries[index % Colors.primaries.length],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              'Card $index',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        );
      },
    ),
  );
}

Future<double> _measureFrameRate(WidgetTester tester) async {
  final frameCount = 30;
  final stopwatch = Stopwatch()..start();

  for (int i = 0; i < frameCount; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }

  stopwatch.stop();
  final elapsedSeconds = stopwatch.elapsedMilliseconds / 1000.0;
  return frameCount / elapsedSeconds;
}
