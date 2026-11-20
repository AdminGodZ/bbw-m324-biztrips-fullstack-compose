#!/usr/bin/env bash
# End-to-end check of the running Compose system: frontend, API through nginx, DB data, S3 photo round trip.
set -euo pipefail
FE="${FRONTEND_URL:-http://localhost:${FRONTEND_PORT:-3000}}"
ok() { printf '  \033[32m✔\033[0m %s\n' "$1"; }
die() { printf '  \033[31m✘\033[0m %s\n' "$1"; exit 1; }

echo "Smoke test against $FE"
curl -fsS "$FE/health" >/dev/null && ok "frontend /health" || die "frontend not healthy"
curl -fsS "$FE/" | grep -q '<div id="root">' && ok "frontend serves the React app" || die "index.html missing"
readiness=$(curl -fsS "$FE/actuator/health/readiness") || die "backend readiness not reachable via nginx"
echo "$readiness" | grep -q '"status":"UP"' && ok "backend ready (db + s3): $readiness" || die "backend not ready: $readiness"
trips=$(curl -fsS "$FE/v1/trips") || die "/v1/trips failed"
[ "$(echo "$trips" | grep -o '"id"' | wc -l)" -ge 1 ] && ok "trips loaded from MariaDB" || die "no trips"

employees=$(curl -fsS "$FE/v1/employees") || die "/v1/employees failed"
echo "$employees" | grep -q '"name"' && ok "employees loaded" || die "no employees"

png=$(mktemp); trap 'rm -f "$png" "$png.out"' EXIT
printf '\x89PNG\r\n\x1a\n%s' "$(head -c 64 /dev/urandom | base64)" > "$png"
code=$(curl -s -o /dev/null -w '%{http_code}' -F "file=@$png;type=image/png" "$FE/v1/employees/1/photo")
[ "$code" = 200 ] && ok "photo upload -> S3 (HTTP $code)" || die "photo upload failed (HTTP $code)"
curl -fsS "$FE/v1/employees/1/photo" -o "$png.out" || die "photo download failed"
cmp -s "$png" "$png.out" && ok "photo download is byte-identical" || die "downloaded photo differs"
echo "All checks passed."
