// Colores y tipografía por rol: cálida para el caficultor, limpia para el comprador.
// Caficultor: cálido, de origen, botones grandes (Nunito, 17 px).
// Comprador: limpio, "specialty coffee", fotos protagonistas (Inter, 15 px).
//
// Cada rol tiene tres variantes (claro, neutro y oscuro) y se le puede cambiar el color principal
// (ver appearance.dart). Las pantallas nunca usan colores fijos: siempre `context.pal`.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'appearance.dart';

class Palette {
  final bool farmer;
  final bool dark;
  final Color bg, surface, surface2, ink, ink2, line, primary, primary2, primaryInk, accent, accentSoft, warm, warmSoft, danger;
  final double fs, radius, radiusSm, btnH;

  const Palette({
    required this.farmer,
    this.dark = false,
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

  Palette copyWith({Color? primary, Color? primary2, Color? primaryInk}) => Palette(
        farmer: farmer,
        dark: dark,
        bg: bg,
        surface: surface,
        surface2: surface2,
        ink: ink,
        ink2: ink2,
        line: line,
        primary: primary ?? this.primary,
        primary2: primary2 ?? this.primary2,
        primaryInk: primaryInk ?? this.primaryInk,
        accent: accent,
        accentSoft: accentSoft,
        warm: warm,
        warmSoft: warmSoft,
        danger: danger,
        fs: fs,
        radius: radius,
        radiusSm: radiusSm,
        btnH: btnH,
      );

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

// ── Neutro: grises sin el tono café, para quien prefiere una app más sobria ──────────
const farmerNeutralPalette = Palette(
  farmer: true,
  bg: Color(0xFFF3F3F1),
  surface: Color(0xFFFFFFFF),
  surface2: Color(0xFFE8E8E5),
  ink: Color(0xFF1F1F1D),
  ink2: Color(0xFF5F5F5A),
  line: Color(0xFFDADAD5),
  primary: Color(0xFF3B3632),
  primary2: Color(0xFF57514B),
  primaryInk: Color(0xFFFFFFFF),
  accent: Color(0xFF3E7B4F),
  accentSoft: Color(0xFFDDEBDF),
  warm: Color(0xFFB9772F),
  warmSoft: Color(0xFFF1E6D6),
  danger: Color(0xFFB4442F),
  fs: 17,
  radius: 20,
  radiusSm: 14,
  btnH: 56,
);

const buyerNeutralPalette = Palette(
  farmer: false,
  bg: Color(0xFFF4F4F4),
  surface: Color(0xFFFFFFFF),
  surface2: Color(0xFFEAEAEA),
  ink: Color(0xFF151515),
  ink2: Color(0xFF636363),
  line: Color(0xFFDDDDDD),
  primary: Color(0xFF1E1E1E),
  primary2: Color(0xFF3A3A3A),
  primaryInk: Color(0xFFFFFFFF),
  accent: Color(0xFF2F6B4F),
  accentSoft: Color(0xFFE1EDE6),
  warm: Color(0xFFA8642E),
  warmSoft: Color(0xFFF1E7DD),
  danger: Color(0xFFB4442F),
  fs: 15,
  radius: 16,
  radiusSm: 12,
  btnH: 48,
);

// ── Oscuro: fondos café muy oscuros, texto claro y colores un poco más suaves ─────────
// Los colores de estado (accent, warm, danger) se mantienen en tono medio para que el
// texto blanco encima siga leyéndose bien.
const farmerDarkPalette = Palette(
  farmer: true,
  dark: true,
  bg: Color(0xFF17110E),
  surface: Color(0xFF221914),
  surface2: Color(0xFF2E231C),
  ink: Color(0xFFF4EADD),
  ink2: Color(0xFFC0AC9A),
  line: Color(0xFF3B2D24),
  primary: Color(0xFFD8A26F),
  primary2: Color(0xFFE6B98C),
  primaryInk: Color(0xFF26170D),
  accent: Color(0xFF4C9963),
  accentSoft: Color(0xFF1E3326),
  warm: Color(0xFFC77B33),
  warmSoft: Color(0xFF3A2817),
  danger: Color(0xFFC9553F),
  fs: 17,
  radius: 20,
  radiusSm: 14,
  btnH: 56,
);

const buyerDarkPalette = Palette(
  farmer: false,
  dark: true,
  bg: Color(0xFF111010),
  surface: Color(0xFF1B1A18),
  surface2: Color(0xFF262421),
  ink: Color(0xFFF2F0EC),
  ink2: Color(0xFFA9A39B),
  line: Color(0xFF33302C),
  primary: Color(0xFFEFEAE3),
  primary2: Color(0xFFD6D0C7),
  primaryInk: Color(0xFF161412),
  accent: Color(0xFF45936D),
  accentSoft: Color(0xFF1B2D24),
  warm: Color(0xFFC07436),
  warmSoft: Color(0xFF33251A),
  danger: Color(0xFFC9553F),
  fs: 15,
  radius: 16,
  radiusSm: 12,
  btnH: 48,
);

/// Paleta del rol según la apariencia elegida.
///  · [mode]: claro, neutro u oscuro (el modo "automático" ya llega resuelto a claro u oscuro).
///  · [accent]: color principal; `cafe` deja el del rol.
Palette resolvePalette(String role, {ThemeChoice mode = ThemeChoice.light, AccentChoice accent = AccentChoice.cafe}) {
  final farmer = role == 'farmer';
  final base = switch (mode) {
    ThemeChoice.dark => farmer ? farmerDarkPalette : buyerDarkPalette,
    ThemeChoice.neutral => farmer ? farmerNeutralPalette : buyerNeutralPalette,
    _ => farmer ? farmerPalette : buyerPalette,
  };
  final c = accentColors[accent];
  if (c == null) return base;
  final primary = base.dark ? c.dark : c.light;
  return base.copyWith(
    primary: primary,
    primary2: Color.lerp(primary, base.dark ? Colors.white : Colors.black, 0.18),
    primaryInk: base.dark ? const Color(0xFF15110E) : Colors.white,
  );
}

/// Paleta clara del rol (sin preferencias de apariencia).
Palette paletteFor(String role) => resolvePalette(role);

ThemeData buildTheme(Palette p) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: p.dark ? Brightness.dark : Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: p.primary,
      brightness: p.dark ? Brightness.dark : Brightness.light,
      primary: p.primary,
      onPrimary: p.primaryInk,
      secondary: p.accent,
      surface: p.surface,
      onSurface: p.ink,
      onSurfaceVariant: p.ink2,
      outline: p.line,
      error: p.danger,
    ),
    scaffoldBackgroundColor: p.bg,
    canvasColor: p.surface,
    dividerColor: p.line,
  );
  final textTheme = (p.farmer ? GoogleFonts.nunitoTextTheme(base.textTheme) : GoogleFonts.interTextTheme(base.textTheme))
      .apply(bodyColor: p.ink, displayColor: p.ink);
  return base.copyWith(
    textTheme: textTheme,
    sliderTheme: SliderThemeData(activeTrackColor: p.primary, thumbColor: p.primary, inactiveTrackColor: p.line),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      titleTextStyle: p.display(size: 22),
      contentTextStyle: p.text(color: p.ink),
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: p.surface, modalBackgroundColor: p.surface),
    popupMenuTheme: PopupMenuThemeData(color: p.surface2, textStyle: p.text()),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primary),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: p.primary)),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: p.primary, foregroundColor: p.primaryInk)),
    textSelectionTheme: TextSelectionThemeData(cursorColor: p.primary, selectionHandleColor: p.primary),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface,
      hintStyle: p.text(color: p.ink2.withValues(alpha: 0.8)),
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
