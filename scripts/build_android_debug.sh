#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Android Debug APK Build Process...${NC}"

# Check if flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Error: Flutter CLI is not installed or not in your PATH.${NC}"
    echo "Please install Flutter: https://docs.flutter.dev/get-started/install"
    exit 1
fi

# Navigate to project root (assuming script is run from project root or scripts folder)
# This finds the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Project Root: $PROJECT_ROOT"
cd "$PROJECT_ROOT"

# Check if android directory exists
if [ ! -d "android" ]; then
    echo -e "${RED}Error: 'android' directory not found. Are you in the correct Flutter project?${NC}"
    exit 1
fi

echo "Cleaning previous builds..."
flutter clean

echo "Fetching dependencies..."
flutter pub get

echo "Building Debug APK..."
flutter build apk --debug

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Build Successful!${NC}"
    echo "APK location: $PROJECT_ROOT/build/app/outputs/flutter-apk/app-debug.apk"
else
    echo -e "${RED}Build Failed.${NC}"
    exit 1
fi
