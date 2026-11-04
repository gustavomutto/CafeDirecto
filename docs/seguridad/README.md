# Seguridad móvil · OWASP Mobile Top 10

Tarea de Programación Móvil: auditoría de CaféDirecto, corrección de hallazgos y verificación antes y después.

| Archivo | Qué es |
| --- | --- |
| `Informe_Seguridad_CafeDirecto.pdf` | Informe completo: modelo de amenazas, Top 10, hallazgos, correcciones, verificación y guion de la demostración |
| `informe.html` | Fuente del informe (se exporta a PDF con el navegador) |
| `evidencia/` | Salidas de las pruebas antes (`*-antes.txt`) y después (`*-despues.txt`) |
| `herramientas/secret-scan.py` | Busca secretos en todo el historial de Git |
| `herramientas/security-check.mjs` | Repite los ataques H-01 y H-02 contra la API local y dice si siguen abiertos |

Cada corrección está en un commit cuyo mensaje empieza con su ID (`H-01` … `H-07`).

## Repetir las verificaciones

```bash
# Secretos en el historial (desde la raíz del repositorio)
python docs/seguridad/herramientas/secret-scan.py . secretos.txt

# Ataques a la API: con PostgreSQL local y la API corriendo en el puerto 3999
cd server
DATABASE_URL=postgres://... NODE_ENV=test PORT=3999 node src/index.js &
node ../docs/seguridad/herramientas/security-check.mjs . http://localhost:3999

# Pruebas completas
npm test                                  # API (incluye test/v5.test.mjs)
cd ../mobile_app && flutter test          # app (incluye test/security_test.dart)

# APK de lanzamiento
flutter build apk --release --obfuscate --split-debug-info=build/symbols
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
aapt2 dump xmltree --file AndroidManifest.xml build/app/outputs/flutter-apk/app-release.apk | grep networkSecurityConfig
```

`security-check.mjs` crea cuentas de prueba con correos `@example.test`. Úsalo solo contra la API local, nunca contra producción.
