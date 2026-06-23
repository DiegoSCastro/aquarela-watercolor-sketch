import 'package:flutter/foundation.dart';

/// Brush type — describes the physical tip shape.
enum BrushType { round, flat, fan, mop }

/// A brush is the painting tool. It carries its own size, opacity,
/// and water ratio. Water ratio drives the radial bleed radius:
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
}

/// Identifiers for the 6 planned brushes. v1 ships only roundSmall.
enum BrushId {
  roundSmall,
  roundMedium,
  roundLarge,
  flat,
  fan,
  mop,
}
