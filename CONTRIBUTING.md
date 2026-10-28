# Cómo trabajar en CaféDirecto

Guía corta para el equipo (Gustavo, Robert, Marlon) y para quien se sume.

## Ramas

| Rama | Para qué |
| --- | --- |
| `main` | Versión estable para entregar. Solo entra por *pull request* revisado. |
| `gustavo` | Integración: aquí se juntan los cambios. **Railway despliega el servidor desde esta rama.** |
| `Robert`, `marlon-martinez` | Trabajo de cada integrante. |

Flujo recomendado:

1. Antes de empezar, trae lo último: `git pull origin gustavo`.
2. Trabaja en tu rama y haz commits pequeños con mensajes claros, en español, que digan **qué** y **por qué**
   (por ejemplo: `Acuerdos: el comprador confirma la entrega`).
3. Sube tu rama y abre un *pull request* hacia `gustavo`. GitHub Actions revisa todo solo (ver abajo).
4. Cuando esté verde y alguien lo revisó, se fusiona. Para una entrega, se abre un *pull request* de `gustavo` a `main`.

> No subas archivos sueltos con "Add files via upload" encima de carpetas del proyecto: se pierde el historial
> y es fácil pisar el trabajo de otro. Los documentos van en `docs/`.

## Antes de subir

```bash
# Servidor
cd server
npm install
npm run lint            # estilo y errores comunes
npm test                # 135 pruebas de la API (necesita PostgreSQL; ver README)

# App
cd mobile_app
flutter pub get
flutter analyze         # debe decir "No issues found!"
flutter test
```

## Qué revisa GitHub Actions en cada cambio

- **Servidor:** ESLint, `npm audit` (vulnerabilidades altas bloquean) y las pruebas de la API contra PostgreSQL real.
- **App:** `flutter analyze` estricto (también las sugerencias), `flutter test` y que el APK compile.
  El APK de cada cambio queda en *Actions → (la ejecución) → Artifacts* durante 14 días (requiere cuenta de GitHub).
- **Dependabot** propone cada semana las actualizaciones de dependencias.

## Publicar una versión nueva de la app

Para que el equipo y los usuarios de prueba descarguen el APK con el enlace fijo del README:

1. Sube el número en `mobile_app/pubspec.yaml` (por ejemplo `version: 3.1.1+6`), haz commit y súbelo a `gustavo`.
2. En GitHub: **Releases → Draft a new release**.
   - *Choose a tag*: escribe `v3.1.1` y elige **Create new tag on publish**; *Target*: `gustavo`.
   - Título `CaféDirecto v3.1.1` y, si quieres, las novedades (si lo dejas vacío se ponen las instrucciones de instalación).
   - **Publish release**.
3. GitHub Actions compila, prueba y adjunta `CafeDirecto.apk` al Release (unos 10 minutos).
   El enlace `releases/latest/download/CafeDirecto.apk` del README pasa a dar esa versión.

> Mientras no exista la clave de firma de Google Play (`docs/PUBLICAR_EN_PLAY.md`), cada APK se firma con una
> clave temporal distinta: para actualizar, hay que desinstalar la versión anterior. Los datos no se pierden (están en el servidor).

## Reglas del código

**App (Flutter)** — arquitectura por capas (ver `docs/ARQUITECTURA.md`):

- Las pantallas **no** llaman HTTP: usan un repositorio (`context.repo<LotRepository>()`) o un provider.
- El JSON del servidor se convierte en entidades con un **DTO** en `lib/data/dtos/`.
- Todo texto visible va en los dos idiomas: `app.tr('Español', 'English')`.
- Usa `AppLogger` en lugar de `print`.
- Lógica nueva con estado → un `ChangeNotifier` en `presentation/providers/` con su prueba en `test/`.

**Servidor (Node.js)**:

- Rutas en `src/routes/`, reglas de negocio en `src/services/`, JSON de salida en `src/serialize.js`.
- Todo dato que llega se valida (`inRange`, `str`, `optId`…) y toda foto que se usa debe ser de quien la usa (`assertOwnImages`).
- Consultas siempre con parámetros (`$1, $2…`), nunca concatenando texto.
- Cambios de la base: agregar al final de `src/schema.sql` de forma idempotente (`IF NOT EXISTS`) y actualizar el diccionario de datos.

## Secretos

Nunca se suben: `JWT_SECRET`, `MEDIA_SECRET`, claves de DeepL/Google/Resend, `android/key.properties`, archivos `.jks`.
Las variables del servidor se configuran en Railway (*Variables*).
