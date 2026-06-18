#!/bin/sh

# Exit immediately if a command exits with a non-zero status
set -e

echo "=== Starting Flutter Web Build on Vercel ==="

# Ensure empty assets directories exist
mkdir -p assets assets/images assets/icons

# 0. Generate .env file from Vercel environment variables
echo "Generating .env file from environment variables..."
echo "WP_BASE_URL: ${WP_BASE_URL:-[NOT SET]}"
echo "WOO_CONSUMER_KEY: ${WOO_CONSUMER_KEY:-[NOT SET]}"

cat << ENV_EOF > .env
WP_BASE_URL=${WP_BASE_URL}
FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID}
FIREBASE_API_KEY=${FIREBASE_API_KEY}
FIREBASE_APP_ID=${FIREBASE_APP_ID}
SUPABASE_URL=${SUPABASE_URL}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
WOO_CONSUMER_KEY=${WOO_CONSUMER_KEY}
WOO_CONSUMER_SECRET=${WOO_CONSUMER_SECRET}
GOOGLE_MAPS_API_KEY=${GOOGLE_MAPS_API_KEY}
ENV_EOF
echo ".env file generated successfully!"

# 1. Clone Flutter SDK (stable channel, shallow clone to save space & time)
echo "Cleaning old Flutter SDK if any..."
rm -rf flutter
echo "Cloning Flutter SDK (stable channel)..."
git clone https://github.com/flutter/flutter.git --depth 1 -b stable

# 2. Add Flutter to PATH for this execution session (Prepend to ensure local copy is used)
export PATH="$(pwd)/flutter/bin:$PATH"

# 3. Verify installation, disable analytics, and print version
echo "Disabling analytics and verifying Flutter version..."
flutter config --no-analytics
flutter --version

# 4. Configure build settings
flutter config --enable-web

# MOCK mode is disabled in production - using Supabase
echo "✓ Supabase mode enabled"

# 5. Get pub dependencies
echo "Getting pub packages..."
flutter pub get

# 6. Run code generation (build_runner)
echo "Skipping code generation on Vercel to save RAM (ensure generated files are pushed to Git)..."
# flutter pub run build_runner build --delete-conflicting-outputs

# 7. Compile the Web app in release mode with performance optimizations
echo "Compiling Flutter Web application with Production Credentials..."
flutter build web --release \
  --no-tree-shake-icons \
  --dart-obfuscation \
  -t lib/main_prod.dart \
  --dart-define=BACKEND_MODE=supabase \
  --dart-define=SUPABASE_URL=${SUPABASE_URL} \
  --dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY} \
  --dart-define=GOOGLE_MAPS_API_KEY=${GOOGLE_MAPS_API_KEY} \
  --dart-define=DART_VM_PRODUCT=true

# 8. Optimize generated web files
echo "Optimizing web assets..."
if command -v gzip >/dev/null 2>&1; then
  find build/web -type f \( -name "*.js" -o -name "*.css" -o -name "*.json" \) ! -name "*.gz" -exec gzip -9 {} + -exec mv {}.gz {} \; 2>/dev/null || true
  echo "✓ Gzip compression applied"
fi

echo "=== Vercel Build Script Completed Successfully ==="
