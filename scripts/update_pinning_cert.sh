#!/usr/bin/env bash
set -euo pipefail

HOST="${1:-}"
OUT_PEM="${2:-server.pem}"
DART_FILE="lib/core/network/interceptors/certificate_pinning_interceptor.dart"

if [[ -z "$HOST" ]]; then
  echo "Usage: $(basename "$0") <host> [output_pem_path]"
  echo "Example: $(basename "$0") theoriginallab-api-apptolv2-dev.m0oqwu.easypanel.host"
  exit 1
fi

openssl s_client -connect "$HOST:443" -servername "$HOST" -showcerts </dev/null 2>/dev/null \
  | awk 'BEGIN{c=0}/BEGIN CERT/{c++} c==1{print} /END CERT/{if(c==1) exit}' \
  > "$OUT_PEM"

python3 - "$OUT_PEM" "$DART_FILE" <<'PY'
import re
import sys

pem_path, dart_path = sys.argv[1:3]
pem = open(pem_path, "r", encoding="utf-8").read().strip()
if "BEGIN CERTIFICATE" not in pem or "END CERTIFICATE" not in pem:
  raise SystemExit("Invalid PEM content.")

text = open(dart_path, "r", encoding="utf-8").read()
pattern = r"'''-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----'''"

def repl(_):
  return "'''" + pem + "'''"

new_text, n = re.subn(pattern, repl, text, count=1, flags=re.S)
if n != 1:
  raise SystemExit("Failed to replace cert block in Dart file.")

open(dart_path, "w", encoding="utf-8").write(new_text)
print(f"Updated {dart_path} with cert from {pem_path}")
PY

echo "Saved PEM to $OUT_PEM"
