import 'package:flutter/foundation.dart';

/// Brush type — describes the physical tip shape. Each type
/// produces a distinct stamp pattern in the engine.
enum BrushType { round, flat, fan, mop }

/// A brush is the painting tool. It carries its own size, opacity,
/// water ratio, and tip type. Water ratio drives the radial bleed:
/// - waterRatio = 0.0: tight, opaque (dry brush)
/// - waterRatio = 1.0: wide, transparent (wet brush, lots of bleed)
@immutable
class Brush {
  const Brush({
    required this.id,
    required this.type,
    required this.size,
    required this.opacity,
    required this.waterRatio,
  });

  final String id;
  final BrushType type;

  /// Tip diameter in logical pixels.
  final double size;

  /// 0..1 — overall alpha of the brush.
  final double opacity;

  /// 0..1 — amount of water in the brush. Drives radial bleed radius.
  final double waterRatio;

  Brush copyWith({
    String? id,
    BrushType? type,
    double? size,
    double? opacity,
    double? waterRatio,
  }) {
    return Brush(
      id: id ?? this.id,
      type: type ?? this.type,
      size: size ?? this.size,
      opacity: opacity ?? this.opacity,
      waterRatio: waterRatio ?? this.waterRatio,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Brush &&
        other.id == id &&
        other.type == type &&
        other.size == size &&
        other.opacity == opacity &&
        other.waterRatio == waterRatio;
  }

  @override
  int get hashCode => Object.hash(id, type, size, opacity, waterRatio);
}

/// All brushes shipped in the app. The brush id is the stable
/// identifier for analytics + saved settings.
enum BrushId {
  roundSmall,
  roundMedium,
  roundLarge,
  flat,
  fan,
  mop,
}

/// Catalogue: id → fully-formed [Brush]. The size and water
/// defaults are tuned for a finger on a phone screen.
Brush brushFor(BrushId id) {
  switch (id) {
    case BrushId.roundSmall:
      return const Brush(
        id: 'round_small',
        type: BrushType.round,
        size: 6,
        opacity: 0.9,
        waterRatio: 0.4,
      );
    case BrushId.roundMedium:
      return const Brush(
        id: 'round_medium',
        type: BrushType.round,
        size: 16,
        opacity: 0.85,
        waterRatio: 0.5,
      );
    case BrushId.roundLarge:
      return const Brush(
        id: 'round_large',
        type: BrushType.round,
        size: 32,
        opacity: 0.8,
        waterRatio: 0.6,
      );
    case BrushId.flat:
      return const Brush(
        id: 'flat',
        type: BrushType.flat,
        size: 18,
        opacity: 0.85,
        waterRatio: 0.5,
      );
    case BrushId.fan:
      return const Brush(
        id: 'fan',
        type: BrushType.fan,
        size: 20,
        opacity: 0.7,
        waterRatio: 0.55,
      );
    case BrushId.mop:
      return const Brush(
        id: 'mop',
        type: BrushType.mop,
        size: 28,
        opacity: 0.75,
        waterRatio: 0.7,
      );
  }
}
