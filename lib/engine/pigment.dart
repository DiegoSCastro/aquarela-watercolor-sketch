import 'package:flutter/material.dart';

import 'package:aquarela_watercolor_sketch/config/palette_ids.dart';

/// A pigment is a pure color with a watercolor "personality":
/// - [absorption]: how much the paper drinks it (0 = none, 1 = a lot)
/// - [granulation]: 0 = smooth, 1 = visible grain texture
///
/// 12 curated pigments ship in [Pigment.curated], inspired by real
/// watercolor paint names from Winsor & Newton and Daniel Smith.
@immutable
class Pigment {
  const Pigment({
    required this.id,
    required this.name,
    required this.color,
    required this.absorption,
    this.granulation = 0.0,
  });

  final PigmentId id;
  final String name;
  final Color color;
  final double absorption;
  final double granulation;

  // ---------- Brand pigments (always free) ----------

  /// #1E3A8A — Ultramarine. Brand primary.
  static const ultramar = Pigment(
    id: PigmentId.ultramar,
    name: 'Ultramar',
    color: Color(0xFF1E3A8A),
    absorption: 0.7,
  );

  /// #9B5D3A — Burnt Sienna. Brand secondary.
  static const burntSienna = Pigment(
    id: PigmentId.burntSienna,
    name: 'Terra Siena Queimada',
    color: Color(0xFF9B5D3A),
    absorption: 0.6,
    granulation: 0.7,
  );

  /// #F2C94C — Cadmium Yellow. Brand accent.
  static const cadmiumYellow = Pigment(
    id: PigmentId.cadmiumYellow,
    name: 'Amarelo Cádmio',
    color: Color(0xFFF2C94C),
    absorption: 0.3,
  );

  /// #2D3142 — Payne's Gray. Brand text/ink.
  static const paynesGray = Pigment(
    id: PigmentId.paynesGray,
    name: 'Cinza de Payne',
    color: Color(0xFF2D3142),
    absorption: 0.8,
  );

  // ---------- Pro-only pigments ----------

  /// Viridian (Pro).
  static const viridian = Pigment(
    id: PigmentId.viridian,
    name: 'Viridiana',
    color: Color(0xFF40826D),
    absorption: 0.5,
    granulation: 0.4,
  );

  static const alizarinCrimson = Pigment(
    id: PigmentId.alizarinCrimson,
    name: 'Carmim de Alizarina',
    color: Color(0xFF7A1F2B),
    absorption: 0.6,
  );

  static const cerulean = Pigment(
    id: PigmentId.cerulean,
    name: 'Cerúleo',
    color: Color(0xFF3A8FB7),
    absorption: 0.4,
    granulation: 0.5,
  );

  static const lemonYellow = Pigment(
    id: PigmentId.lemonYellow,
    name: 'Amarelo Limão',
    color: Color(0xFFFFE066),
    absorption: 0.2,
  );

  static const roseMadder = Pigment(
    id: PigmentId.roseMadder,
    name: 'Rosa Madder',
    color: Color(0xFFC25A7C),
    absorption: 0.5,
  );

  static const sapGreen = Pigment(
    id: PigmentId.sapGreen,
    name: 'Verde Seiva',
    color: Color(0xFF7A8B3D),
    absorption: 0.5,
  );

  static const indigo = Pigment(
    id: PigmentId.indigo,
    name: 'Anil',
    color: Color(0xFF3F4A6B),
    absorption: 0.7,
  );

  static const sepia = Pigment(
    id: PigmentId.sepia,
    name: 'Sépia',
    color: Color(0xFF704A2B),
    absorption: 0.6,
    granulation: 0.6,
  );

  /// The curated 12-pigment palette, in display order.
  /// First 4 are free, the rest are Pro-only.
  static const curated = <Pigment>[
    ultramar,
    burntSienna,
    cadmiumYellow,
    paynesGray,
    viridian,
    alizarinCrimson,
    cerulean,
    lemonYellow,
    roseMadder,
    sapGreen,
    indigo,
    sepia,
  ];

  /// Lookup by [PigmentId]. Returns null if not found.
  static Pigment? byId(PigmentId id) {
    for (final p in curated) {
      if (p.id == id) return p;
    }
    return null;
  }
}
