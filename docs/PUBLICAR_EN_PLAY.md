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
`build.gradle.kts` firma con esa clave; si no, con la de depuración (para pruebas).

## 3. Generar el paquete

```powershell
cd mobile_app
flutter build appbundle --release
```

Queda en `build\app\outputs\bundle\release\app-release.aab`. Ese archivo se sube a Google Play Console.

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
