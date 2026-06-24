import 'package:aquarela_watercolor_sketch/config/palette_ids.dart';
import 'package:aquarela_watercolor_sketch/engine/brush.dart';
import 'package:aquarela_watercolor_sketch/features/canvas/canvas_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Drive the throttle clock manually so throttling tests are
  // deterministic and don't have to wait 16ms per assertion.
  group('CanvasCubit', () {
    late DateTime fakeNow;
    late void Function([Duration]) advance;
    setUp(() {
      fakeNow = DateTime.fromMillisecondsSinceEpoch(0);
      CanvasCubit.clock = () => fakeNow;
      advance = ([delta = const Duration(milliseconds: 17)]) {
        fakeNow = fakeNow.add(delta);
      };
    });
    tearDown(() {
      CanvasCubit.clock = DateTime.now;
    });

    group('initial state', () {
      test('starts with empty strokes + default ultramar + round brush', () {
        final cubit = CanvasCubit();
        expect(cubit.state.strokes, isEmpty);
        expect(cubit.state.hasLiveStroke, isFalse);
        expect(cubit.state.currentPigment, PigmentId.ultramar);
        expect(cubit.state.currentBrush.id, 'round_medium');
        expect(cubit.state.currentBrush.type, BrushType.round);
      });
    });

    group('stroke lifecycle', () {
      test('startStroke opens the live stroke with a path of 1 point', () {
        final cubit = CanvasCubit();
        cubit.startStroke(const Offset(10, 20));
        expect(cubit.state.hasLiveStroke, isTrue);
        expect(cubit.state.livePath, [const Offset(10, 20)]);
        expect(cubit.state.liveStamps, isEmpty);
      });

      test('addPoint extends the live path AND appends stamps', () {
        final cubit = CanvasCubit();
        cubit.startStroke(Offset.zero);
        cubit.addPoint(const Offset(10, 10));
        cubit.addPoint(const Offset(20, 20));
        final path = cubit.state.livePath;
        final stamps = cubit.state.liveStamps;
        expect(path.length, 3);
        expect(stamps.isNotEmpty, isTrue);
      });

      test('endStroke finalizes and appends to strokes', () {
        final cubit = CanvasCubit();
        cubit.startStroke(Offset.zero);
        for (var i = 1; i < 20; i++) {
          advance();
          cubit.addPoint(Offset(i * 5.0, i * 5.0));
        }
        cubit.endStroke();
        expect(cubit.state.hasLiveStroke, isFalse);
        expect(cubit.state.strokes.length, 1);
        expect(cubit.state.strokes.first.stamps.isNotEmpty, isTrue);
        expect(cubit.state.strokes.first.isFinalized, isTrue);
      });

      test('cancelStroke drops the live stroke without finalizing', () {
        final cubit = CanvasCubit();
        cubit.startStroke(Offset.zero);
        cubit.addPoint(const Offset(10, 10));
        cubit.cancelStroke();
        expect(cubit.state.hasLiveStroke, isFalse);
        expect(cubit.state.strokes, isEmpty);
      });

      test('clear empties all strokes and live', () {
        final cubit = CanvasCubit();
        cubit.startStroke(Offset.zero);
        cubit.addPoint(const Offset(10, 10));
        cubit.endStroke();
        cubit.clear();
        expect(cubit.state.strokes, isEmpty);
        expect(cubit.state.hasLiveStroke, isFalse);
      });
    });

    group('throttling (60fps cap)', () {
      test('two addPoint within 16ms still records both path waypoints', () {
        // Throttling must NEVER drop path waypoints — only stamps.
        final cubit = CanvasCubit();
        cubit.startStroke(Offset.zero);
        cubit.addPoint(const Offset(10, 10)); // 0ms — processed
        cubit.addPoint(const Offset(20, 20)); // 0ms — throttled
        expect(cubit.state.livePath.length, 3); // start + 2 addPoint
      });

      test('two addPoint within 16ms emits stamps for only the first', () {
        final cubit = CanvasCubit();
        cubit.startStroke(Offset.zero);
        cubit.addPoint(const Offset(10, 10)); // 0ms — processed
        final stampsAfterFirst = cubit.state.liveStamps.length;
        cubit.addPoint(const Offset(20, 20)); // 0ms — throttled
        expect(cubit.state.liveStamps.length, stampsAfterFirst);
      });

      test('addPoint after 16ms emits a fresh batch of stamps', () {
        final cubit = CanvasCubit();
        cubit.startStroke(Offset.zero);
        cubit.addPoint(const Offset(10, 10));
        advance();
        cubit.addPoint(const Offset(20, 20));
        expect(cubit.state.liveStamps.length, greaterThan(0));
        expect(cubit.state.livePath.length, 3);
      });
    });

    group('brush settings', () {
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

    group('pigment', () {
      test('setPigment updates currentPigment', () {
        final cubit = CanvasCubit();
        cubit.setPigment(PigmentId.cadmiumYellow);
        expect(cubit.state.currentPigment, PigmentId.cadmiumYellow);
      });
    });
  });
}
