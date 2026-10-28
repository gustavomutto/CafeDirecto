import '../../domain/entities/appearance.dart';
import '../../domain/repositories/appearance_repository.dart';
import '../datasources/local/appearance_local_datasource.dart';

class AppearanceRepositoryImpl implements AppearanceRepository {
  final AppearanceLocalDataSource _local;
  AppearanceRepositoryImpl(this._local);

  static T _byName<T extends Enum>(List<T> values, String? name, T fallback) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }

  @override
  Future<AppearanceSettings> load() async {
    final m = await _local.read();
    const d = AppearanceSettings.defaults;
    return AppearanceSettings(
      theme: _byName(ThemeChoice.values, m['theme'], d.theme),
      accent: _byName(AccentChoice.values, m['accent'], d.accent),
      textSize: _byName(TextSizeChoice.values, m['textSize'], d.textSize),
    );
  }

  @override
  Future<void> save(AppearanceSettings s) => _local.write(theme: s.theme.name, accent: s.accent.name, textSize: s.textSize.name);
}
