# CaféDirecto · App (Flutter)

App de CaféDirecto para Android (y web) que conecta a caficultores colombianos con compradores de café de especialidad. Se conecta a la API de la carpeta `../server`.

## Ejecutar

Con la API publicada en Railway (valor por defecto de `lib/config.dart`):

```bash
flutter run
```

Con la API local (ver `../README.md`):

```bash
flutter run -d chrome --dart-define=API_URL=http://localhost:3000
```

En un celular Android conectado por USB, cambia `localhost` por la IP de tu computador en la red wifi (por ejemplo `http://192.168.1.20:3000`).

## Pruebas y análisis

```bash
flutter analyze
flutter test
```

## Generar el APK o el paquete para Google Play

```bash
flutter build appbundle --dart-define=API_URL=https://TU-API.up.railway.app
```

Antes de publicar en Google Play falta configurar la firma de la versión de lanzamiento (`android/app/build.gradle.kts` todavía firma con la clave de depuración) y reemplazar el ícono por defecto de Flutter en `android/app/src/main/res/mipmap-*`.

## Estructura

| Carpeta | Contenido |
| --- | --- |
| `lib/api` | Cliente HTTP de la API |
| `lib/state` | Sesión, pestaña activa, mensajes sin leer y avisos |
| `lib/screens` | Pantallas (inicio de sesión, explorar, chat, acuerdos, perfil…) |
| `lib/widgets` | Componentes reutilizables (tarjetas, botones, cotización, acuerdo) |
| `lib/data` | Catálogos fijos: regiones, variedades, contenido de "Aprende" |
| `lib/theme` | Colores y tipografía por rol |
