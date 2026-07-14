#!/usr/bin/env bash
# Genera Sources/Generated/AppConfig.generated.swift a partir del .env.
# Uso: scripts/gen-config.sh [.env] [salida.swift]
set -euo pipefail

ENV_FILE="${1:-.env}"
OUT="${2:-Sources/Generated/AppConfig.generated.swift}"

if [ ! -f "$ENV_FILE" ]; then
  echo "✗ No existe $ENV_FILE. Copia .env.example → .env y pon tus valores." >&2
  exit 1
fi

# Lee el valor de una key del .env (última ocurrencia, sin comentarios inline ni espacios).
val() {
  grep -E "^[[:space:]]*$1=" "$ENV_FILE" | tail -1 \
    | cut -d= -f2- \
    | sed -e 's/[[:space:]]*#.*$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

# Escapa comillas y backslashes para un string literal de Swift.
esc() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

API_KEY="$(val TRADELOG_API_KEY)"
TENANT_ID="$(val TRADELOG_TENANT_ID)"
ENVIRONMENT="$(val TRADELOG_ENVIRONMENT)"; ENVIRONMENT="${ENVIRONMENT:-staging}"
ENABLE_LOGS="$(val TRADELOG_ENABLE_LOGS)"
CUSTOMER_NAME="$(val TRADELOG_CUSTOMER_NAME)"
CUSTOMER_DATA="$(val TRADELOG_CUSTOMER_DATA)"

# enableLogs como Bool de Swift.
if [ "$(printf '%s' "$ENABLE_LOGS" | tr '[:upper:]' '[:lower:]')" = "false" ]; then
  ENABLE_LOGS_SWIFT="false"
else
  ENABLE_LOGS_SWIFT="true"
fi

mkdir -p "$(dirname "$OUT")"
cat > "$OUT" <<EOF
// GENERADO desde $ENV_FILE por scripts/gen-config.sh — NO editar a mano.
// Se regenera con \`make env\` (o automáticamente en \`make spm\` / \`make pods\`).
enum AppConfig {
    static let apiKey = "$(esc "$API_KEY")"
    static let tenantId = "$(esc "$TENANT_ID")"
    static let environment = "$(esc "$ENVIRONMENT")"
    static let enableLogs = $ENABLE_LOGS_SWIFT
    static let customerName = "$(esc "$CUSTOMER_NAME")"
    static let customerData = "$(esc "$CUSTOMER_DATA")"
}
EOF

echo "✅ Generado $OUT"
