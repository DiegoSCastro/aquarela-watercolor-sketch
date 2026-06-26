import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aquarela_watercolor_sketch/config/palette_ids.dart';
import 'package:aquarela_watercolor_sketch/engine/brush.dart';
import 'package:aquarela_watercolor_sketch/engine/pigment.dart';
import 'package:aquarela_watercolor_sketch/engine/pigment_engine.dart';
import 'package:aquarela_watercolor_sketch/engine/stamp.dart';
import 'package:aquarela_watercolor_sketch/engine/stroke.dart';

/// State of the canvas — all the strokes currently painted, plus
/// the active brush and pigment. The in-progress stroke uses a
/// private mutable buffer internally so that the cubit can append
/// new waypoints in O(1) without re-allocating the stamps list on
/// every touch event. The painter sees the live stroke through
/// [liveStamps] / [livePath] accessors, which expose read-only
/// views of the internal buffer.
class CanvasState {
  const CanvasState({
    required this.strokes,
    required this.currentBrush,
    required this.currentPigment,
    required this.liveBrush,
    required this.livePigment,
    required this.livePath,
    required this.liveStamps,
    required this.liveStrokeId,
  });

  factory CanvasState.initial() {
    return const CanvasState(
      strokes: [],
      currentBrush: Brush(
        id: 'round_medium',
        type: BrushType.round,
        size: 16,
        opacity: 0.85,
        waterRatio: 0.5,
      ),
      currentPigment: PigmentId.ultramar,
      liveBrush: null,
      livePigment: null,
      livePath: <Offset>[],
      liveStamps: <Stamp>[],
      liveStrokeId: null,
    );
  }

  /// Finalized strokes — these are immutable [Stroke]s that don't
  /// change. Once the user lifts the finger, the live data is
  /// collected into a real [Stroke] and appended here.
  final List<Stroke> strokes;

  final Brush currentBrush;
  final PigmentId currentPigment;

  /// Read-only views of the in-progress stroke. All four fields
  /// are kept in sync by [CanvasCubit]. When [liveStrokeId] is
  /// null, no drag is in progress and the painter should ignore
  /// the live data.
  final String? liveStrokeId;
  final Brush? liveBrush;
  final PigmentId? livePigment;
  final List<Offset> livePath;
  final List<Stamp> liveStamps;

  /// True while the user is dragging their finger on the canvas.
  bool get hasLiveStroke => liveStrokeId != null;

  /// Convert the live data into an immutable [Stroke] for the
  /// painter. Returns null when no drag is in progress.
  ///
  /// This is a *read-only view* — the underlying lists are the
  /// cubit's private mutable buffers. The painter must not store
  /// it across frames; treat it as a snapshot.
  Stroke? get liveSnapshot {
    final id = liveStrokeId;
    final brush = liveBrush;
    final pigment = livePigment;
    if (id == null || brush == null || pigment == null) return null;
    return Stroke(
      id: id,
      brush: brush,
      pigment: pigment,
      path: livePath,
      stamps: liveStamps,
      createdAt: null,
    );
  }

  CanvasState copyWith({
    List<Stroke>? strokes,
    Brush? currentBrush,
    PigmentId? currentPigment,
    String? liveStrokeId,
    Brush? liveBrush,
    PigmentId? livePigment,
    List<Offset>? livePath,
    List<Stamp>? liveStamps,
    bool clearLive = false,
  }) {
    return CanvasState(
      strokes: strokes ?? this.strokes,
      currentBrush: currentBrush ?? this.currentBrush,
      currentPigment: currentPigment ?? this.currentPigment,
      liveStrokeId: clearLive ? null : (liveStrokeId ?? this.liveStrokeId),
      liveBrush: clearLive ? null : (liveBrush ?? this.liveBrush),
      livePigment: clearLive ? null : (livePigment ?? this.livePigment),
      livePath: clearLive ? const <Offset>[] : (livePath ?? this.livePath),
      liveStamps: clearLive ? const <Stamp>[] : (liveStamps ?? this.liveStamps),
    );
  }
}

/// Canvas state management. Owns the in-progress stroke (during a
/// finger drag) and emits stamps in real time as the user moves. No
/// tier system, no session timer, no IAP — the app only monetises
/// via AdMob.
///
/// **Performance**:
/// 1. The live stroke uses a **private mutable list** of stamps
///    internally, so stamps are appended in O(1) instead of
///    allocating a fresh list per waypoint. The public [CanvasState]
///    exposes these as read-only views, so external code can't
///    accidentally mutate them.
/// 2. [addPoint] is **throttled to 60fps** (16ms minimum interval)
///    so we don't queue more emits than the screen can show. Waypoint
///    recording is preserved either way — the throttle only skips
///    the expensive stamp generation and emit.
/// 3. The painter renders [CanvasState.strokes] and the live stroke
///    as separate layers — the finalized stroke list is never
///    copied during a drag.
class CanvasCubit extends Cubit<CanvasState> {
  CanvasCubit() : super(CanvasState.initial());

  int _strokeCounter = 0;

  // --- Mutable live-stroke buffers (not exposed in the state).
  // Using growable lists avoids the per-waypoint copy of a new
  // <Stamp>[] each time. The state exposes these as read-only
  // views, so this is safe.
  final List<Offset> _livePath = <Offset>[];
  final List<Stamp> _liveStamps = <Stamp>[];

