# CaféDirecto · App (Flutter)

App de CaféDirecto para Android (y web) que conecta a caficultores colombianos con compradores de café de especialidad. Se conecta a la API de la carpeta `../server`.

## Ejecutar

Con la API publicada en Railway (valor por defecto de `lib/core/config/env.dart`):

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

## Estructura por capas

| Carpeta | Contenido |
| --- | --- |
| `lib/app` | `di.dart` arma todo (ApiClient → DataSources → Repositories → Providers), `router.dart` las rutas, `app.dart` el MaterialApp |
| `lib/core` | Configuración, `ApiClient`, `AppLogger`, avisos del teléfono, tema, formatos y catálogos fijos |
| `lib/domain/entities` | Entidades puras (Lot, Auction, Agreement, ChatMessage, AppNotification, CoffeeMarket…) |
| `lib/domain/repositories` | Contratos que usan las pantallas (LotRepository, AuctionRepository…) |
| `lib/data/dtos` | DTOs: convierten el JSON del servidor en entidades y las entidades en JSON |
| `lib/data/datasources` | `remote/` una por módulo de la API · `local/` el token en el teléfono |
| `lib/data/repositories` | Implementaciones de los contratos |
| `lib/presentation/providers` | Estado con Provider: sesión, notificaciones, mercado, subasta en pantalla |
| `lib/presentation/screens` | Pantallas por módulo (auth, home, explore, lot, chat, orders, auctions, market, notifications, profile, learn) |
| `lib/presentation/widgets` | Componentes reutilizables |

### Cómo se usa en una pantalla

```dart
// Leer datos: la pantalla pide al repositorio (no sabe que hay HTTP detrás)
Loader<Lot>(
  load: () => context.repo<LotRepository>().get(lotId),
  builder: (context, lot, reload) => LotView(lot: lot),
);

// Estado compartido: Provider
final unread = context.watch<NotificationsProvider>().unreadMessages;
final app = context.app;          // sesión (se redibuja al cambiar)
context.session.showToast('Listo'); // sesión dentro de un botón
```

### Registros (logs)

`AppLogger.d/i/w/e(...)` escribe en la consola de Android Studio (pestaña **Run** o **Logcat**, filtro `CafeDirecto`).
Cada llamada a la API queda registrada con su código y tiempo, por ejemplo `GET /lots → 200 (183 ms)`.
