#!/bin/bash
# Script to clean, reinstall, generate code, and run analysis

echo "🧹 Cleaning project..."
flutter clean

echo "📦 Fetching dependencies..."
flutter pub get

echo "⚙️ Running code generator (build_runner)..."
flutter pub run build_runner build --delete-conflicting-outputs

echo "🔍 Running static analysis..."
flutter analyze

echo "✅ Check complete!"
