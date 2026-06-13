#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "=== Starting Flutter Web Build on Vercel ==="

# Ensure empty assets directories exist
mkdir -p assets assets/images assets/icons

# 0. Generate .env file from Vercel environment variables
echo "Generating .env file from environment variables..."
echo "WP_BASE_URL: ${WP_BASE_URL:-[NOT SET]}"
echo "WOO_CONSUMER_KEY: ${WOO_CONSUMER_KEY:-[NOT SET]}"

cat << EOF > .env
WP_BASE_URL=${WP_BASE_URL}
FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID}
FIREBASE_API_KEY=${FIREBASE_API_KEY}
FIREBASE_APP_ID=${FIREBASE_APP_ID}
SUPABASE_URL=${SUPABASE_URL}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
WOO_CONSUMER_KEY=${WOO_CONSUMER_KEY}
WOO_CONSUMER_SECRET=${WOO_CONSUMER_SECRET}
EOF
echo ".env file generated successfully!"

# 1. Clone Flutter SDK (stable channel, shallow clone to save space & time)
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter SDK (stable channel)..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable
else
  echo "Flutter SDK already exists, pulling updates..."
  cd flutter && git pull && cd ..
fi

# 2. Add Flutter to PATH for this execution session
export PATH="$PATH:$(pwd)/flutter/bin"

# 3. Verify installation and print version
echo "Flutter version details:"
flutter --version

# 4. Configure build settings
flutter config --enable-web

# MOCK mode is already enabled in main.dart and service_locator.dart
echo "✓ MOCK mode enabled (demo data will be used)"

# 5. Get pub dependencies
echo "Getting pub packages..."
flutter pub get

# 6. Run code generation (build_runner)
echo "Running code generators (build_runner)..."
flutter pub run build_runner build --delete-conflicting-outputs

# 7. Compile the Web app in release mode
echo "Compiling Flutter Web application..."
flutter build web --release

echo "=== Vercel Build Script Completed Successfully ==="
