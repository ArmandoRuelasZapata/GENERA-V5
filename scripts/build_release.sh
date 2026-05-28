#!/usr/bin/env bash
# =============================================================================
# BUILD DE RELEASE CON SEGURIDAD COMPLETA — The Original Lab
# =============================================================================
# Uso:
#   chmod +x scripts/build_release.sh
#   ./scripts/build_release.sh
#
# Flags de seguridad aplicados:
#   --obfuscate              → Ofusca el snapshot de Dart VM (nombres de clases,
#                              funciones y strings internos ilegibles en el APK).
#   --split-debug-info       → Separa los símbolos de debug en un archivo local.
#                              NUNCA subas build/debug-info/ al repositorio.
#
# ANTES DE EJECUTAR:
#   1. Rota CONTENT_API_KEY, PAYLOAD_ENCRYPTION_KEY y cualquier otra key expuesta.
#   2. Actualiza .env.prod con las nuevas claves y URLs de EasyPanel.
#   3. ¡Importante! Ejecuta: dart run build_runner build -d
#   4. Verifica que key.properties apunta al keystore de producción.
# =============================================================================

set -euo pipefail

ENV_FILE=".env.prod"
DEBUG_INFO_DIR="build/debug-info"

# ──────────────────────────────────────────────────────────────────────────────
# Validaciones previas
# ──────────────────────────────────────────────────────────────────────────────
if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: No se encontró '$ENV_FILE'."
  echo "   Crea el archivo con las claves de producción usando envied antes de continuar."
  exit 1
fi

if [ ! -f "android/key.properties" ]; then
  echo "ERROR: No se encontró 'android/key.properties'."
  echo "   Configura el keystore de producción antes de construir el release."
  exit 1
fi

mkdir -p "$DEBUG_INFO_DIR"

echo ""
echo "Construyendo APK de release con obfuscación (envied) y certificate pinning..."
echo "   Env:  $ENV_FILE"
echo "   Syms: $DEBUG_INFO_DIR"
echo ""

flutter build apk \
  --release \
  --obfuscate \
  --split-debug-info="$DEBUG_INFO_DIR"

echo ""
echo "APK generado en: build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "────────────────────────────────────────────────────────────────────────"
echo "VERIFICACIÓN POST-BUILD (corre manualmente):"
echo ""
echo "1. Extraer APK y buscar secretos expuestos en la librería compilada:"
echo "   unzip -o build/app/outputs/flutter-apk/app-release.apk \\"
echo "     'lib/arm64-v8a/libapp.so' -d /tmp/apk_check"
echo "   strings /tmp/apk_check/lib/arm64-v8a/libapp.so | grep -i 'dev_key'"
echo "   # Resultado esperado: sin output (keys ofuscadas estáticamente por envied)"
echo ""
echo "2. Confirmar que Certificate Pinning bloquea proxies MITM como Burp Suite."
echo "────────────────────────────────────────────────────────────────────────"
