#!/usr/bin/env bash

# Gold-Taxi: GitHub Secrets Setup Script
# ========================================
# This script helps you set up GitHub Actions secrets for the Gold-Taxi repository.
#
# REQUIREMENTS:
#   - GitHub CLI installed: https://cli.github.com/
#   - Authenticated with GitHub CLI: gh auth login
#   - Repository admin access: NEXIFY-STUDIO/gold-taxi
#
# USAGE:
#   ./setup_github_secrets.sh

set -euo pipefail

REPO="NEXIFY-STUDIO/gold-taxi"
SECRETS=(
  "WP_BASE_URL"
  "FIREBASE_PROJECT_ID"
  "FIREBASE_API_KEY"
  "FIREBASE_APP_ID"
  "SUPABASE_URL"
  "SUPABASE_ANON_KEY"
  "WOO_CONSUMER_KEY"
  "WOO_CONSUMER_SECRET"
  "GOOGLE_MAPS_API_KEY"
)

echo "============================================"
echo "Gold-Taxi: GitHub Secrets Setup"
echo "============================================"
echo ""

if ! command -v gh > /dev/null 2>&1; then
  echo "ERROR: GitHub CLI is not installed."
  echo "Install it from: https://cli.github.com/"
  exit 1
fi

if ! gh auth status > /dev/null 2>&1; then
  echo "ERROR: GitHub CLI is not authenticated."
  echo "Run: gh auth login"
  exit 1
fi

echo "Setting up secrets for: $REPO"
echo "Leave a value empty to skip that secret."
echo ""

for name in "${SECRETS[@]}"; do
  if [[ "$name" == *_KEY || "$name" == *_SECRET || "$name" == *_TOKEN ]]; then
    read -r -s -p "Enter value for $name: " value
    echo ""
  else
    read -r -p "Enter value for $name: " value
  fi

  if [[ -z "$value" ]]; then
    echo "Skipping $name"
    continue
  fi

  echo -n "Setting $name... "
  if printf '%s' "$value" | gh secret set "$name" --body-file - --repo "$REPO" > /dev/null 2>&1; then
    echo "OK"
  else
    echo "FAILED"
    echo "Make sure you have admin access to $REPO."
    exit 1
  fi
done

echo ""
echo "============================================"
echo "Secrets setup complete."
echo "Verify at: https://github.com/$REPO/settings/secrets/actions"
echo "============================================"
