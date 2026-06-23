import 'package:flutter/material.dart';

/// A stamp is a pre-computed dot that the pigment engine emits
/// along a stroke path. The renderer paints one circle per stamp.
///
/// Stamps are immutable: a stroke's visual is fully captured by its
/// list of stamps. Repaint == repaint the same circles.
@immutable
class Stamp {
  const Stamp({
    required this.offset,
    required this.radius,
    required this.color,
    required this.alpha,
  });

  /// Center of the stamp, in canvas coordinates.
  final Offset offset;

  /// Radius in logical pixels. Already includes the water-ratio
  /// bleed, so the renderer can paint it as-is.
  final double radius;

  /// The stamp's color (after pigment blending for wet-on-wet).
  final Color color;

  /// Alpha multiplier applied on top of the brush opacity.
  /// 0 = invisible, 1 = full strength.
  final double alpha;
}
