/// Preferencias de apariencia de la persona (se guardan en el teléfono).
library;

/// Modo de color. `system` sigue el modo claro/oscuro del teléfono.
enum ThemeChoice { light, neutral, dark, system }

/// Color principal de botones y títulos. `cafe` es el propio de cada rol.
enum AccentChoice { cafe, verde, azul, vino, terracota }

/// Tamaño del texto en toda la app.
enum TextSizeChoice { normal, large, xlarge }

class AppearanceSettings {
  final ThemeChoice theme;
  final AccentChoice accent;
  final TextSizeChoice textSize;
  const AppearanceSettings({this.theme = ThemeChoice.light, this.accent = AccentChoice.cafe, this.textSize = TextSizeChoice.normal});

  static const defaults = AppearanceSettings();

  AppearanceSettings copyWith({ThemeChoice? theme, AccentChoice? accent, TextSizeChoice? textSize}) =>
      AppearanceSettings(theme: theme ?? this.theme, accent: accent ?? this.accent, textSize: textSize ?? this.textSize);

  @override
  bool operator ==(Object other) =>
      other is AppearanceSettings && other.theme == theme && other.accent == accent && other.textSize == textSize;

  @override
  int get hashCode => Object.hash(theme, accent, textSize);
}
