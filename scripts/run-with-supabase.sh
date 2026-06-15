#!/bin/bash

# GoldTaxi - Quick Run with Supabase
# Usage: bash scripts/run-with-supabase.sh
# Or: bash scripts/run-with-supabase.sh --web

PROJECT_REF="nscxuxhapaabtsiduxlu"
SUPABASE_URL="https://${PROJECT_REF}.supabase.co"

# Check if .env exists and get keys
if [ -f ".env" ]; then
    SUPABASE_URL=$(grep "^SUPABASE_URL=" .env | cut -d'=' -f2-)
    SUPABASE_ANON_KEY=$(grep "^SUPABASE_ANON_KEY=" .env | cut -d'=' -f2-)
    GOOGLE_MAPS_KEY=$(grep "^GOOGLE_MAPS_API_KEY=" .env | cut -d'=' -f2-)
fi

# Check command line arguments
if [ "$1" == "--web" ]; then
    echo "Building web with Supabase..."
    echo ""
    
    if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
        echo "❌ .env file missing or incomplete"
        echo "Please create .env with SUPABASE_URL and SUPABASE_ANON_KEY"
        echo "Or run: bash scripts/setup-supabase-auto.sh"
        exit 1
    fi
    
    flutter build web \
      --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
      --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}" \
      --dart-define=BACKEND_MODE=supabase \
      ${GOOGLE_MAPS_KEY:+--dart-define=GOOGLE_MAPS_API_KEY="${GOOGLE_MAPS_KEY}"}
    
    echo ""
    echo "✅ Web build created in build/web"
    echo ""
    echo "To serve locally:"
    echo "  cd build/web && python3 -m http.server 8080"
    echo ""
    echo "To deploy to Firebase:"
    echo "  firebase deploy"
    
elif [ "$1" == "--run" ] || [ -z "$1" ]; then
    echo "Running Flutter app with Supabase..."
    echo ""
    
    if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
        echo "❌ .env file missing or incomplete"
        echo "Please create .env with SUPABASE_URL and SUPABASE_ANON_KEY"
        echo "Or run: bash scripts/setup-supabase-auto.sh"
        exit 1
    fi
    
    flutter run -d chrome \
      --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
      --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}" \
      --dart-define=BACKEND_MODE=supabase \
      ${GOOGLE_MAPS_KEY:+--dart-define=GOOGLE_MAPS_API_KEY="${GOOGLE_MAPS_KEY}"}
else
    echo "Usage: bash scripts/run-with-supabase.sh [--run|--web]"
    echo ""
    echo "Options:"
    echo "  --run    Run the app in Chrome (default)"
    echo "  --web    Build web version"
    echo ""
    echo "Requirements:"
    echo "  - .env file with SUPABASE_URL and SUPABASE_ANON_KEY"
    echo "  - Supabase project: ${PROJECT_REF}"
    echo ""
    echo "Quick setup:"
    echo "  bash scripts/setup-supabase-auto.sh"
fi
