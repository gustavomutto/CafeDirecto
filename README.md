# CafeDirecto
Aplicativo para celular estilo markeplace , para la venta de cafe en granos


| Carpeta | Qué es |
| --- | --- |
| `server/` | API en Node.js + Express + PostgreSQL (se despliega en Railway) |
| `mobile_app/` | App en Flutter para Android y web |
| `flutter_app/` | Demo Flutter original con datos locales (sin servidor) |
| `src/`, `index.html` | Demo web original en React (Vite) |

Servidor en producción: https://cafedirecto-production.up.railway.app (Railway despliega `server/` desde la rama `gustavo`).

## Correr todo en local

1. Abrir Docker Desktop y crear la base de datos (solo la primera vez):

```bash
docker run -d --name cafedirecto-db -e POSTGRES_USER=cafe -e POSTGRES_PASSWORD=cafe_local -e POSTGRES_DB=cafedirecto -p 127.0.0.1:5432:5432 -v cafedirecto-pgdata:/var/lib/postgresql/data postgres:16-alpine
```

Las siguientes veces basta con `docker start cafedirecto-db`.

2. Arrancar la API (puerto 3000). En `server/` ejecutar `npm install` la primera vez y luego `start-local.cmd` (doble clic, o `.\start-local.cmd` en la terminal). Al iniciar crea o actualiza las tablas.

3. Arrancar la app apuntando a la API local:

```bash
cd mobile_app
flutter run -d chrome --dart-define=API_URL=http://localhost:3000
```

En local, los códigos para recuperar la contraseña se muestran en la terminal de la API (no se envían correos).

## Variables del servidor

