#!/bin/sh
# Vocero CRM on Railway: run migrations, create the owner account on a private
# loopback port (public sign-up closes once the first organization exists),
# then hand over to the upstream entrypoint on the public port.
set -eu
PUBLIC_PORT="${PORT:-8080}"
BOOT_PORT="${VOCERO_BOOTSTRAP_PORT:-3999}"
: "${MEDIA_DIR:=/data/media}"
export MEDIA_DIR
MARKER=/data/.railway-owner-created
cd /app

mkdir -p "$MEDIA_DIR"
find /data ! -user vocero -exec chown -h vocero:vocero {} + 2>/dev/null || true

echo "[railway] running database migrations"
su-exec vocero node migrate.mjs

if [ ! -f "$MARKER" ] && [ -n "${VOCERO_ADMIN_PASSWORD:-}" ]; then
  echo "[railway] creating owner account on 127.0.0.1:${BOOT_PORT}"
  PORT="$BOOT_PORT" HOSTNAME=127.0.0.1 su-exec vocero node server.js &
  pid=$!
  i=0
  until wget -q -O /dev/null "http://127.0.0.1:${BOOT_PORT}/api/health" 2>/dev/null; do
    i=$((i + 1)); [ "$i" -gt 120 ] && break; sleep 1
  done
  if BOOT_PORT="$BOOT_PORT" node -e '
    const p = process.env.BOOT_PORT;
    fetch(`http://127.0.0.1:${p}/api/auth/sign-up/email`, {
      method: "POST",
      headers: { "content-type": "application/json", origin: process.env.APP_BASE_URL },
      body: JSON.stringify({
        name: process.env.VOCERO_ADMIN_NAME || "Admin",
        email: process.env.VOCERO_ADMIN_EMAIL || "admin@example.com",
        password: process.env.VOCERO_ADMIN_PASSWORD,
      }),
    }).then(async (r) => {
      const t = (await r.text()).slice(0, 200);
      console.log(`[railway] owner sign-up returned HTTP ${r.status}${r.ok ? "" : ": " + t}`);
      process.exit(r.ok || r.status === 403 ? 0 : 1);
    }).catch((e) => { console.error("[railway] owner sign-up failed:", e.message); process.exit(1); });
  '; then
    touch "$MARKER"
  else
    echo "[railway] WARNING: owner account was not created; first visitor could register" >&2
  fi
  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
fi

export PORT="$PUBLIC_PORT" HOSTNAME=0.0.0.0
exec /usr/local/bin/vocero-entrypoint.sh sh -c "node migrate.mjs && node server.js"
