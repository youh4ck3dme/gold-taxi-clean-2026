#!/usr/bin/env bash
set -euo pipefail

SITE_URL="${1:-https://goldtaxi-202ff.web.app/}"
MAPS_KEY="${GOOGLE_MAPS_API_KEY:-}"

if [[ -z "${MAPS_KEY}" ]]; then
  echo "SKIP: GOOGLE_MAPS_API_KEY is not set."
  exit 0
fi

MAPS_RESPONSE="$(curl -fsS -H "Referer: ${SITE_URL}" "https://maps.googleapis.com/maps/api/js?key=${MAPS_KEY}&loading=async")"
if grep -E 'RefererNotAllowed|Google Maps JavaScript API error|InvalidKey|ApiNotActivated|MissingKeyMapError|This API project is not authorized' <<<"${MAPS_RESPONSE}" >/dev/null; then
  echo "FAIL: Google Maps API key rejected ${SITE_URL}."
  exit 1
fi

curl -fsSI -L "${SITE_URL}" >/dev/null
echo "PASS: ${SITE_URL} can load Google Maps JS with the configured referrer."