| Variable | Obligatoria | Para qué |
| --- | --- | --- |
| `DATABASE_URL` | Sí | Conexión a PostgreSQL (Railway la da al agregar la base) |
| `JWT_SECRET` | Sí en producción | Firma las sesiones. Texto aleatorio de 48+ caracteres. Sin ella el servidor no arranca en Railway |
| `RESEND_API_KEY` | Sí en producción | Envío de correos con [Resend](https://resend.com) (códigos de recuperación de contraseña) |
| `MAIL_FROM` | Sí en producción | Remitente, por ejemplo `CaféDirecto <no-reply@tudominio.com>` (dominio verificado en Resend) |
| `DEEPL_API_KEY` o `GOOGLE_TRANSLATE_API_KEY` | No | Traducción de mayor calidad. Sin ellas se usa MyMemory (gratis, con límites) |
| `MYMEMORY_EMAIL` | No | Sube el límite diario gratuito de MyMemory |
| `PORT` | No | Puerto (Railway lo define solo) |

## Arquitectura (v3)

### App (`mobile_app/lib`) · capas con Provider y DTOs

```
lib/
├─ main.dart            arranque: avisos del teléfono, sesión guardada, runApp
├─ app/                 di.dart (inyección de dependencias), router.dart (rutas), app.dart (MaterialApp + providers)
├─ core/                config (URL del servidor), network (ApiClient), logging (AppLogger),
│                       notifications (avisos del teléfono), theme, utils (formatos, lectura de JSON), constants
├─ domain/
│  ├─ entities/         clases puras: Lot, Auction, Bid, Agreement, ChatMessage, AppNotification, CoffeeMarket…
│  └─ repositories/     contratos (interfaces): LotRepository, AuctionRepository, ChatRepository…
├─ data/
│  ├─ dtos/             JSON del servidor ⇄ entidades (LotDto.fromJson(...).toEntity(), LotInputDto.toJson(...))
│  ├─ datasources/      remote/ (una por módulo de la API) y local/ (token en el teléfono)
│  └─ repositories/     implementación de los contratos (usa datasources + DTOs)
└─ presentation/
   ├─ providers/        SessionProvider, NotificationsProvider, MarketProvider, AuctionDetailController
   ├─ screens/          una carpeta por módulo (auth, home, explore, lot, chat, orders, auctions, market, notifications…)
   └─ widgets/          piezas reutilizables
```

Regla: las pantallas **nunca** llaman HTTP. Usan un provider o un repositorio (`context.repo<LotRepository>()`),
el repositorio usa una fuente de datos y la fuente de datos usa `ApiClient`. Así cada capa se puede cambiar o probar sola.
Los registros (`AppLogger`) se ven en la pestaña **Run / Logcat** de Android Studio con el prefijo `CafeDirecto.`.

### Servidor (`server/src`)

```
index.js        arranque (migra la base, inicia el proceso de subastas, abre el puerto)
app.js          Express: middlewares y montaje de rutas
routes/         capa HTTP: auth, account, images, lots, auctions, conversations, agreements, notifications, market
services/       reglas de negocio compartidas: agreements, auctions, conversations, notifications, market
serialize.js    filas de la base → JSON (DTO) que consume la app
lib/http.js     errores con código, lectura segura del cuerpo y transacciones
db.js · auth.js · translate.js · mail.js · ratelimit.js
test/           pruebas de la API contra PostgreSQL real (`npm test`)
```

## Novedades de la v3

- **Subastas con fecha límite.** El caficultor abre una subasta desde su lote (precio base, incremento mínimo, sacos,
  duración y entrega). Los compradores pujan por libra y ven la oferta más alta; los demás compradores aparecen como
  "Comprador 1, 2…". Si alguien oferta en los últimos 2 minutos, el cierre se alarga 2 minutos. El caficultor elige
  la oferta que quiera (antes o después del cierre; tiene 7 días) y se registra el **acuerdo** y el chat con el ganador.
- **Notificaciones (campanita + aviso del teléfono).** Cuando un comprador abre un lote, el caficultor recibe
  "👀 *Fulano* está interesado en tu café" (máximo una vez por comprador y lote cada 24 h) y puede ver la lista de
  interesados y escribirles. También avisa: nueva oferta, te superaron, ganaste/perdiste, subasta terminada,
  cotizaciones, acuerdo registrado, cambios de estado y calificaciones.
- **Precio del café.** Precio interno de referencia de la FNC (por carga, kg y arroba), contrato C de la Bolsa de
  Nueva York (con variación e histórico), TRM oficial, prima del café colombiano, calculadora "¿cuánto vale mi café?"
  y el dólar en 20 países de América Latina (con la bolsa convertida a cada moneda).
- **Acuerdos** muestra las subastas abiertas y el acceso a subastar o pujar.
- **GitHub Actions** analiza, prueba y compila el APK de la app, y prueba la API con PostgreSQL en cada cambio.

### Endpoints nuevos

| Método | Ruta | Para qué |
| --- | --- | --- |
| GET | `/market/coffee` | Precio interno FNC, bolsa NY, TRM, conversiones e histórico (público) |
| GET | `/auctions` · `/auctions?mine=1` | Subastas activas · mis subastas o en las que pujé |
| POST | `/lots/:id/auction` | Abrir subasta (`basePriceLb, minIncrementLb, sacks, durationHours, incoterm`) |
| GET | `/auctions/:id` | Detalle con ofertas |
| POST | `/auctions/:id/bids` | Pujar (`priceLb`) |
| POST | `/auctions/:id/award` | Elegir oferta ganadora (`bidId`) → crea el acuerdo |
| POST | `/auctions/:id/cancel` | Cancelar |
| GET | `/lots/:id/interest` | Compradores que vieron el lote (solo el dueño) |
| GET | `/notifications` · `/notifications/unread` | Avisos (`?after=ID` para los nuevos) |
| POST | `/notifications/read` | Marcar leídos (`ids` o `all`) |

## Cambios de la v1.3

- Eliminar cuenta desde el perfil (exigido por Google Play). Pide la contraseña. Se borran perfil, lotes, conversaciones y fotos; si hay acuerdos registrados, se conservan para la otra parte sin datos personales.
- Recuperar contraseña con un código de 6 dígitos por correo (vence en 15 minutos, máximo 5 intentos). Al cambiarla se cierran las sesiones abiertas en otros dispositivos.
- `JWT_SECRET` obligatoria en producción.
- Límite de intentos: inicio de sesión (10 por correo y 50 por IP cada 15 min), registro (10 por hora), recuperación (10 por hora por IP y 3 por correo) y traducción (60 por minuto por usuario).
- La app deja de consultar el servidor cuando está en segundo plano, y la lista de chats solo se actualiza cuando está a la vista.
- Pulido: sin textos de "demo", botón de estado del pedido con estilo normal, íconos en lugar de emojis en los formularios, título y colores correctos en la versión web.

## Al desplegar en Railway

1. Agregar `JWT_SECRET`, `RESEND_API_KEY` y `MAIL_FROM` en las variables del servicio antes de desplegar.
2. Al cambiar `JWT_SECRET`, todas las sesiones abiertas se cierran y los usuarios deben volver a entrar una vez.
3. Las tablas nuevas se crean solas al arrancar.

## Pendiente antes de publicar en Google Play

- Firma de lanzamiento: crear tu propia clave (keystore) y configurarla en `mobile_app/android/app/build.gradle.kts`. Hoy firma con la clave de depuración.
- Ícono propio: hoy es el ícono por defecto de Flutter.
- Política de privacidad publicada en una URL (Google Play la pide, y la app usa el micrófono).
