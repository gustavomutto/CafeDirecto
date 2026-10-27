# CafeDirecto
Aplicativo para celular estilo markeplace , para la venta de cafe en granos


| Carpeta | Qué es |
| --- | --- |
| `server/` | API en Node.js + Express + PostgreSQL (se despliega en Railway) |
| `mobile_app/` | App en Flutter para Android y web |

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
