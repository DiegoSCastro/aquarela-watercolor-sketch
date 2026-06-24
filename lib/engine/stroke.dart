import 'package:flutter/material.dart';

import 'package:aquarela_watercolor_sketch/config/palette_ids.dart';
import 'package:aquarela_watercolor_sketch/engine/brush.dart';
import 'package:aquarela_watercolor_sketch/engine/stamp.dart';

/// A stroke is the painted record of a single finger drag (or
/// mouse drag, or stylus stroke). It carries the brush, the pigment,
/// the raw path, and the pre-computed [stamps] used to render it.
@immutable
class Stroke {
  const Stroke({
    required this.id,
    required this.brush,
    required this.pigment,
    required this.path,
    required this.stamps,
    required this.createdAt,
  });

  final String id;
  final Brush brush;
  final PigmentId pigment;
  final List<Offset> path;
  final List<Stamp> stamps;
  final DateTime? createdAt;

  /// A stroke is "finalized" once [createdAt] is set, i.e. the user
  /// lifted their finger. Unfinalized strokes can still be appended
  /// to (live preview during a drag).
  bool get isFinalized => createdAt != null;

  /// How long ago the stroke was finalized. Returns [Duration.zero]
  /// for unfinalized strokes.
  Duration age([DateTime? now]) {
    if (createdAt == null) return Duration.zero;
    return (now ?? DateTime.now()).difference(createdAt!);
  }

  /// A stroke counts as "wet" within 2 seconds of being created.
  /// Wet strokes participate in wet-on-wet bleeding.
  bool get isWet => age() < const Duration(seconds: 2);

  Stroke copyWith({
    String? id,
    Brush? brush,
    PigmentId? pigment,
    List<Offset>? path,
    List<Stamp>? stamps,
    DateTime? createdAt,
  }) {
    return Stroke(
      id: id ?? this.id,
      brush: brush ?? this.brush,
      pigment: pigment ?? this.pigment,
      path: path ?? this.path,
      stamps: stamps ?? this.stamps,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Lazily-computed bounding box cache, stored externally so the
/// [Stroke] class stays `@immutable`. The wet-mix algorithm calls
/// the `bounds` getter for every existing stroke on every touch
/// event — caching turns the repeated cost from O(stamps) per
/// stroke into O(1) for the amortized path.
///
/// `Expando` is keyed by the stroke instance, so the cache is
/// garbage-collected with the stroke (no leaks).
final Expando<Rect> _boundsCache = Expando<Rect>();

/// Get the bounding box of all stamp offsets in the stroke.
/// Computes on first call, cached for all subsequent calls on the
/// same instance. The bound ignores stamp radius — it captures the
/// spatial extent of the path, which is what wet-mix needs to
/// filter by proximity.
extension StrokeBounds on Stroke {
  Rect get bounds {
    final cached = _boundsCache[this];
    if (cached != null) return cached;
    if (stamps.isEmpty) {
      // No stamps yet — fall back to the raw path so a single-point
      // stroke still has a non-infinite bounding box.
      if (path.isEmpty) return _boundsCache[this] = Rect.zero;
      final p = path.first;
      return _boundsCache[this] = Rect.fromLTWH(p.dx, p.dy, 0, 0);
    }
    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;
    for (final s in stamps) {
      if (s.offset.dx < minX) minX = s.offset.dx;
      if (s.offset.dy < minY) minY = s.offset.dy;
      if (s.offset.dx > maxX) maxX = s.offset.dx;
      if (s.offset.dy > maxY) maxY = s.offset.dy;
    }
    return _boundsCache[this] = Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}
