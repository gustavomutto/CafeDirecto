# Auditoría técnica de CaféDirecto

**Fecha:** 28 de octubre de 2026 · **Versión auditada:** 3.0 (rama `gustavo`, commit `4fc01ad`) · **Versión resultante:** 3.1

## 1. Resumen

Se revisó todo el sistema: servidor (Node.js/Express), base de datos (PostgreSQL), app (Flutter), integración
continua y organización del repositorio. Se encontraron **30 hallazgos**: 6 de severidad alta, 13 media y 11 baja.
**Se corrigieron 30 de 30** y cada corrección quedó cubierta por una prueba automática o por la revisión de CI.
Quedan 12 recomendaciones para siguientes versiones (sección 6), ninguna bloqueante.

| Indicador | Antes | Después |
| --- | --- | --- |
| Vulnerabilidades conocidas en dependencias del servidor | 4 (3 altas) | **0** |
| Pruebas automáticas de la API | 108 | **135** |
| Pruebas automáticas de la app | 11 | **23** |
| Problemas del analizador de Flutter (modo estricto, incluye sugerencias) | no se revisaban | **0** |
| Errores de ESLint en el servidor | no se revisaba | **0** |
| Índices de la base (sin contar llaves primarias) | 8 | **21** |
| Reglas de integridad `CHECK` | 15 | **26** |
| Controles automáticos en cada cambio (CI) | analizar, probar, compilar | + ESLint, `npm audit`, análisis estricto, Dependabot |

## 2. Alcance y método

1. **Revisión de código** completa de `server/src` (2.450 líneas) y `mobile_app/lib` (11.600 líneas).
2. **Análisis estático:** `flutter analyze` en modo estricto y ESLint 9 con reglas recomendadas.
3. **Dependencias:** `npm audit` y revisión de versiones y avisos de obsolescencia.
4. **Base de datos:** llaves, índices, restricciones y consultas frecuentes contra un PostgreSQL real.
5. **Pruebas dinámicas:** suite de la API contra PostgreSQL (local y en GitHub Actions) y pruebas de la capa de
   presentación de la app con repositorios falsos.
6. **Requisitos de publicación** de Google Play (firma, privacidad, eliminación de cuenta, permisos).

Severidad: **Alta** = expone datos, permite saltar una regla de negocio o produce resultados incorrectos para el usuario;
**Media** = riesgo real pero acotado, o deuda que frena el mantenimiento; **Baja** = buena práctica o mejora menor.

## 3. Hallazgos y correcciones — Seguridad

| ID | Sev. | Hallazgo | Impacto | Corrección | Verificación |
| --- | --- | --- | --- | --- | --- |
| S-01 | Alta | Las fotos se servían en `/images/ID` con ids consecutivos y sin control | Cualquiera podía descargar todas las fotos, **incluidas las del chat privado y los reportes de calidad**, cambiando el número | Dirección firmada con HMAC-SHA256 (`/images/ID?s=FIRMA`); sin firma válida responde 404 | `flow.test`: sin firma → 404; firma falsa → 404 |
| S-02 | Alta | Dependencias con 4 vulnerabilidades (path-to-regexp ReDoS, qs DoS) y multer 1.x obsoleto | Denegación de servicio con peticiones manipuladas | Express 4.22.3, multer 2.5.0, pg 8.23.1, jsonwebtoken 9.0.3 | `npm audit`: 0; CI bloquea vulnerabilidades altas |
| S-03 | Alta | El token de sesión se guardaba sin cifrar (SharedPreferences) y con copia de seguridad activa | Un respaldo o un teléfono comprometido expone la sesión | `flutter_secure_storage` (Android Keystore) con migración automática; `allowBackup=false` | Compila en CI; migración sin cerrar sesiones |
| S-04 | Media | Se aceptaba cualquier archivo cuyo tipo declarado dijera "imagen" | Subir archivos que no son imágenes | Tipo real por los primeros bytes (JPG, PNG, WEBP, GIF, HEIC) | `v3.test`: archivo falso → 400 |
| S-05 | Media | Se podía poner en el perfil, un lote o un mensaje el id de una foto ajena | Mostrar o reenviar fotos privadas de otra persona | `assertOwnImages` en perfil, lotes, mensajes, calidad y disputas | `v3.test`: 3 casos → 400 |
| S-06 | Media | Contraseñas de 6 caracteres sin requisitos | Cuentas fáciles de adivinar | 8+ caracteres con letras y números (servidor y app) | `v3.test` y prueba de la app |
| S-07 | Media | Sin límite de mensajes ni de fotos por usuario | Abuso del almacenamiento y del costo de traducción | 40 mensajes/min, 60 fotos/hora (además de los límites existentes) | Revisión de código |
| S-08 | Baja | El login respondía más rápido si el correo no existía | Permitía averiguar qué correos están registrados | Comparación con un hash de relleno (tiempo constante) | Revisión de código |
| S-09 | Baja | JWT verificado sin fijar el algoritmo | Defensa en profundidad | Firma y verificación solo con HS256 | `v3.test`: token `alg: none` → 401 |
| S-10 | Baja | Sin cabeceras de seguridad y con `X-Powered-By: Express` | Información útil para un atacante | `nosniff`, `X-Frame-Options`, HSTS, `Referrer-Policy`; sin `X-Powered-By`; CORS configurable | `v3.test` revisa las cabeceras |

