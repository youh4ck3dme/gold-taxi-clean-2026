#!/usr/bin/env bash

# Gold-Taxi: Vercel Environment Variables Pruning Script
# ======================================================
# This script uses the Vercel CLI to remove unnecessary environment variables
# that are not used by the Flutter Web client (like direct PostgreSQL credentials).
#
# REQUIREMENTS:
#   - Node.js installed
#   - Authenticated with Vercel CLI: npx vercel login
#   - Project linked locally to Vercel: npx vercel link
#
# USAGE:
#   chmod +x scripts/prune_vercel_envs.sh
#   ./scripts/prune_vercel_envs.sh

set -euo pipefail

# List of variables to remove
UNNECESSARY_VARS=(
  "POSTGRES_URL"
  "POSTGRES_PRISMA_URL"
  "POSTGRES_URL_NON_POOLING"
  "POSTGRES_USER"
  "POSTGRES_HOST"
  "POSTGRES_PASSWORD"
  "POSTGRES_DATABASE"
  "SUPABASE_SERVICE_ROLE_KEY"
  "SUPABASE_JWT_SECRET"
  "SUPABASE_PUBLISHABLE_KEY"
)

echo "======================================================"
# Verify Vercel CLI is authenticated / linked
if ! npx vercel whoami >/dev/null 2>&1; then
  echo "ERROR: Vercel CLI is not authenticated or not installed."
  echo "Please run: npx vercel login"
  exit 1
fi

echo "Pruning unnecessary environment variables from Vercel..."
echo "This will remove them from all environments (production, preview, development)."
echo "======================================================"
echo ""

for var in "${UNNECESSARY_VARS[@]}"; do
  echo "Removing $var..."
  
  # Remove from all environments (production, preview, development)
  # We run this for each env since Vercel CLI requires env name or defaults to interactive
  for env in production preview development; do
    echo "  - from $env..."
    # We ignore errors in case the variable doesn't exist in that environment
    npx vercel env rm "$var" "$env" -y >/dev/null 2>&1 || true
  done
done

echo ""
echo "======================================================"
echo "Pruning complete!"
echo "You can check your remaining variables in Vercel Dashboard:"
echo "https://vercel.com/dashboard"
echo "======================================================"
