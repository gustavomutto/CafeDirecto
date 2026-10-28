@echo off
REM Arranca la API de CafeDirecto en local (puerto 3000).
REM Requiere el contenedor de PostgreSQL:  docker start cafedirecto-db
set DATABASE_URL=postgres://cafe:cafe_local@localhost:5432/cafedirecto
set JWT_SECRET=clave-local-solo-para-desarrollo-cafedirecto
set PORT=3000
cd /d "%~dp0"
node src/index.js
