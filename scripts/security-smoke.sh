#!/bin/bash
# Security smoke test for GoldTaxi Mock Mode Kill Switch

# Define regex parts to avoid triggering the script search itself
P_MOCK_JWT="mock_""jwt_""token"
P_MOCK_JWT_ABC="mock_""jwt_""token_""abc123xyz789"
P_ENABLE_MOCK="ApiService\.enable""MockMode"
P_DISABLE_MOCK="ApiService\.disable""MockMode"
P_MOCK_ENABLED="_mockMode""Enabled"
P_ENV_ASSET="/assets/\.""env"
P_DRIVER_1="driver_""1"
P_ID_0="id: '""0'"

REGEX="${P_MOCK_JWT}|${P_MOCK_JWT_ABC}|${P_ENABLE_MOCK}|${P_DISABLE_MOCK}|${P_MOCK_ENABLED}|${P_ENV_ASSET}|${P_DRIVER_1}|${P_ID_0}"

echo "Checking for forbidden mock mode patterns..."
echo "Regex: ${REGEX}"

# Check if ripgrep is installed
if ! command -v rg &> /dev/null; then
  echo "ripgrep (rg) is not installed. Falling back to grep."
  # Use grep fallback, excluding this script
  MATCHES=$(grep -rnH --exclude="security-smoke.sh" -E "${REGEX}" lib test pubspec.yaml .github scripts 2>/dev/null)
else
  # Run ripgrep, excluding this script
  MATCHES=$(rg -n --glob '!scripts/security-smoke.sh' "${REGEX}" lib test pubspec.yaml .github scripts 2>/dev/null)
fi

if [ -n "${MATCHES}" ]; then
  echo "❌ CRITICAL SECURITY RISK: Forbidden mock mode references found in codebase:"
  echo "${MATCHES}"
  exit 1
else
  echo "✅ Security check passed. No forbidden mock mode references found."
  exit 0
fi
