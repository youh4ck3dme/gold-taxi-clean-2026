#!/bin/bash

# =============================================================================
# GoldTaxi - Automatic Supabase Setup Script
# This script automates Supabase setup from A to Z
# Run: bash scripts/setup-supabase-auto.sh
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project info
PROJECT_NAME="Gold-Taxi"
PROJECT_REF="nscxuxhapaabtsiduxlu"
SUPABASE_URL="https://${PROJECT_REF}.supabase.co"

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}Error: Not in GoldTaxi project directory!${NC}"
    echo "Please run this script from: /Users/erikbabcan/Gold-taxi"
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}GoldTaxi Automatic Supabase Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Step 1: Check Supabase CLI
STEP=1
echo -e "${YELLOW}[${STEP}] Checking Supabase CLI...${NC}"
if ! command -v supabase &> /dev/null; then
    echo -e "${RED}Supabase CLI not found!${NC}"
    echo "Installing Supabase CLI..."
    if command -v brew &> /dev/null; then
        brew install supabase/tap/supabase
    elif command -v npm &> /dev/null; then
        npm install -g supabase
    else
        echo -e "${RED}Error: Cannot install Supabase CLI automatically.${NC}"
        echo "Please install it manually:"
        echo "  macOS: brew install supabase/tap/supabase"
        echo "  Linux: npm install -g supabase"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Supabase CLI is installed${NC}"
fi

# Step 2: Login to Supabase
STEP=$((STEP+1))
echo -e "${YELLOW}[${STEP}] Logging into Supabase...${NC}"
if ! supabase status &> /dev/null; then
    echo "Opening browser for Supabase login..."
    supabase login
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Supabase login failed${NC}"
        echo "Please run 'supabase login' manually and try again."
        exit 1
    fi
    echo -e "${GREEN}✓ Successfully logged into Supabase${NC}"
else
    echo -e "${GREEN}✓ Already logged into Supabase${NC}"
fi

# Step 3: Link project
STEP=$((STEP+1))
echo -e "${YELLOW}[${STEP}] Linking project ${PROJECT_REF}...${NC}"
if supabase status | grep -q "${PROJECT_REF}"; then
    echo -e "${GREEN}✓ Project already linked${NC}"
else
    echo "Linking project..."
    supabase link --project-ref ${PROJECT_REF}
    echo -e "${GREEN}✓ Project linked successfully${NC}"
fi

# Step 4: Get Supabase credentials
STEP=$((STEP+1))
echo -e "${YELLOW}[${STEP}] Getting Supabase credentials...${NC}"

# Try to get the anon key from the project
ANON_KEY=$(supabase config -o json 2>/dev/null | grep -o '"anon_key":"[^"]*"' | cut -d'"' -f4 || true)

if [ -z "$ANON_KEY" ]; then
    echo "Could not get key automatically. Please enter it manually."
    echo "You can find it at: https://app.supabase.com/project/${PROJECT_REF}/settings/api"
    read -p "Enter SUPABASE_ANON_KEY: " ANON_KEY
fi

echo -e "${GREEN}✓ Got Supabase credentials${NC}"
echo "  URL: ${SUPABASE_URL}"
echo "  Anon Key: ${ANON_KEY:0:30}..."

# Step 5: Create .env file
STEP=$((STEP+1))
echo -e "${YELLOW}[${STEP}] Creating .env file...${NC}"

# Get Google Maps API Key
GOOGLE_MAPS_KEY=""
if [ -f ".env" ]; then
    GOOGLE_MAPS_KEY=$(grep "GOOGLE_MAPS_API_KEY=" .env | cut -d'=' -f2 || true)
fi

if [ -z "$GOOGLE_MAPS_KEY" ]; then
    read -p "Enter GOOGLE_MAPS_API_KEY (or press Enter to skip): " GOOGLE_MAPS_KEY
fi

# Create .env file
cat > .env << EOF
# Supabase Configuration
SUPABASE_URL=${SUPABASE_URL}
SUPABASE_ANON_KEY=${ANON_KEY}