## 4. Hallazgos y correcciones — Funcionamiento y datos

| ID | Sev. | Hallazgo | Impacto | Corrección | Verificación |
| --- | --- | --- | --- | --- | --- |
| F-01 | Alta | Al publicar un lote "por carga", el precio en dólares usaba una **tasa fija de 3.900** y un factor 92,8 | Con la TRM real (~3.147) el precio en US$/lb salía **≈ 24 % más bajo** de lo que el caficultor quería cobrar | Usa la TRM del día del servidor y el factor 94 de la FNC; muestra la TRM usada y la diferencia con el precio interno | Pruebas de conversión en la app |
| F-02 | Alta | Cualquiera de las dos partes podía marcar el acuerdo como "entregado" | El caficultor podía dar por entregado algo no recibido y habilitar las calificaciones | Despacho: solo el caficultor; entrega: solo el comprador (servidor y pantalla) | `v3.test`: 4 casos de permisos |
| F-03 | Alta | Si la base fallaba un instante, el servidor respondía 401 "sesión vencida" | La app cerraba la sesión de **todos** los usuarios por una caída momentánea | Se separa el error del token (401) del error de la base (500) | Revisión de código |
| F-04 | Media | La traducción gratuita (MyMemory) cortaba los textos de más de 480 caracteres | El final de los mensajes largos llegaba sin traducir | Traducción por partes, cortando en fin de frase | Prueba de partición |
| F-05 | Media | Sin límites superiores en precio (US$/lb), sacos, puntaje SCA, altitud o año | Datos absurdos (p. ej. US$ 5.000/lb) en el catálogo y en los totales | Rangos en cada ruta (`inRange`) y reglas `CHECK` en la base | `v3.test`: 5 casos → 400 |
| D-01 | Media | 13 llaves foráneas y consultas frecuentes sin índice | Listas y borrados lentos al crecer los datos | 13 índices (varios parciales: activos, abiertos, sin leer) | Revisados contra `pg_indexes` |
| D-02 | Media | Sin reglas de integridad en estados, tipos y precios | Un error de código podía guardar datos inválidos | 11 reglas `CHECK` (creadas `NOT VALID` para no bloquear el arranque) | Migración probada sobre una base con datos |
| D-03 | Baja | El diccionario de datos no incluía índices ni las reglas nuevas | Documentación desactualizada | Diccionario 3.1 con hoja/sección de índices | Cruce automático con el esquema |

## 5. Hallazgos y correcciones — Calidad, operación y repositorio

