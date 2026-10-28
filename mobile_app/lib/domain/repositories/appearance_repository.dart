import '../entities/appearance.dart';

/// Guarda y lee la apariencia elegida (modo, color principal y tamaño de letra).
abstract class AppearanceRepository {
  Future<AppearanceSettings> load();
  Future<void> save(AppearanceSettings settings);
}
