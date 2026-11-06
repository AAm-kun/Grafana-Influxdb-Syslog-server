#!/bin/sh
set -eu

DATA_DIR=/var/lib/influxdb3/data
TOKEN_FILE=/var/lib/influxdb3/admin-token.json
HOST=http://127.0.0.1:8181
DATABASE="${INFLUXDB_DATABASE:-syslog}"
RETENTION="${INFLUXDB_RETENTION:-}"

mkdir -p "$DATA_DIR"

if [ ! -s "$TOKEN_FILE" ]; then
  if [ -n "${INFLUXDB_ADMIN_TOKEN:-}" ]; then
    TOKEN="$INFLUXDB_ADMIN_TOKEN"
  else
    TOKEN="apiv3_$(head -c 48 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | cut -c1-64)"
  fi
  printf '{"name":"_admin","token":"%s"}\n' "$TOKEN" > "$TOKEN_FILE"
fi
chmod 0644 "$TOKEN_FILE"

TOKEN="$(sed -n 's/.*"token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$TOKEN_FILE")"
if [ -z "$TOKEN" ]; then
  echo "error: unable to read an admin token from $TOKEN_FILE" >&2
  exit 1
fi

influxdb3 serve \
  --node-id="${INFLUXDB_NODE_ID:-node0}" \
  --object-store=file \
  --data-dir="$DATA_DIR" \
  --http-bind=0.0.0.0:8181 \
  --admin-token-file="$TOKEN_FILE" &
serve_pid=$!

trap 'kill -TERM "$serve_pid" 2>/dev/null || true' INT TERM

until influxdb3 show databases --host "$HOST" --token "$TOKEN" >/dev/null 2>&1; do
  if ! kill -0 "$serve_pid" 2>/dev/null; then
    echo "error: influxdb3 exited before becoming ready" >&2
    wait "$serve_pid" || exit $?
  fi
  sleep 1
done

if influxdb3 show databases --host "$HOST" --token "$TOKEN" | grep -qw "$DATABASE"; then
  echo "database '$DATABASE' already exists"
elif [ -n "$RETENTION" ]; then
  influxdb3 create database "$DATABASE" --host "$HOST" --token "$TOKEN" --retention-period "$RETENTION"
else
  influxdb3 create database "$DATABASE" --host "$HOST" --token "$TOKEN"
fi

echo "admin token: $TOKEN"

wait "$serve_pid"
