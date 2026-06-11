#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "=== Starting Flutter Web Build on Vercel ==="

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
