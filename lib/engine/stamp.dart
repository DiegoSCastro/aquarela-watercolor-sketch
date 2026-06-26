import 'package:flutter/foundation.dart';
import 'dart:ui';

/// How a stamp should be drawn on the canvas. Different brush types
/// produce different shapes here — this is the single source of
/// truth for "what does this stamp look like".
///
/// Round brushes and mop brushes are drawn as circles, but mop
/// stamps carry an `edgeJitter` hint so the painter can render an
/// irregular border (mop brushes don't leave a perfect disc — the
/// bristles splay). Flat brushes are drawn as oriented ovals; the
/// painter uses `angle` to align the oval with the stroke heading.
/// Fan brushes emit multiple thin tines, each one a thin rect
/// emanating from the center along `angle`.
enum StampShape { round, oval, fan, mop }

/// A pre-computed pigment deposit on the canvas. The engine emits
/// one or more [Stamp]s per touch waypoint; the painter renders
/// each stamp as a soft, water-coloured shape.
///
/// [shape] drives the painter's draw call:
///   - [StampShape.round]  -> [Canvas.drawCircle]
///   - [StampShape.oval]   -> canvas save / rotate / drawOval
///   - [StampShape.fan]    -> multiple [Canvas.drawRect]s as tines
///   - [StampShape.mop]    -> [Canvas.drawCircle] with edge jitter
///
/// [radius] is the primary extent (width). For oval stamps,
/// [aspectRatio] (>=1.0) stretches the stamp along its [angle] —
/// for instance, a flat brush at angle 0 has aspectRatio 3 and
/// angle 0, producing a horizontal streak. The painter computes
/// the actual bounding box as `radius` by `radius * aspectRatio`.
///
/// [angle] is in radians, measured clockwise from the positive
/// X axis. The painter uses this for oval rotation and for the
/// direction the fan tines spread along.
@immutable
class Stamp {
  const Stamp({
    required this.offset,
    required this.radius,
    required this.color,
    required this.alpha,
    this.shape = StampShape.round,
    this.angle = 0.0,
    this.aspectRatio = 1.0,
    this.edgeJitter = 0.0,
    this.tineCount = 0,
    this.tineLength = 0.0,
    this.tineWidth = 0.0,
  });

  /// Where the stamp is centered on the canvas.
  final Offset offset;

  /// Primary radius (in logical pixels). For round and mop this is
  /// the disc radius. For oval it's the semi-minor axis (width/2).
  final double radius;

  /// Pigment color before alpha modulation.
  final Color color;

  /// 0..1 — final alpha multiplier. The painter combines this with
  /// [Paint.color] using [Color.withValues].
  final double alpha;

  /// Geometric shape the painter should use.
  final StampShape shape;

  /// Orientation in radians, clockwise from positive X.
  final double angle;

  /// For oval: stretch ratio along [angle] (>=1.0). 1.0 = circle.
  final double aspectRatio;

  /// For mop: amount of edge irregularity in pixels (0 = clean disc).
  /// The painter uses this to perturb the disc outline.
  final double edgeJitter;

  /// For fan: how many parallel tines to render.
  final int tineCount;

  /// For fan: length of each tine (along [angle]).
  final double tineLength;

  /// For fan: width of each tine (perpendicular to [angle]).
  final double tineWidth;

  Stamp copyWith({
    Offset? offset,
    double? radius,
    Color? color,
    double? alpha,
    StampShape? shape,
    double? angle,
    double? aspectRatio,
    double? edgeJitter,
    int? tineCount,
    double? tineLength,
    double? tineWidth,
  }) {
    return Stamp(
      offset: offset ?? this.offset,
      radius: radius ?? this.radius,
      color: color ?? this.color,
      alpha: alpha ?? this.alpha,
      shape: shape ?? this.shape,
      angle: angle ?? this.angle,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      edgeJitter: edgeJitter ?? this.edgeJitter,
      tineCount: tineCount ?? this.tineCount,
      tineLength: tineLength ?? this.tineLength,
      tineWidth: tineWidth ?? this.tineWidth,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Stamp &&
        other.offset == offset &&
        other.radius == radius &&
        other.color == color &&
        other.alpha == alpha &&
        other.shape == shape &&
        other.angle == angle &&
        other.aspectRatio == aspectRatio &&
        other.edgeJitter == edgeJitter &&
        other.tineCount == tineCount &&
        other.tineLength == tineLength &&
        other.tineWidth == tineWidth;
  }

  @override
  int get hashCode => Object.hash(
        offset,
        radius,
        color,
        alpha,
        shape,
        angle,
        aspectRatio,
        edgeJitter,
        tineCount,
        tineLength,
        tineWidth,
      );
}