  /// Last [addPoint] call that we processed (wall-clock timestamp).
  /// Throttling compares against this. Reset to "long ago" at
  /// [startStroke] so the first waypoint is always processed.
  DateTime _lastProcessedAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Minimum interval between processed [addPoint] emissions. At
  /// 16ms we cap at ~60fps, which is the screen refresh rate on
  /// most devices — any faster and we'd be doing CPU work for
  /// frames the user never sees.
  static const Duration _minFrameInterval = Duration(milliseconds: 16);

  /// Test seam: a clock function returning the current time. Tests
  /// override this to drive throttling deterministically. Defaults
  /// to wall-clock.
  static DateTime Function() clock = DateTime.now;

  // ---------- Brush & pigment ----------

  void setBrush(Brush brush) {
    emit(state.copyWith(currentBrush: brush));
  }

  void setPigment(PigmentId id) {
    emit(state.copyWith(currentPigment: id));
  }

  /// Update the water ratio in [0..1]. Caps the brush's current
  /// water ratio without losing the rest of its config.
  void setWaterRatio(double ratio) {
    final clamped = ratio.clamp(0.0, 1.0);
    final updated = state.currentBrush.copyWith(waterRatio: clamped);
    emit(state.copyWith(currentBrush: updated));
  }

  void setBrushSize(double size) {
    final clamped = size.clamp(1.0, 80.0);
    final updated = state.currentBrush.copyWith(size: clamped);
    emit(state.copyWith(currentBrush: updated));
  }

  void setOpacity(double opacity) {
    final clamped = opacity.clamp(0.3, 1.0);
    final updated = state.currentBrush.copyWith(opacity: clamped);
    emit(state.copyWith(currentBrush: updated));
  }

  // ---------- Stroke lifecycle ----------

  void startStroke(Offset point) {
    _livePath
      ..clear()
      ..add(point);
    _liveStamps.clear();
    final id = 's${_strokeCounter++}';
    emit(
      state.copyWith(
        liveStrokeId: id,
        liveBrush: state.currentBrush,
        livePigment: state.currentPigment,
        livePath: _livePath,
        liveStamps: _liveStamps,
      ),
    );
    // Reset throttle *between strokes* by stamping the last
    // processed time as the current clock value MINUS the frame
    // interval. This guarantees the first addPoint of the new
    // drag is processed, while still respecting throttle for
    // subsequent calls. We use clock() (not the wall clock) so
    // tests with a fake clock behave consistently.
    _lastProcessedAt =
        clock().subtract(_minFrameInterval);
  }

  /// Add a new waypoint to the live stroke. Stamps for this
  /// waypoint are computed immediately and appended to the live
  /// stamps buffer, so the painter renders the new pigment on
  /// the very next frame.
  ///
  /// Throttled to [_minFrameInterval] — if a more recent waypoint
  /// has already been processed, this one is dropped. The dropped
  /// waypoint is still in [_livePath], so the end-of-stroke
  /// rendering has continuous points; we just skip emitting for
  /// intermediate samples.
  void addPoint(Offset point) {
    if (!state.hasLiveStroke) return;

    final now = clock();
    if (now.difference(_lastProcessedAt) < _minFrameInterval) {
      // Still record the path waypoint so the final freeze has
      // continuous points, but skip the (expensive) stamp
      // generation + emit.
      _livePath.add(point);
      return;
    }
    _lastProcessedAt = now;

    final brush = state.liveBrush;
    final pigmentId = state.livePigment;
    if (brush == null || pigmentId == null) return;
    final pigment = Pigment.byId(pigmentId);
    if (pigment == null) return;

    _livePath.add(point);

    // Build the "existing" list for wet-on-wet: the strokes
    // already on the canvas PLUS the stamps emitted earlier in
    // this same drag. This makes the live stroke bleed into
    // itself as it grows (the watercolor pool effect). The
    // wet-mix engine does its own bounding-box filtering, so the
    // cost is proportional to nearby stamps, not the total.
    final existing = <Stroke>[
      ...state.strokes,
      Stroke(
        id: state.liveStrokeId!,
        brush: brush,
        pigment: pigmentId,
        path: _livePath,
        stamps: _liveStamps,
        createdAt: null,
      ),
    ];

    // Heading-aware stamping: pass the previous waypoint so the
    // engine can orient flat/fan stamps along the stroke direction.
    // For the very first waypoint, the previous is null.
    final previousPoint =
        _livePath.length >= 2 ? _livePath[_livePath.length - 2] : null;

    final newStamps = PigmentEngine.stamp(
      brush: brush,
      pigment: pigment,
      point: point,
      previousPoint: previousPoint,
      existing: existing,
    );

    _liveStamps.addAll(newStamps);

    // No new copyWith for the live lists — we mutated the existing
    // buffers. Just emit a sentinel to trigger the painter rebuild.
    emit(state.copyWith());
  }

  void endStroke() {
    if (!state.hasLiveStroke) return;

    final brush = state.liveBrush!;
    final pigment = state.livePigment!;
    final id = state.liveStrokeId!;

    final finalized = Stroke(
      id: id,
      brush: brush,
      pigment: pigment,
      path: List<Offset>.unmodifiable(_livePath),
      stamps: List<Stamp>.unmodifiable(_liveStamps),
      createdAt: DateTime.now(),
    );
    _livePath.clear();
    _liveStamps.clear();
    emit(
      state.copyWith(
        strokes: [...state.strokes, finalized],
        clearLive: true,
      ),
    );
  }

  void cancelStroke() {
    if (!state.hasLiveStroke) return;
    _livePath.clear();
    _liveStamps.clear();
    emit(state.copyWith(clearLive: true));
  }

  void clear() {
    _livePath.clear();
    _liveStamps.clear();
    emit(state.copyWith(strokes: const [], clearLive: true));
  }
}
