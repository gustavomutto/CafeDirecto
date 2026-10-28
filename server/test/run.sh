#!/usr/bin/env bash
# Pruebas de la API contra una base PostgreSQL real.
# Uso:  DATABASE_URL=postgres://... bash test/run.sh
# Cada archivo corre con el servidor recién iniciado (los límites de intentos viven en memoria).
set -u
cd "$(dirname "$0")/.."
PORT=${PORT:-3999}
export API_URL="http://localhost:$PORT"
LOG=$(mktemp)
status=0
for t in test/*.test.mjs; do
  PORT=$PORT node src/index.js > "$LOG" 2>&1 &
  pid=$!
  for _ in $(seq 1 30); do curl -sf "$API_URL/health" > /dev/null && break; sleep 0.5; done
  echo "── $t"
  node "$t" "$LOG" || status=1
  kill $pid; wait $pid 2>/dev/null
done
rm -f "$LOG"
exit $status
