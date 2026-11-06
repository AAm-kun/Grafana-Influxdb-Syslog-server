#!/bin/sh
set -eu

TOKEN_FILE="${INFLUXDB_TOKEN_FILE:-/var/lib/influxdb3/admin-token.json}"

until [ -s "$TOKEN_FILE" ]; do
  sleep 1
done

INFLUX_TOKEN="$(sed -n 's/.*"token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$TOKEN_FILE")"
if [ -z "$INFLUX_TOKEN" ]; then
  echo "error: unable to read an InfluxDB token from $TOKEN_FILE" >&2
  exit 1
fi
export INFLUX_TOKEN

exec telegraf --config /etc/telegraf/telegraf.conf
