# CaféDirecto

[![App Flutter](https://github.com/gustavomutto/CafeDirecto/actions/workflows/flutter.yml/badge.svg?branch=gustavo)](https://github.com/gustavomutto/CafeDirecto/actions/workflows/flutter.yml)
[![Servidor](https://github.com/gustavomutto/CafeDirecto/actions/workflows/server.yml/badge.svg?branch=gustavo)](https://github.com/gustavomutto/CafeDirecto/actions/workflows/server.yml)

Marketplace móvil que conecta **caficultores colombianos** con **compradores de café de especialidad** del mundo:
perfiles de finca, lotes con fotos, chat con **traducción automática ES ⇄ EN**, negociación de precios,
**subastas con fecha límite**, acuerdos con seguimiento, calificaciones, notificaciones y **precios del café en tiempo real**
(precio interno de la FNC, Bolsa de Nueva York y TRM).

Servidor en producción: <https://cafedirecto-production.up.railway.app> · [Política de privacidad](https://cafedirecto-production.up.railway.app/privacy)

## Descargar la app (Android)

**[⬇️ Descargar CafeDirecto.apk](https://github.com/gustavomutto/CafeDirecto/releases/latest/download/CafeDirecto.apk)**
— siempre la última versión. Ábrelo desde el celular, permite *Instalar apps desconocidas* y luego **Crear cuenta**
(caficultor o comprador). Pasos y novedades de cada versión en [Releases](https://github.com/gustavomutto/CafeDirecto/releases).

## Estructura

| Carpeta | Qué es |
| --- | --- |
| [`mobile_app/`](mobile_app) | App Flutter (Android y web), arquitectura por capas con Provider y DTOs |
| [`server/`](server) | API Node.js + Express + PostgreSQL, desplegada en Railway |
| [`docs/`](docs) | Arquitectura, API, auditoría, publicación en Google Play, diccionario de datos y documentos del proyecto |
| [`demos/`](demos) | Prototipos anteriores sin servidor (React y Flutter) |
| `.github/` | GitHub Actions (CI) y plantilla de pull request |

## Empezar

**App** (Android Studio con Flutter):

```bash
cd mobile_app
flutter pub get
flutter run                      # usa el servidor de Railway
```

**Servidor en local** (Node 20+ y PostgreSQL; con Docker es lo más fácil):

```bash
docker run -d --name cafedirecto-db -e POSTGRES_USER=cafe -e POSTGRES_PASSWORD=cafe_local -e POSTGRES_DB=cafedirecto -p 127.0.0.1:5432:5432 postgres:16-alpine
cd server
npm install
start-local.cmd                  # Windows (o: DATABASE_URL=postgres://cafe:cafe_local@localhost:5432/cafedirecto npm start)
npm test                         # 135 pruebas de la API
```

Para apuntar la app al servidor local: `flutter run --dart-define=API_URL=http://10.0.2.2:3000` (emulador)
o la IP de tu computador en la red wifi (celular).

## Funciones

| Caficultor | Comprador |
| --- | --- |
| Perfil de finca bilingüe con fotos y certificaciones | Explorar lotes con filtros (región, proceso, variedad, SCA, altitud, en subasta) |
| Publicar lotes (precio por libra o por carga, con la TRM del día) | Chat traducido con dictado por voz y fotos |
| Ver qué compradores se interesaron en cada lote y escribirles | Pujar en subastas y ver si va ganando |
| Abrir subastas y elegir la oferta ganadora | Cotizar, contraofertar y confirmar acuerdos |
| Marcar el despacho; calificar | Confirmar la entrega; reporte de calidad; calificar |
| Precio interno FNC, bolsa y calculadora "¿cuánto vale mi café?" | Precio de referencia en US$/lb y dólar por país |

## Documentación

- [Arquitectura](docs/ARQUITECTURA.md) — capas de la app y del servidor, flujos y seguridad
- [API](docs/API.md) — todas las rutas, cuerpos, respuestas y variables de entorno
- [Auditoría técnica](docs/AUDITORIA.md) — hallazgos, correcciones y pendientes
- [Publicar en Google Play](docs/PUBLICAR_EN_PLAY.md) — firma, paquete y datos de privacidad
- [Cómo contribuir](CONTRIBUTING.md) — ramas, pruebas y reglas del código
- [Diccionario de datos](docs/CafeDirecto_Diccionario_de_Datos.docx)

## Variables del servidor (Railway)

`DATABASE_URL` y `JWT_SECRET` son obligatorias. Para recuperar contraseñas: `RESEND_API_KEY` y `MAIL_FROM`.
Opcionales: `DEEPL_API_KEY` o `GOOGLE_TRANSLATE_API_KEY`, `MYMEMORY_EMAIL`, `MEDIA_SECRET`, `CORS_ORIGINS`, `CONTACT_EMAIL`.
Detalle en [docs/API.md](docs/API.md#variables-de-entorno).

## Equipo

Gustavo Mutto ([@gustavomutto](https://github.com/gustavomutto)) · Robert ([@ROBERTOCGF](https://github.com/ROBERTOCGF)) · Marlon Martínez ([@MWNEW-928](https://github.com/MWNEW-928)) — Unicesar.
