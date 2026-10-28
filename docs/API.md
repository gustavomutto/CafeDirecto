# API de CaféDirecto · referencia

Base: `https://cafedirecto-production.up.railway.app` · JSON en UTF-8 · versión 3.

- **Autenticación:** encabezado `Authorization: Bearer <token>` (el token llega al registrarse o iniciar sesión).
  Las rutas marcadas con 🔓 no lo necesitan.
- **Errores:** `{ "error": "mensaje para mostrar" }` con código 400 (dato inválido), 401 (sin sesión),
  403 (sin permiso), 404, 409 (duplicado), 429 (demasiados intentos; trae `Retry-After`) o 500.
- **Fechas:** milisegundos desde 1970 (`createdAt`, `endsAt`…).
- **Textos bilingües:** `{ "es": "…", "en": "…" }`.
- **Fotos:** las direcciones llegan firmadas (`/images/12?s=FIRMA`); se usan tal cual.
- Cada respuesta trae `X-Request-Id` para buscarla en los registros de Railway.

## Salud y páginas

| Método | Ruta | Descripción |
| --- | --- | --- |
| GET 🔓 | `/` | Versión y traductor activo |
| GET 🔓 | `/health` | Comprueba la base de datos (lo usa Railway) |
| GET 🔓 | `/privacy` (`/privacidad`) | Política de privacidad y cómo eliminar la cuenta (para Google Play) |

## Cuenta

| Método | Ruta | Cuerpo | Respuesta |
| --- | --- | --- | --- |
| POST 🔓 | `/auth/register` | `email, password (8+ letras y números), role ('farmer'\|'buyer'), name, lang, phone?` · caficultor: `farmName, region, municipality` · comprador: `company, city, country, type` | `201 { token, user }` |
| POST 🔓 | `/auth/login` | `email, password` | `{ token, user }` |
| POST 🔓 | `/auth/forgot` | `email` | `{ ok }` (igual exista o no el correo) |
| POST 🔓 | `/auth/reset` | `email, code (6 dígitos), password` | `{ token, user }` (cierra las demás sesiones) |
| GET | `/me` | — | `{ user, profile }` |
| PUT | `/me` | `name?, phone?, lang?, photoId?` | `{ user, profile }` |
| PUT | `/me/profile` | Finca: `name, region, municipality, altitude (0–6000), hectares, sca (0–100), since, varieties[], processes[], notes[], story, quote, certifications, coverId, gallery[]` · Comprador: `company, city, country, type, volume, since, about, looking, coverId` | `{ user, profile }` (los textos se traducen) |
| DELETE | `/me` | `password` | `{ ok }` |
| GET | `/users/:id` | — | `{ user, profile, lots? }` |

## Fotos

| Método | Ruta | Detalle |
| --- | --- | --- |
| POST | `/images` | `multipart/form-data`, campo `file`, máx. 6 MB, JPG/PNG/WEBP/GIF/HEIC (se revisa el contenido). 60 por hora. → `201 { id, url }` |
| GET 🔓 | `/images/:id?s=FIRMA` | La imagen. Sin firma válida → 404 |

Un `photoId`/`coverId`/`gallery` solo se acepta si la foto la subió el mismo usuario.

## Lotes

| Método | Ruta | Detalle |
| --- | --- | --- |
| GET | `/lots` | Filtros: `q, region, process, variety (separados por coma), minSca, minAlt, farmerId, auction=1` |
| POST | `/lots` | `name, variety, process ('lavado'\|'honey'\|'natural'), sacks (0–100000), sca (80–100), priceLb (0,01–100), priceCarga?, notes[], harvest, photoId` (solo caficultor) |
| GET | `/lots/:id` | Incluye `certifications`, `auction` (si hay subasta abierta) e `interest` (solo el dueño). Si quien lo abre es comprador, se avisa al caficultor |
| PUT | `/lots/:id` | Igual que POST (solo el dueño) |
| DELETE | `/lots/:id` | Lo retira (no se puede con una subasta abierta) |
| GET | `/lots/:id/interest` | Compradores que lo vieron (solo el dueño) |

## Subastas

