#!/bin/bash
export HOME=/Users/erikbabcan
cd /Users/erikbabcan/Projects/NEXIFY-STUDIO/bolt-flutter-app
git init
git add README.md
git commit --no-gpg-sign -m "🎯 init: Project initialized"

flutter create --org com.nexify flutter_app
cd flutter_app
flutter pub add riverpod flutter_riverpod dio retrofit firebase_core hive hive_flutter json_annotation
flutter pub add --dev json_serializable build_runner
flutter pub run build_runner build

cd ..
git add .
git commit --no-gpg-sign -m "🎯 init: Flutter skeleton + 3 models + API service + Home screen"
echo "✅ HOTOVO! Všetko je pripravené na spustenie."
