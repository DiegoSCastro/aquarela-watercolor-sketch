import 'package:aquarela_watercolor_sketch/config/premium_config.dart';
import 'package:aquarela_watercolor_sketch/engine/brush.dart';
import 'package:aquarela_watercolor_sketch/features/canvas/canvas_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CanvasCubit', () {
    test(
      'initial state has empty strokes + default ultramar + round brush',
      () {
        final cubit = CanvasCubit();
        expect(cubit.state.strokes, isEmpty);
        expect(cubit.state.currentPigment, PigmentId.ultramar);
        expect(cubit.state.currentBrush.id, 'round_small');
        expect(cubit.state.currentBrush.type, BrushType.round);
      },
    );

    test('startStroke initializes in-progress with a path of 1 point', () {
      final cubit = CanvasCubit();
      cubit.startStroke(const Offset(10, 20));
      expect(cubit.state.inProgressStroke, isNotNull);
      expect(cubit.state.inProgressStroke!.path, [const Offset(10, 20)]);
    });

    test('addPoint extends the in-progress path', () {
      final cubit = CanvasCubit();
      cubit.startStroke(Offset.zero);
      cubit.addPoint(const Offset(10, 10));
      cubit.addPoint(const Offset(20, 20));
      expect(cubit.state.inProgressStroke!.path.length, 3);
    });

    test('endStroke finalizes and computes stamps', () {
      final cubit = CanvasCubit();
      cubit.startStroke(Offset.zero);
      for (var i = 1; i < 20; i++) {
        cubit.addPoint(Offset(i * 5.0, i * 5.0));
      }
      cubit.endStroke();
      expect(cubit.state.inProgressStroke, isNull);
      expect(cubit.state.strokes.length, 1);
      expect(cubit.state.strokes.first.stamps.isNotEmpty, isTrue);
      expect(cubit.state.strokes.first.isFinalized, isTrue);
    });

    test('clear empties all strokes and in-progress', () {
      final cubit = CanvasCubit();
      cubit.startStroke(Offset.zero);
      cubit.addPoint(const Offset(10, 10));
      cubit.endStroke();
      cubit.clear();
      expect(cubit.state.strokes, isEmpty);
      expect(cubit.state.inProgressStroke, isNull);
    });

    test('setWaterRatio clamps to [0..1]', () {
      final cubit = CanvasCubit();
      cubit.setWaterRatio(1.5);
      expect(cubit.state.currentBrush.waterRatio, 1.0);
      cubit.setWaterRatio(-0.5);
      expect(cubit.state.currentBrush.waterRatio, 0.0);
    });

    test('setBrushSize clamps to [1..50]', () {
      final cubit = CanvasCubit();
      cubit.setBrushSize(0.5);
      expect(cubit.state.currentBrush.size, 1.0);
      cubit.setBrushSize(100);
      expect(cubit.state.currentBrush.size, 50.0);
    });
  });

  group('CanvasCubit session timer (free tier)', () {
    setUp(() => PremiumConfig.overrideForTest(isPremium: false));
    tearDown(PremiumConfig.resetForTest);

    test('startStroke activates the timer', () {
      final cubit = CanvasCubit();
      expect(cubit.state.sessionSecondsRemaining, isNull);
      cubit.startStroke(Offset.zero);
      expect(cubit.state.sessionSecondsRemaining, 30);
    });

    test('onTick counts down every second', () {
      final cubit = CanvasCubit();
      cubit.startStroke(Offset.zero);
      cubit.onTick(const Duration(seconds: 1));
      expect(cubit.state.sessionSecondsRemaining, 29);
      cubit.onTick(const Duration(seconds: 2));
      expect(cubit.state.sessionSecondsRemaining, 28);
    });

    test('onTick at 30s clears strokes and stops timer', () {
      final cubit = CanvasCubit();
      cubit.startStroke(Offset.zero);
      cubit.addPoint(const Offset(5, 5));
      cubit.endStroke();
      // jump to end of session
      for (var i = 0; i < 30; i++) {
        cubit.onTick(Duration(seconds: i + 1));
      }
      // final tick at 30s should have fired the auto-clear
      expect(cubit.state.strokes, isEmpty);
    });
  });

  group('CanvasCubit session timer (pro tier)', () {
    setUp(() => PremiumConfig.overrideForTest(isPremium: true));
    tearDown(PremiumConfig.resetForTest);

    test('startStroke does NOT activate the timer', () {
      final cubit = CanvasCubit();
      cubit.startStroke(Offset.zero);
      expect(cubit.state.sessionSecondsRemaining, isNull);
    });
  });
}
