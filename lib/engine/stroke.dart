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
