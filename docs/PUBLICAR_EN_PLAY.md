# Publicar la app en Google Play

## 1. Crear la clave de firma (una sola vez)

En la terminal de Android Studio (Windows):

```powershell
cd mobile_app\android
keytool -genkey -v -keystore cafedirecto-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias cafedirecto
```

Guarda la contraseña en un lugar seguro. **Si pierdes este archivo o su contraseña no podrás actualizar la app en Google Play.**

## 2. Crear `mobile_app/android/key.properties`

```properties
storePassword=LA_CONTRASEÑA
keyPassword=LA_CONTRASEÑA
keyAlias=cafedirecto
storeFile=../cafedirecto-release.jks
```

`key.properties` y los `.jks` están en `.gitignore`: **no se suben a GitHub**. Si el archivo existe,
`build.gradle.kts` firma con esa clave; si no, con la de depuración (solo para pruebas, y Gradle lo avisa).

### Firma en GitHub Actions (para los APK de Releases)

Al publicar un Release, CI **exige** la clave de lanzamiento: sin ella la compilación falla en lugar de
publicar un APK firmado con la clave de depuración. Agrega estos secretos en GitHub
(*Settings → Secrets and variables → Actions → New repository secret*):

| Secreto | Valor |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | El `.jks` en Base64. En PowerShell: `[Convert]::ToBase64String([IO.File]::ReadAllBytes("cafedirecto-release.jks")) \| Set-Clipboard` |
| `ANDROID_KEYSTORE_PASSWORD` | La contraseña del `.jks` |
| `ANDROID_KEY_ALIAS` | `cafedirecto` |
| `ANDROID_KEY_PASSWORD` | La contraseña de la clave (si no la pones, se usa la del `.jks`) |

## 3. Generar el paquete

```powershell
cd mobile_app
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
```

Queda en `build\app\outputs\bundle\release\app-release.aab`. Ese archivo se sube a Google Play Console.

`--obfuscate` hace ilegibles los nombres del código Dart dentro de la app. Guarda la carpeta `build\symbols`
de cada versión (no se sube a GitHub): sin ella no se pueden leer los errores que reporten los usuarios.

## 4. Datos que pide Google Play

| Pregunta | Respuesta |
| --- | --- |
| Política de privacidad | `https://cafedirecto-production.up.railway.app/privacy` |
| Eliminar la cuenta (URL) | `https://cafedirecto-production.up.railway.app/privacy#eliminar` |
| ¿La app permite eliminar la cuenta? | Sí: Perfil → Eliminar mi cuenta |
| Datos recopilados | Nombre, correo, teléfono (opcional), fotos, mensajes, actividad en la app |
| ¿Se comparten con terceros? | Solo con proveedores del servicio (alojamiento, traducción, correo) |
| ¿Cifrados en tránsito? | Sí (HTTPS) |
| Permisos | Internet, micrófono (dictado por voz), notificaciones |

Antes de publicar, agrega en Railway la variable `CONTACT_EMAIL` con el correo de contacto del equipo
(aparece en la página de privacidad).

## 5. Versión

Sube `version:` en `mobile_app/pubspec.yaml` en cada publicación (por ejemplo `3.1.0+5` → `3.1.1+6`;
el número después de `+` debe crecer siempre).
