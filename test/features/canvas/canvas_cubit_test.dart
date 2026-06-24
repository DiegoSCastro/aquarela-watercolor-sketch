import 'package:aquarela_watercolor_sketch/config/palette_ids.dart';
import 'package:aquarela_watercolor_sketch/engine/brush.dart';
import 'package:aquarela_watercolor_sketch/features/canvas/canvas_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CanvasCubit — initial state', () {
    test('starts with empty strokes + default ultramar + round brush', () {
      final cubit = CanvasCubit();
      expect(cubit.state.strokes, isEmpty);
      expect(cubit.state.inProgressStroke, isNull);
      expect(cubit.state.currentPigment, PigmentId.ultramar);
      expect(cubit.state.currentBrush.id, 'round_medium');
      expect(cubit.state.currentBrush.type, BrushType.round);
    });
  });

  group('CanvasCubit — stroke lifecycle', () {
    test('startStroke initializes in-progress with a path of 1 point', () {
      final cubit = CanvasCubit();
      cubit.startStroke(const Offset(10, 20));
      expect(cubit.state.inProgressStroke, isNotNull);
      expect(cubit.state.inProgressStroke!.path, [const Offset(10, 20)]);
      // First waypoint has no stamps yet (only added via addPoint).
      expect(cubit.state.inProgressStroke!.stamps, isEmpty);
    });

    test('addPoint extends the in-progress path AND appends stamps', () {
      final cubit = CanvasCubit();
      cubit.startStroke(Offset.zero);
      cubit.addPoint(const Offset(10, 10));
      cubit.addPoint(const Offset(20, 20));
      final ip = cubit.state.inProgressStroke!;
      expect(ip.path.length, 3);
      // Real-time stamps: each addPoint emits at least the center
      // stamp. We don't pin an exact count because the engine's
      // sub-stamp count depends on waterRatio.
      expect(ip.stamps.isNotEmpty, isTrue);
    });

    test('endStroke finalizes and appends to strokes', () {
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

    test('cancelStroke drops the in-progress stroke without finalizing', () {
      final cubit = CanvasCubit();
      cubit.startStroke(Offset.zero);
      cubit.addPoint(const Offset(10, 10));
      cubit.cancelStroke();
      expect(cubit.state.inProgressStroke, isNull);
      expect(cubit.state.strokes, isEmpty);
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
  });

  group('CanvasCubit — brush settings', () {
    test('setWaterRatio clamps to [0..1]', () {
      final cubit = CanvasCubit();
      cubit.setWaterRatio(1.5);
      expect(cubit.state.currentBrush.waterRatio, 1.0);
      cubit.setWaterRatio(-0.5);
      expect(cubit.state.currentBrush.waterRatio, 0.0);
    });

    test('setBrushSize clamps to [1..80]', () {
      final cubit = CanvasCubit();
      cubit.setBrushSize(0.5);
      expect(cubit.state.currentBrush.size, 1.0);
      cubit.setBrushSize(100);
      expect(cubit.state.currentBrush.size, 80.0);
    });

    test('setOpacity clamps to [0.3..1]', () {
      final cubit = CanvasCubit();
      cubit.setOpacity(0.1);
      expect(cubit.state.currentBrush.opacity, 0.3);
      cubit.setOpacity(2.0);
      expect(cubit.state.currentBrush.opacity, 1.0);
    });

    test('setBrush swaps the active brush wholesale', () {
      final cubit = CanvasCubit();
      cubit.setBrush(brushFor(BrushId.mop));
      expect(cubit.state.currentBrush.type, BrushType.mop);
      expect(cubit.state.currentBrush.id, 'mop');
    });
  });

  group('CanvasCubit — pigment', () {
    test('setPigment updates currentPigment', () {
      final cubit = CanvasCubit();
      cubit.setPigment(PigmentId.cadmiumYellow);
      expect(cubit.state.currentPigment, PigmentId.cadmiumYellow);
    });
  });
}
