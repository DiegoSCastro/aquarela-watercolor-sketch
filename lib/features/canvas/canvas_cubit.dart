import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aquarela_watercolor_sketch/config/premium_config.dart';
import 'package:aquarela_watercolor_sketch/engine/brush.dart';
import 'package:aquarela_watercolor_sketch/engine/pigment.dart';
import 'package:aquarela_watercolor_sketch/engine/pigment_engine.dart';
import 'package:aquarela_watercolor_sketch/engine/stroke.dart';

/// State of the canvas — all the strokes currently painted, plus
/// the active brush and pigment. The free-tier session timer is
/// tracked here too so the UI can react to it.
class CanvasState {
  const CanvasState({
    required this.strokes,
    required this.currentBrush,
    required this.currentPigment,
    this.inProgressStroke,
    this.sessionSecondsRemaining,
  });

  factory CanvasState.initial() {
    return CanvasState(
      strokes: const [],
      currentBrush: const Brush(
        id: 'round_small',
        type: BrushType.round,
        size: 12,
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
  final int? sessionSecondsRemaining;

  /// Strokes the painter should render: finalized ones plus the
  /// in-progress one if there is one.
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
    int? sessionSecondsRemaining,
    bool clearTimer = false,
  }) {
    return CanvasState(
      strokes: strokes ?? this.strokes,
      currentBrush: currentBrush ?? this.currentBrush,
      currentPigment: currentPigment ?? this.currentPigment,
      inProgressStroke: clearInProgress
          ? null
          : (inProgressStroke ?? this.inProgressStroke),
      sessionSecondsRemaining: clearTimer
          ? null
          : (sessionSecondsRemaining ?? this.sessionSecondsRemaining),
    );
  }
}

/// Canvas state management. Owns the in-progress stroke (during a
/// finger drag), finalizes strokes on lift, and enforces the free
/// tier session timer.
class CanvasCubit extends Cubit<CanvasState> {
  CanvasCubit() : super(CanvasState.initial());

  int _strokeCounter = 0;
  int _elapsedSeconds = 0;
  bool _timerActive = false;
  Duration _previousTick = Duration.zero;

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
    final updated = Brush(
      id: state.currentBrush.id,
      type: state.currentBrush.type,
      size: state.currentBrush.size,
      opacity: state.currentBrush.opacity,
      waterRatio: clamped,
    );
    emit(state.copyWith(currentBrush: updated));
  }

  void setBrushSize(double size) {
    final clamped = size.clamp(1.0, 50.0);
    final updated = Brush(
      id: state.currentBrush.id,
      type: state.currentBrush.type,
      size: clamped,
      opacity: state.currentBrush.opacity,
      waterRatio: state.currentBrush.waterRatio,
    );
    emit(state.copyWith(currentBrush: updated));
  }

  void setOpacity(double opacity) {
    final clamped = opacity.clamp(0.5, 1.0);
    final updated = Brush(
      id: state.currentBrush.id,
      type: state.currentBrush.type,
      size: state.currentBrush.size,
      opacity: clamped,
      waterRatio: state.currentBrush.waterRatio,
    );
    emit(state.copyWith(currentBrush: updated));
  }

  // ---------- Stroke lifecycle ----------

  void startStroke(Offset point) {
    if (!_timerActive && PremiumConfig.current.maxSessionSeconds > 0) {
      _startSessionTimer();
    }
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

  void addPoint(Offset point) {
    final current = state.inProgressStroke;
    if (current == null) return;
    final updatedPath = [...current.path, point];
    final updatedStroke = current.copyWith(path: updatedPath);
    emit(state.copyWith(inProgressStroke: updatedStroke));
  }

  void endStroke() {
    final current = state.inProgressStroke;
    if (current == null) return;

    // Look up the pigment by id — Pigment.byId is the single
    // source of truth (the previous manual switch drifted when
    // new pigments were added and would silently miss them).
    final pigment = Pigment.byId(current.pigment);
    if (pigment == null) return; // unknown pigment, skip

    final stamps = PigmentEngine.stroke(
      brush: current.brush,
      pigment: pigment,
      path: current.path,
      existing: state.strokes,
    );

    final finalized = current.copyWith(
      stamps: stamps,
      createdAt: DateTime.now(),
    );

    // Drop the oldest strokes past the tier cap so the painter
    // stays cheap regardless of how long the user paints.
    final updatedStrokes = [...state.strokes, finalized];
    final trimmed = updatedStrokes.length > _maxStrokes
        ? updatedStrokes.sublist(updatedStrokes.length - _maxStrokes)
        : updatedStrokes;

    emit(
      state.copyWith(
        strokes: trimmed,
        clearInProgress: true,
      ),
    );
  }

  void clear() {
    emit(state.copyWith(strokes: const [], clearInProgress: true));
  }

  // Maximum number of strokes kept in memory. Older strokes are
  // dropped past the cap to keep the painter cheap on weaker
  // devices. Tuned by tier.
  int get _maxStrokes => isPremium ? 2000 : 200;

  bool get isPremium => PremiumConfig.current.isPremium;

  // Minimum elapsed tick (ms) before we count it as a real second
  // boundary. At 60Hz a ticker fires ~16ms; without this gate we'd
  // emit 60 state updates per second, flooding the UI.
  static const _tickIntervalMs = 900;

  // ---------- Session timer ----------

  void _startSessionTimer() {
    final max = PremiumConfig.current.maxSessionSeconds;
    if (max <= 0) return; // unlimited
    _timerActive = true;
    _elapsedSeconds = 0;
    _previousTick = Duration.zero;
    emit(state.copyWith(sessionSecondsRemaining: max));
  }

  /// Called by the Ticker in the UI layer. Increments the
  /// elapsed time and emits a new state every second.
  void onTick(Duration elapsed) {
    if (!_timerActive) return;
    final max = PremiumConfig.current.maxSessionSeconds;
    if (max <= 0) return;

    final delta = elapsed - _previousTick;
    _previousTick = elapsed;
    if (delta.inMilliseconds < _tickIntervalMs) return;

    _elapsedSeconds += 1;
    final remaining = max - _elapsedSeconds;
    if (remaining <= 0) {
      _timerActive = false;
      emit(
        state.copyWith(
          sessionSecondsRemaining: 0,
          strokes: const [],
          clearInProgress: true,
        ),
      );
    } else {
      emit(state.copyWith(sessionSecondsRemaining: remaining));
    }
  }
}
