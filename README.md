# CaféDirecto

Aplicación móvil de demostración para caficultores y compradores de café colombiano. La aplicación principal está desarrollada en **Flutter y Dart** y abre como app nativa; no necesita un navegador ni una WebView. Los datos son locales y de ejemplo, sin backend.

## Ejecutar en un teléfono Android

1. Instala Flutter y Android Studio, conecta un teléfono con la depuración USB activada o inicia un emulador.
2. Desde la carpeta del proyecto:

   ```powershell
   cd flutter_app
   flutter pub get
   flutter run
   ```

Para generar un APK de depuración e instalarlo manualmente:

```powershell
cd flutter_app
flutter build apk --debug
```

El APK queda en `flutter_app/build/app/outputs/flutter-apk/app-debug.apk`.

## Pantallas y funciones

- Onboarding con selección de rol: caficultor o comprador.
- Inicio del caficultor y catálogo de lotes para compradores, con búsqueda por texto y filtros de región.
- Detalle del café y de su finca de origen.
- Bandeja de conversaciones y chat con persistencia local.
- Acuerdos de ejemplo y detalle de sus condiciones.
- Publicación de lotes, aprendizaje y perfil.
- Panel de demostración en el perfil para cambiar de rol, simular desconexión o reiniciar los datos.

El estado del onboarding, rol, lotes nuevos y mensajes se guarda en el dispositivo con `shared_preferences`. No hay servicio remoto ni traducción en vivo: la interfaz y los datos incluidos son una demo funcional.

## Organización del código Flutter

```text
flutter_app/
├─ lib/
│  ├─ main.dart          Tema, onboarding y navegación principal
│  ├─ screens.dart       Pantallas, formularios y widgets reutilizables
│  ├─ app_state.dart     Estado de la demo y persistencia local
│  ├─ coffee_data.dart  Fincas, lotes, conversaciones y acuerdos iniciales
│  └─ models.dart        Modelos de datos
├─ test/
└─ android/              Proyecto Android generado por Flutter
```

## Prototipo web anterior

La carpeta `src/` conserva la versión React + Vite como referencia del prototipo. Para ejecutarla opcionalmente en un navegador, usa `npm install` y `npm run dev` desde la raíz. La app para celular es la que está en `flutter_app/`.