| Método | Ruta | Detalle |
| --- | --- | --- |
| GET | `/auctions` | Activas. `?mine=1`: las mías (caficultor) o en las que pujé (comprador) |
| POST | `/lots/:id/auction` | `basePriceLb, minIncrementLb (0,01–5), sacks, durationHours (1–720), incoterm` |
| GET | `/auctions/:id` | Fase (`live`, `ended`, `awarded`, `cancelled`, `expired`), ofertas, `minNext`, `myBest`, `leading` |
| POST | `/auctions/:id/bids` | `priceLb` ≥ oferta mayor + incremento (solo compradores; 30 por minuto) |
| POST | `/auctions/:id/award` | `bidId` → crea el acuerdo y el chat → `{ auction, agreementId }` |
| POST | `/auctions/:id/cancel` | Cierra sin ganador |

## Chat y cotizaciones

| Método | Ruta | Detalle |
| --- | --- | --- |
| GET | `/conversations` | Mis chats con último mensaje y no leídos |
| POST | `/conversations` | `userId, lotId?` → abre o reutiliza el chat |
| GET | `/conversations/:id` | Resumen del chat |
| GET | `/conversations/:id/messages?after=ID` | Mensajes con id mayor que `after` |
| POST | `/conversations/:id/messages` | `type ('text'\|'photo'), text, lang, viaVoice, photoId` (40 por minuto). Se traduce al idioma del otro |
| POST | `/conversations/:id/read` | `lastId` |
| POST | `/conversations/:id/quotes` | `lotId, priceLb (0,01–100), sacks, incoterm` |
| POST | `/messages/:id/quote` | `action: 'counter' (priceLb, sacks) \| 'accept' \| 'confirm'` → al confirmar se crea el acuerdo |
| GET | `/unread` | `{ unread, notifications, latestNotificationId }` |

## Acuerdos

| Método | Ruta | Detalle |
| --- | --- | --- |
| GET | `/agreements` · `/agreements/:id` | Con calificaciones, reporte de calidad y disputas |
| POST | `/agreements/:id/advance` | 1→2 "enviado" (solo el caficultor) · 2→3 "entregado" (solo el comprador) |
| POST | `/agreements/:id/rate` | `stars (1–5), tags[], comment` (después de la entrega, una vez) |
| POST | `/agreements/:id/quality` | `sca, moisture, defects, matchesSample, notes[], comment, photoId` (comprador, después de la entrega) |
| POST | `/agreements/:id/disputes` | `reason ('quality'\|'quantity'\|'delay'\|'payment'\|'other'), text, photoId?` |
| POST | `/disputes/:id/comments` | `text, photoId?` |
| POST | `/disputes/:id/resolve` | Solo quien la abrió |

## Notificaciones

| Método | Ruta | Detalle |
| --- | --- | --- |
| GET | `/notifications` | `?after=ID` (nuevas) · `?before=ID&limit=50` (anteriores) → `{ items, unread }` |
| GET | `/notifications/unread` | `{ unread, latestId }` |
| POST | `/notifications/read` | `{ ids: [..] }` o `{ all: true }` |

Tipos: `lot_interest`, `auction_opened`, `bid_new`, `bid_outbid`, `auction_ended`, `auction_won`, `auction_lost`,
`auction_cancelled`, `auction_expired`, `quote_new`, `quote_counter`, `quote_accepted`, `agreement_new`,
`agreement_status`, `rating_new`. El campo `data` indica a qué pantalla lleva (`lotId`, `auctionId`, `conversationId`, `agreementId`, `userId`).

## Mercado

| Método | Ruta | Detalle |
| --- | --- | --- |
| GET 🔓 | `/market/coffee` | `internal` (precio FNC por carga), `ny` (contrato C en ¢/lb + histórico), `trm` (+ histórico), `derived` (por kg, por arroba, US$/lb, prima), `internalHistory`, `constants` |
| POST | `/translate` | `text, from` → `{ text, from, to }` (60 por minuto) |

## Variables de entorno

| Variable | Obligatoria | Uso |
| --- | --- | --- |
| `DATABASE_URL` | Sí | PostgreSQL |
| `JWT_SECRET` | Sí en producción | Firma de sesiones (48+ caracteres aleatorios) |
| `MEDIA_SECRET` | No | Firma de las fotos (si no está, se deriva de `JWT_SECRET`) |
| `RESEND_API_KEY`, `MAIL_FROM` | Para recuperar contraseña | Envío de correos |
| `DEEPL_API_KEY` / `GOOGLE_TRANSLATE_API_KEY` | No | Mejor traducción (si no, MyMemory) |
| `MYMEMORY_EMAIL` | No | Sube el límite gratuito de MyMemory |
| `CORS_ORIGINS` | No | Orígenes web permitidos, separados por coma |
| `CONTACT_EMAIL` | Recomendada | Correo de contacto en `/privacy` |