# Google Maps (optional)
GOOGLE_MAPS_API_KEY=${GOOGLE_MAPS_KEY}

# Backend Mode
BACKEND_MODE=supabase
EOF

# Add .env to .gitignore if not already there
if ! grep -q "^\.env$" .gitignore; then
    echo ".env" >> .gitignore
    echo -e "${GREEN}✓ Added .env to .gitignore${NC}"
fi

echo -e "${GREEN}✓ .env file created${NC}"

# Step 6: Run database migration
STEP=$((STEP+1))
echo -e "${YELLOW}[${STEP}] Running database migration...${NC}"
if [ -f "supabase_migration.sql" ]; then
    echo "Applying database schema..."
    supabase db reset || {
        echo -e "${YELLOW}Note: Database reset requires local Supabase. Skipping...${NC}"
        echo "Please apply supabase_migration.sql manually in Supabase SQL Editor"
    }
    echo -e "${GREEN}✓ Database migration script ready${NC}"
else
    echo -e "${YELLOW}No supabase_migration.sql found. Skipping...${NC}"
fi

# Step 7: Create test user
STEP=$((STEP+1))
echo -e "${YELLOW}[${STEP}] Creating test user...${NC}"

# Generate a random password
TEST_PASSWORD=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 16)
TEST_EMAIL="test+$(date +%s)@goldtaxi.sk"

# Create user via Supabase CLI or API
# This would need to be done manually or via the dashboard
# For now, we'll just print instructions
cat > create_test_user.sql << EOF
-- Run this in Supabase SQL Editor to create a test user

-- Insert into auth.users (use Supabase Dashboard or API)
-- Then insert into profiles:
INSERT INTO public.profiles (id, email, name, role, created_at)
VALUES (
  'test-user-$(date +%s)',
  '${TEST_EMAIL}',
  'Test User',
  'customer',
  NOW()
);

-- Or use Supabase Dashboard:
-- 1. Go to Authentication -> Users
-- 2. Click "Add User"
-- 3. Enter email and password
EOF

echo "Test user SQL created: create_test_user.sql"
echo "Email: ${TEST_EMAIL}"
echo "Password: ${TEST_PASSWORD}"
echo ""
echo "Please run the SQL manually or create a user via Supabase Dashboard"
echo -e "${YELLOW}Note: Auto-creating users requires Supabase API key${NC}"

# Step 8: Configure Flutter
STEP=$((STEP+1))
echo -e "${YELLOW}[${STEP}] Configuring Flutter...${NC}"

# Check if main_common.dart uses environment variables
if grep -q "String.fromEnvironment" lib/main_common.dart; then
    echo -e "${GREEN}✓ Flutter already uses environment variables${NC}"
else
    echo -e "${YELLOW}Note: You may need to update main_common.dart to use String.fromEnvironment${NC}"
fi

# Step 9: Run the app
STEP=$((STEP+1))
echo -e "${YELLOW}[${STEP}] Ready to run the app!${NC}"
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Run the following command to start the app:${NC}"
echo ""
echo "flutter run -d chrome \\"
echo "  --dart-define=SUPABASE_URL=${SUPABASE_URL} \\"
echo "  --dart-define=SUPABASE_ANON_KEY=${ANON_KEY} \\"
echo -e "  --dart-define=BACKEND_MODE=supabase${NC}"
echo ""

# Step 10: Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Setup Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "✓ Supabase CLI: ${GREEN}Installed${NC}"
echo -e "✓ Supabase Login: ${GREEN}Done${NC}"
echo -e "✓ Project Linked: ${GREEN}${PROJECT_REF}${NC}"
echo -e "✓ .env File: ${GREEN}Created${NC}"
echo -e "✓ Database: ${YELLOW}Migration ready (run manually)${NC}"
echo -e "✓ Test User: ${YELLOW}SQL ready (create manually)${NC}"
echo ""
echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Apply supabase_migration.sql in Supabase SQL Editor"
echo "2. Create a test user via Supabase Dashboard"
echo "3. Run the app with the flutter run command above"
echo "4. Test login with your user"
echo ""
