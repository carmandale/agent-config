#!/bin/bash

###############################################################################
# Create Enterprise Delivery Package
#
# Creates a delivery folder with xcarchive and README for enterprise re-signing.
#
# Usage:
#   create-delivery.sh <archive_path> <app_name> <version> <build> <bundle_id> <platform> [description]
#
# Example:
#   create-delivery.sh ~/Desktop/MyApp.xcarchive "My App" "1.2" "75" "com.company.myapp" "visionOS" "Description here"
#
###############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$SCRIPT_DIR/delivery-readme-template.md"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Parse arguments
ARCHIVE_PATH="${1:-}"
APP_NAME="${2:-}"
VERSION="${3:-}"
BUILD="${4:-}"
BUNDLE_ID="${5:-}"
PLATFORM="${6:-}"
DESCRIPTION="${7:-This app is provided for enterprise distribution.}"

if [[ -z "$ARCHIVE_PATH" ]] || [[ -z "$APP_NAME" ]] || [[ -z "$VERSION" ]] || [[ -z "$BUILD" ]] || [[ -z "$BUNDLE_ID" ]] || [[ -z "$PLATFORM" ]]; then
    echo -e "${RED}Usage: $0 <archive_path> <app_name> <version> <build> <bundle_id> <platform> [description]${NC}"
    echo ""
    echo "Example:"
    echo "  $0 ~/Desktop/PfizerOutdoCancer.xcarchive \"Outdo Cancer\" \"1.2\" \"75\" \"com.groovejones.PfizerOutdoCancer\" \"visionOS (Apple Vision Pro)\" \"Educational ADC building experience\""
    exit 1
fi

if [[ ! -d "$ARCHIVE_PATH" ]]; then
    echo -e "${RED}Archive not found: $ARCHIVE_PATH${NC}"
    exit 1
fi

# Derive names
ARCHIVE_NAME=$(basename "$ARCHIVE_PATH" .xcarchive)
SAFE_APP_NAME=$(echo "$APP_NAME" | tr ' ' '_' | tr -cd '[:alnum:]_-')
FOLDER_NAME="${SAFE_APP_NAME}_Delivery_v${VERSION}_Build${BUILD}"
DELIVERY_PATH="$HOME/Desktop/$FOLDER_NAME"
DATE=$(date "+%B %d, %Y")

# Platform requirements
case "$PLATFORM" in
    *visionOS*|*Vision*)
        PLATFORM_REQUIREMENTS="Apple Vision Pro with visionOS 2.0+"
        ;;
    *macOS*|*Mac*)
        PLATFORM_REQUIREMENTS="Mac with macOS 14.0+ (Sonoma)"
        ;;
    *iOS*|*iPad*)
        PLATFORM_REQUIREMENTS="iPhone/iPad with iOS 17.0+"
        ;;
    *)
        PLATFORM_REQUIREMENTS="$PLATFORM"
        ;;
esac

# Get archive size
ARCHIVE_SIZE=$(du -sh "$ARCHIVE_PATH" | cut -f1)

echo -e "${GREEN}Creating delivery package...${NC}"
echo "  App: $APP_NAME"
echo "  Version: $VERSION ($BUILD)"
echo "  Platform: $PLATFORM"
echo "  Bundle ID: $BUNDLE_ID"
echo ""

# Create folder
mkdir -p "$DELIVERY_PATH"

# Generate README from template
if [[ -f "$TEMPLATE" ]]; then
    sed -e "s|{{APP_NAME}}|$APP_NAME|g" \
        -e "s|{{VERSION}}|$VERSION|g" \
        -e "s|{{BUILD}}|$BUILD|g" \
        -e "s|{{DATE}}|$DATE|g" \
        -e "s|{{PLATFORM}}|$PLATFORM|g" \
        -e "s|{{BUNDLE_ID}}|$BUNDLE_ID|g" \
        -e "s|{{ARCHIVE_NAME}}|$ARCHIVE_NAME|g" \
        -e "s|{{ARCHIVE_SIZE}}|$ARCHIVE_SIZE|g" \
        -e "s|{{FOLDER_NAME}}|$FOLDER_NAME|g" \
        -e "s|{{APP_DESCRIPTION}}|$DESCRIPTION|g" \
        -e "s|{{PLATFORM_REQUIREMENTS}}|$PLATFORM_REQUIREMENTS|g" \
        "$TEMPLATE" > "$DELIVERY_PATH/README.md"
else
    echo -e "${YELLOW}Warning: Template not found, creating basic README${NC}"
    cat > "$DELIVERY_PATH/README.md" << EOF
# $APP_NAME - Enterprise Delivery

**Version:** $VERSION  
**Build:** $BUILD  
**Date:** $DATE  
**Platform:** $PLATFORM  
**Bundle ID:** \`$BUNDLE_ID\`

## Contents

- \`$ARCHIVE_NAME.xcarchive\` ($ARCHIVE_SIZE)

## Instructions

1. Open the archive in Xcode (Window → Organizer)
2. Click "Distribute App" → Choose "Enterprise" or "Ad Hoc"
3. Sign with your enterprise certificate
4. Deploy the exported IPA via your MDM

## Support

Contact: Groove Jones
EOF
fi

# Move archive
mv "$ARCHIVE_PATH" "$DELIVERY_PATH/"

echo -e "${GREEN}✅ Delivery package created:${NC}"
echo "   $DELIVERY_PATH"
echo ""
echo "Contents:"
ls -lh "$DELIVERY_PATH/"
echo ""
echo -e "${YELLOW}Next: Zip and send to recipient${NC}"
