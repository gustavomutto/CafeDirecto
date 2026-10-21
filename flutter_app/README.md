# CaféDirecto Flutter

Aplicación móvil nativa escrita en Dart. No carga la aplicación React ni utiliza WebView.

## Ejecutar en un teléfono o emulador

Desde esta carpeta, con Flutter y Android Studio instalados:

```powershell
flutter pub get
flutter run
```

Conecta un dispositivo Android con depuración USB activada o inicia un emulador. Si Android solicita licencias del SDK, revísalas y acéptalas con `flutter doctor --android-licenses`.

Para crear un APK de depuración:

```powershell
flutter build apk --debug
```

El APK queda en `build/app/outputs/flutter-apk/app-debug.apk`.

## Código

- `lib/main.dart`: tema, onboarding y navegación inferior.
- `lib/screens.dart`: pantallas, widgets compartidos y formularios.
- `lib/app_state.dart`: estado, acciones y persistencia local.
- `lib/coffee_data.dart`: datos de ejemplo.
- `lib/models.dart`: modelos del dominio.

Los datos son de demostración y se conservan en el dispositivo mediante `shared_preferences`. No hay backend ni traducción automática en tiempo real.
