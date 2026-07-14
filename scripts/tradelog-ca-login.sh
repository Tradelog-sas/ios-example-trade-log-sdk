#!/usr/bin/env bash
# Cliente Tradelog: canjea la API KEY por un token de CodeArtifact (vía el broker)
# y configura SwiftPM para instalar el SDK. NO requiere credenciales AWS — solo
# la api key + tenant id del cliente (las mismas del runtime, en .env).
#
# Uso: scripts/tradelog-ca-login.sh [.env]
set -euo pipefail

ENV_FILE="${1:-.env}"
BROKER_URL="${TRADELOG_BROKER_URL:-https://a93sb53vya.execute-api.us-east-1.amazonaws.com/prod/sdk/token}"

val() { grep -E "^$1=" "$ENV_FILE" 2>/dev/null | head -1 | cut -d= -f2- | sed -E 's/^["'\'' ]+|["'\'' ]+$//g' | sed 's/[[:space:]]*#.*$//'; }

API_KEY="$(val TRADELOG_API_KEY)"
TENANT="$(val TRADELOG_TENANT_ID)"
if [ -z "$API_KEY" ] || [ -z "$TENANT" ]; then
  echo "❌ Falta TRADELOG_API_KEY o TRADELOG_TENANT_ID en $ENV_FILE" >&2
  exit 1
fi

echo "→ Canjeando api key por token de CodeArtifact (broker)..."
resp="$(curl -s -u "$TENANT:$API_KEY" "$BROKER_URL")"

read -r TOKEN ENDPOINT < <(printf '%s' "$resp" | /usr/bin/python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
except Exception:
    print("", ""); sys.exit(0)
data = d.get("data", d)
print(data.get("authorizationToken",""), data.get("registryEndpoint",""))
')

if [ -z "$TOKEN" ] || [ -z "$ENDPOINT" ]; then
  echo "❌ El broker no devolvió token. Respuesta:" >&2
  printf '%s\n' "$resp" | sed -E 's/("authorizationToken" *: *")[^"]*/\1****/' >&2
  exit 1
fi

HOST="$(printf '%s' "$ENDPOINT" | sed -E 's#https?://([^/]+)/.*#\1#')"

# 1) Registry por defecto (global) para SwiftPM/Xcode.
swift package-registry set --global "$ENDPOINT" >/dev/null 2>&1 || swift package-registry set "$ENDPOINT" >/dev/null 2>&1 || true

# 2) Token del registry en ~/.netrc (Basic auth: usuario 'aws', password = token).
NETRC="$HOME/.netrc"
touch "$NETRC"; chmod 600 "$NETRC"
grep -v "machine $HOST " "$NETRC" > "$NETRC.tmp" 2>/dev/null || true
mv "$NETRC.tmp" "$NETRC" 2>/dev/null || true
printf 'machine %s login aws password %s\n' "$HOST" "$TOKEN" >> "$NETRC"

echo "✅ SwiftPM configurado para CodeArtifact (registry: $HOST). Token válido ~12h."
