// Colores de las opciones de apariencia (Perfil → Apariencia). Las opciones en sí
// (modo, color principal y tamaño de letra) están en domain/entities/appearance.dart.
import 'package:flutter/painting.dart';

import '../../domain/entities/appearance.dart';

export '../../domain/entities/appearance.dart';

class AccentColor {
  final Color light; // sobre fondos claros
  final Color dark; // sobre fondos oscuros
  const AccentColor(this.light, this.dark);
}

const accentColors = <AccentChoice, AccentColor>{
  AccentChoice.verde: AccentColor(Color(0xFF2F6B4F), Color(0xFF7DC49D)),
  AccentChoice.azul: AccentColor(Color(0xFF2E5C8A), Color(0xFF8DB8E4)),
  AccentChoice.vino: AccentColor(Color(0xFF7B2D3B), Color(0xFFE596A3)),
  AccentChoice.terracota: AccentColor(Color(0xFFA8492A), Color(0xFFEFA27C)),
};

/// Muestra de color para el selector (el "café" depende del rol y del modo).
Color accentSwatch(AccentChoice a, {required bool farmer, required bool dark}) {
  final c = accentColors[a];
  if (c != null) return dark ? c.dark : c.light;
  if (dark) return farmer ? const Color(0xFFD8A26F) : const Color(0xFFEFEAE3);
  return farmer ? const Color(0xFF5B3A29) : const Color(0xFF1F1A16);
}

double textScaleOf(TextSizeChoice s) => switch (s) {
      TextSizeChoice.normal => 1.0,
      TextSizeChoice.large => 1.15,
      TextSizeChoice.xlarge => 1.3,
    };
