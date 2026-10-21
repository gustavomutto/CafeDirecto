// Colores y tipografía por rol, igual que en la demo web.
// Caficultor: cálido, de origen, botones grandes (Nunito, 17 px).
// Comprador: limpio, "specialty coffee", fotos protagonistas (Inter, 15 px).
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Palette {
  final bool farmer;
  final Color bg, surface, surface2, ink, ink2, line, primary, primary2, primaryInk, accent, accentSoft, warm, warmSoft, danger;
  final double fs, radius, radiusSm, btnH;

  const Palette({
    required this.farmer,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.ink,
    required this.ink2,
    required this.line,
    required this.primary,
    required this.primary2,
    required this.primaryInk,
    required this.accent,
    required this.accentSoft,
    required this.warm,
    required this.warmSoft,
    required this.danger,
    required this.fs,
    required this.radius,
    required this.radiusSm,
    required this.btnH,
  });

  static const star = Color(0xFFE0A030);

  /// Texto normal con la fuente del rol.
  TextStyle text({double? size, FontWeight weight = FontWeight.w500, Color? color, double? height}) {
    final base = farmer ? GoogleFonts.nunito() : GoogleFonts.inter();
    return base.copyWith(fontSize: size ?? fs, fontWeight: weight, color: color ?? ink, height: height);
  }

  /// Títulos con Fraunces (serif).
  TextStyle display({double size = 26, FontWeight weight = FontWeight.w700, Color? color, double? height}) =>
      GoogleFonts.fraunces(fontSize: size, fontWeight: weight, color: color ?? ink, height: height ?? 1.15);

  TextStyle muted({double? size, FontWeight weight = FontWeight.w500}) => text(size: size ?? fs - 2, weight: weight, color: ink2);
}

const farmerPalette = Palette(
  farmer: true,
  bg: Color(0xFFF5EDE0),
  surface: Color(0xFFFFFBF4),
  surface2: Color(0xFFEFE3D1),
  ink: Color(0xFF2B1D14),
  ink2: Color(0xFF6E5646),
  line: Color(0xFFE3D4BF),
  primary: Color(0xFF5B3A29),
  primary2: Color(0xFF7A4F37),
  primaryInk: Color(0xFFFFFAF2),
  accent: Color(0xFF3E7B4F),
  accentSoft: Color(0xFFDCEBDC),
  warm: Color(0xFFC8782A),
  warmSoft: Color(0xFFF6E2CB),
  danger: Color(0xFFB4442F),
  fs: 17,
  radius: 20,
  radiusSm: 14,
  btnH: 56,
);

const buyerPalette = Palette(
  farmer: false,
  bg: Color(0xFFF7F6F3),
  surface: Color(0xFFFFFFFF),
  surface2: Color(0xFFF0EEE9),
  ink: Color(0xFF171512),
  ink2: Color(0xFF6E6A63),
  line: Color(0xFFE8E4DD),
  primary: Color(0xFF1F1A16),
  primary2: Color(0xFF3A322B),
  primaryInk: Color(0xFFFFFFFF),
  accent: Color(0xFF2F6B4F),
  accentSoft: Color(0xFFE2EFE7),
  warm: Color(0xFFB5662B),
  warmSoft: Color(0xFFF5E6D8),
  danger: Color(0xFFB4442F),
  fs: 15,
  radius: 16,
  radiusSm: 12,
  btnH: 48,
);

Palette paletteFor(String role) => role == 'farmer' ? farmerPalette : buyerPalette;

ThemeData buildTheme(Palette p) {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: p.primary,
      primary: p.primary,
      onPrimary: p.primaryInk,
      secondary: p.accent,
      surface: p.surface,
      error: p.danger,
    ),
    scaffoldBackgroundColor: p.bg,
  );
  final textTheme = (p.farmer ? GoogleFonts.nunitoTextTheme(base.textTheme) : GoogleFonts.interTextTheme(base.textTheme))
      .apply(bodyColor: p.ink, displayColor: p.ink);
  return base.copyWith(
    textTheme: textTheme,
    sliderTheme: SliderThemeData(activeTrackColor: p.primary, thumbColor: p.primary, inactiveTrackColor: p.line),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(p.radiusSm), borderSide: BorderSide(color: p.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(p.radiusSm), borderSide: BorderSide(color: p.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(p.radiusSm), borderSide: BorderSide(color: p.primary, width: 1.6)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      indicatorColor: p.farmer ? p.warmSoft : p.surface2,
      height: p.farmer ? 76 : 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => p.text(
          size: p.farmer ? 13 : 12,
          weight: s.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
          color: s.contains(WidgetState.selected) ? p.primary : p.ink2,
        ),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: ZoomPageTransitionsBuilder()},
    ),
  );
}
