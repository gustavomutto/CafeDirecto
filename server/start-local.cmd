@echo off
REM Arranca la API de CafeDirecto en local (puerto 3000).
REM Requiere PostgreSQL local (ver README). Las claves NO van en este archivo (hallazgo H-01):
REM la primera vez se crea .env.local con una JWT_SECRET aleatoria. Ese archivo no se sube a GitHub.
cd /d "%~dp0"
if not exist .env.local (
  copy /y .env.example .env.local >nul
  node -e "const fs=require('fs');const k=require('crypto').randomBytes(48).toString('hex');fs.writeFileSync('.env.local',fs.readFileSync('.env.local','utf8').replace('JWT_SECRET=','JWT_SECRET='+k))"
  echo Se creo server\.env.local con una clave aleatoria. Revisa DATABASE_URL si tu base usa otra clave.
)
for /f "usebackq eol=# tokens=1,* delims==" %%a in (".env.local") do set "%%a=%%b"
set NODE_ENV=development
node src/index.js
