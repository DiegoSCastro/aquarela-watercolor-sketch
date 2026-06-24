import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aquarela_watercolor_sketch/config/palette_ids.dart';
import 'package:aquarela_watercolor_sketch/engine/brush.dart';
import 'package:aquarela_watercolor_sketch/engine/pigment.dart';
import 'package:aquarela_watercolor_sketch/engine/pigment_engine.dart';
import 'package:aquarela_watercolor_sketch/engine/stroke.dart';

/// State of the canvas — all the strokes currently painted, plus
/// the active brush and pigment. Stamps are emitted incrementally
/// as the user drags, so the in-progress stroke is visible live.
class CanvasState {
  const CanvasState({
    required this.strokes,
    required this.currentBrush,
    required this.currentPigment,
    this.inProgressStroke,
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
    );
  }

  final List<Stroke> strokes;
  final Brush currentBrush;
  final PigmentId currentPigment;
  final Stroke? inProgressStroke;

  /// Strokes the painter should render: finalized ones plus the
  /// in-progress one (with its live stamps) if there is one.
  List<Stroke> get renderableStrokes {
    if (inProgressStroke == null) return strokes;
    return [...strokes, inProgressStroke!];
  }

  CanvasState copyWith({
    List<Stroke>? strokes,
    Brush? currentBrush,
    PigmentId? currentPigment,
    Stroke? inProgressStroke,
    bool clearInProgress = false,
  }) {
    return CanvasState(
      strokes: strokes ?? this.strokes,
      currentBrush: currentBrush ?? this.currentBrush,
      currentPigment: currentPigment ?? this.currentPigment,
      inProgressStroke: clearInProgress
          ? null
          : (inProgressStroke ?? this.inProgressStroke),
    );
  }
}

/// Canvas state management. Owns the in-progress stroke (during a
/// finger drag) and emits stamps in real time as the user moves.
/// No tier system, no session timer, no IAP — the app is ad-free
/// at the user level and only monetises via AdMob.
class CanvasCubit extends Cubit<CanvasState> {
  CanvasCubit() : super(CanvasState.initial());

  int _strokeCounter = 0;

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
    final id = 's${_strokeCounter++}';
    emit(
      state.copyWith(
        inProgressStroke: Stroke(
          id: id,
          brush: state.currentBrush,
          pigment: state.currentPigment,
          path: [point],
          stamps: const [],
          createdAt: null,
        ),
      ),
    );
  }

  /// Add a new waypoint to the in-progress stroke. Stamps for
  /// this waypoint are computed immediately and appended, so the
  /// painter renders the new pigment on the very next frame.
  void addPoint(Offset point) {
    final current = state.inProgressStroke;
    if (current == null) return;

    final pigment = Pigment.byId(current.pigment);
    if (pigment == null) return;

    // Build the "existing" list for wet-on-wet: the strokes
    // already on the canvas PLUS the stamps emitted earlier in
    // this same drag. This makes the in-progress stroke bleed
    // into itself as it grows (the watercolor pool effect).
    final existing = <Stroke>[
      ...state.strokes,
      current,
    ];

    final newStamps = PigmentEngine.stamp(
      brush: current.brush,
      pigment: pigment,
      point: point,
      existing: existing,
    );

    final updatedPath = [...current.path, point];
    final updatedStamps = [...current.stamps, ...newStamps];
    final updatedStroke = current.copyWith(
      path: updatedPath,
      stamps: updatedStamps,
    );

    emit(state.copyWith(inProgressStroke: updatedStroke));
  }

  void endStroke() {
    final current = state.inProgressStroke;
    if (current == null) return;

    final finalized = current.copyWith(createdAt: DateTime.now());
    emit(
      state.copyWith(
        strokes: [...state.strokes, finalized],
        clearInProgress: true,
      ),
    );
  }

  void cancelStroke() {
    if (state.inProgressStroke == null) return;
    emit(state.copyWith(clearInProgress: true));
  }

  void clear() {
    emit(state.copyWith(strokes: const [], clearInProgress: true));
  }
}