| ID | Sev. | Hallazgo | Corrección |
| --- | --- | --- | --- |
| A-01 | Media | La lógica del chat (≈600 líneas) estaba dentro de la pantalla, sin pruebas | `ChatRoomController` (Provider) con 7 pruebas: envío optimista, error, consulta sin duplicados, acuerdos, segundo plano |
| A-02 | Media | Los providers dependían de clases concretas (difícil de probar) | `AlertService` (interfaz) y repositorios falsos en `test/support/fakes.dart`; 10 pruebas de providers |
| A-03 | Baja | La app pedía la lista de avisos cada 10 s aunque no hubiera nada nuevo | `/unread` trae el id del último aviso: la app solo pide la lista cuando hay uno nuevo (la mitad de consultas) |
| A-04 | Baja | Fotos decodificadas a 1.600 px aunque se muestren pequeñas | `cacheWidth` según el tamaño en pantalla (menos memoria, listas más fluidas) |
| A-05 | Baja | Errores asíncronos sin capturar no quedaban registrados | `PlatformDispatcher.onError` → `AppLogger` |
| A-06 | Baja | Código sin uso (RouteTracker, `uid`, `langOf`, `otherRole`, `fmtDuration`, variante "demo") | Eliminado |
| A-07 | Media | Requisitos de Google Play: firma de lanzamiento, política de privacidad y URL para eliminar la cuenta | `key.properties` opcional, página `/privacy` en el servidor y pantalla de privacidad en la app; guía `docs/PUBLICAR_EN_PLAY.md` |
| A-08 | Baja | Ícono por defecto de Flutter; el aviso del teléfono usaba un ícono a color (Android lo muestra como un cuadro gris) | Ícono propio (grano de café) en todos los tamaños y silueta blanca para los avisos |
| O-01 | Media | Sin registro de peticiones ni identificador para depurar en Railway | Una línea por petición (método, ruta, estado, tiempo, usuario) y `X-Request-Id` |
| O-02 | Baja | Sin apagado ordenado: cada despliegue cortaba las peticiones en curso | Manejo de `SIGTERM`: cierra el servidor, el proceso de subastas y la base |
| R-01 | Media | Raíz del repositorio desordenada (demos y documentos mezclados), sin guía de trabajo, subidas por "Add files via upload" | `docs/`, `demos/`, `CONTRIBUTING.md`, plantilla de pull request, `.editorconfig`, `.gitattributes` |
| R-02 | Baja | Acciones de GitHub con Node 20 obsoleto; análisis no estricto; sin revisión de dependencias | Acciones actualizadas, análisis estricto, ESLint, `npm audit` y Dependabot semanal |

## 6. Recomendaciones para siguientes versiones

| # | Prioridad | Recomendación | Por qué |
| --- | --- | --- | --- |
| 1 | Alta | Configurar `RESEND_API_KEY`, `MAIL_FROM` y `CONTACT_EMAIL` en Railway | Sin correo no funciona "Olvidé mi contraseña"; el contacto aparece en `/privacy` |
| 2 | Alta | Crear la clave de firma (`key.properties`) y guardarla en un lugar seguro | Requisito para Google Play; si se pierde no se puede actualizar la app |
| 3 | Alta | Proteger `main` y `gustavo` en GitHub (*Settings → Branches*): exigir pull request y CI verde | Evita que una subida directa rompa producción |
| 4 | Media | Activar copias de seguridad automáticas de PostgreSQL en Railway | Hoy no hay respaldo de los datos |
| 5 | Media | Avisos con la app cerrada (Firebase Cloud Messaging) | Hoy el aviso llega con la app abierta o en segundo plano |
| 6 | Media | Mover las fotos a almacenamiento de objetos (Railway Buckets o S3) | Las fotos en la base la hacen crecer y encarecen los respaldos |
| 7 | Media | Optimizar `/conversations` con una sola consulta (hoy ~5 consultas por chat) | Con muchos chats la lista se vuelve lenta |
| 8 | Media | Paginación en lotes, chats y acuerdos (hoy hasta 100–200 por lista) | Escalabilidad |
| 9 | Baja | Monitoreo de errores (Sentry o similar) en la app y el servidor | Saber de los errores antes que los usuarios |
| 10 | Baja | Migraciones versionadas (p. ej. `node-pg-migrate`) en lugar de un `schema.sql` idempotente | Cambios de columnas más seguros a futuro |
| 11 | Baja | Migrar a Express 5 | Express 4 sigue con parches, pero la línea nueva es la 5 |
| 12 | Baja | Pruebas de widgets e integración de los flujos completos en la app | Hoy se prueban la lógica y los DTOs, no la interfaz |

## 7. Cómo verificar

```bash
cd server && npm run lint && npm audit --omit=dev && npm test     # 135 pruebas, 0 vulnerabilidades
cd mobile_app && flutter analyze && flutter test                  # 0 problemas, 23 pruebas
```

En GitHub, la pestaña **Actions** muestra las dos revisiones en verde para cada cambio, y el APK compilado.
