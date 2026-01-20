#!/bin/bash

###############################################################################
# TestFlight Upload Script
#
# Builds, exports, and uploads visionOS/iOS/macOS apps to TestFlight.
# Works from any Xcode project directory.
#
# Usage:
#   upload.sh <project_name> <scheme_name> [options] [platform]
#   upload.sh --upload-only <scheme_name>
#
# Options:
#   --upload-only    Skip archive/export, upload existing IPA/PKG from ~/Desktop/<scheme>_Export/
#   --appstore       Distribute for App Store (selectable for App Store submission)
#                    Default is TestFlight Internal Only (NOT selectable for App Store)
#
# Platform:
#   visionos (default), ios, macos
#
# Examples:
#   upload.sh PfizerOutdoCancer PfizerOutdoCancer           # Internal testing only
#   upload.sh PfizerOutdoCancer PfizerOutdoCancer --appstore # App Store distribution
#   upload.sh --upload-only PfizerOutdoCancer               # Upload existing IPA only
#   upload.sh MyApp MyApp-Release --appstore                # Full build for App Store
#
# macOS Apps (Media Server):
#   For GrooveTech Media Server, run from the repo root (not subdirectory):
#     cd /path/to/groovetech-media-server
#     upload.sh GrooveTechMediaServer "GrooveTech Media Server" --appstore macos
#
#   Media Server uses a workspace (GrooveTechMediaServer.xcworkspace) at repo root.
#   The script auto-detects this and uses the correct derived data path.
#
# Distribution Modes:
#   Default (Internal Only):  Build works in TestFlight but CANNOT be selected
#                             for App Store submission. Use for testing.
#   --appstore:               Build works in TestFlight AND can be selected
#                             for App Store submission. Use for releases.
#
# Credentials:
#   - Set TESTFLIGHT_API_KEY_ID and TESTFLIGHT_ISSUER_ID env vars, OR
#   - Source ~/.config/testflight/credentials.env
#
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREDENTIALS_FILE="$HOME/.config/testflight/credentials.env"

# Load credentials from file if exists and env vars not set
if [[ -z "$TESTFLIGHT_API_KEY_ID" ]] && [[ -f "$CREDENTIALS_FILE" ]]; then
    source "$CREDENTIALS_FILE"
fi

# Parse all arguments - flags can be anywhere
UPLOAD_ONLY=false
APPSTORE_DISTRIBUTION=false
POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --upload-only)
            UPLOAD_ONLY=true
            shift
            ;;
        --appstore)
            APPSTORE_DISTRIBUTION=true
            shift
            ;;
        --*)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            exit 1
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

# Restore positional arguments
set -- "${POSITIONAL_ARGS[@]}"

# Parse positional arguments
PROJECT_NAME="${1:-}"
SCHEME_NAME="${2:-}"

# For --upload-only, scheme is the first positional arg
if [[ "$UPLOAD_ONLY" == true ]]; then
    SCHEME_NAME="${1:-}"
    PROJECT_NAME="$SCHEME_NAME"  # Not used for upload-only, but set for paths
fi

API_KEY_ID="${TESTFLIGHT_API_KEY_ID}"
ISSUER_ID="${TESTFLIGHT_ISSUER_ID}"
PLATFORM="${3:-visionos}"
TEAM_ID="${TESTFLIGHT_TEAM_ID:-UTK59YE75G}"

# Validate arguments
if [[ "$UPLOAD_ONLY" == true ]]; then
    if [[ -z "$SCHEME_NAME" ]]; then
        echo -e "${RED}❌ Missing scheme name${NC}"
        echo ""
        echo "Usage: $0 --upload-only <scheme_name>"
        echo ""
        echo "Example:"
        echo "  $0 --upload-only PfizerOutdoCancer"
        exit 1
    fi
elif [[ -z "$PROJECT_NAME" ]] || [[ -z "$SCHEME_NAME" ]]; then
    echo -e "${RED}❌ Missing project or scheme name${NC}"
    echo ""
    echo "Usage: $0 <project_name> <scheme_name> [options]"
    echo "       $0 --upload-only <scheme_name>"
    echo ""
    echo "Options:"
    echo "  --appstore    Build for App Store submission (default: internal testing only)"
    echo ""
    echo "Examples:"
    echo "  $0 PfizerOutdoCancer PfizerOutdoCancer             # Internal testing only"
    echo "  $0 PfizerOutdoCancer PfizerOutdoCancer --appstore  # App Store submission"
    echo "  $0 --upload-only PfizerOutdoCancer                 # Upload existing IPA"
    exit 1
fi

# Check for credentials
if [[ -z "$API_KEY_ID" ]] || [[ -z "$ISSUER_ID" ]]; then
    echo -e "${RED}❌ API credentials not found${NC}"
    echo ""
    echo "Set credentials in ~/.config/testflight/credentials.env:"
    echo "  TESTFLIGHT_API_KEY_ID=your_key_id"
    echo "  TESTFLIGHT_ISSUER_ID=your_issuer_id"
    exit 1
fi

# Validate API key file exists
API_KEY_FILE="$HOME/.appstoreconnect/private_keys/AuthKey_${API_KEY_ID}.p8"
if [[ ! -f "$API_KEY_FILE" ]]; then
    echo -e "${RED}❌ API key file not found: $API_KEY_FILE${NC}"
    echo ""
    echo "Please copy your .p8 file to:"
    echo "  ~/.appstoreconnect/private_keys/AuthKey_${API_KEY_ID}.p8"
    exit 1
fi

# Set platform-specific destination
case "$PLATFORM" in
    visionos)
        DESTINATION="generic/platform=visionOS"
        UPLOAD_TYPE="visionos"
        PACKAGE_EXT="ipa"
        ;;
    ios)
        DESTINATION="generic/platform=iOS"
        UPLOAD_TYPE="ios"
        PACKAGE_EXT="ipa"
        ;;
    macos)
        # macOS uses platform=macOS (not generic/) for proper package resolution
        DESTINATION="platform=macOS"
        UPLOAD_TYPE="macos"
        PACKAGE_EXT="pkg"
        ;;
    *)
        DESTINATION="generic/platform=visionOS"
        UPLOAD_TYPE="visionos"
        PACKAGE_EXT="ipa"
        ;;
esac

# Find project file
# Priority: workspace > project (workspaces handle SPM packages correctly)
PROJECT_FILE=""
PROJECT_FLAG=""
DERIVED_DATA_PATH=""

if [[ -d "${PROJECT_NAME}.xcworkspace" ]]; then
    PROJECT_FILE="${PROJECT_NAME}.xcworkspace"
    PROJECT_FLAG="-workspace"
elif [[ -d "${PROJECT_NAME}.xcodeproj" ]]; then
    PROJECT_FILE="${PROJECT_NAME}.xcodeproj"
    PROJECT_FLAG="-project"
else
    # Try to find any workspace or project in current directory
    WORKSPACE=$(find . -maxdepth 1 -name "*.xcworkspace" -not -name ".*" -not -path "*.xcodeproj/*" | head -1)
    if [[ -n "$WORKSPACE" ]]; then
        PROJECT_FILE="$WORKSPACE"
        PROJECT_FLAG="-workspace"
    else
        PROJECT=$(find . -maxdepth 1 -name "*.xcodeproj" -not -name ".*" | head -1)
        if [[ -n "$PROJECT" ]]; then
            PROJECT_FILE="$PROJECT"
            PROJECT_FLAG="-project"
        fi
    fi
fi

# For macOS apps with workspaces, use local derived data (like gj does)
# This ensures SPM packages are resolved correctly
if [[ "$PLATFORM" == "macos" ]] && [[ "$PROJECT_FLAG" == "-workspace" ]]; then
    DERIVED_DATA_PATH="$(pwd)/build/DerivedData"
    DERIVED_DATA_FLAG="-derivedDataPath \"$DERIVED_DATA_PATH\""
else
    DERIVED_DATA_FLAG=""
fi

if [[ -z "$PROJECT_FILE" ]] && [[ "$UPLOAD_ONLY" != true ]]; then
    echo -e "${RED}❌ No Xcode project or workspace found${NC}"
    exit 1
fi

# Set paths
ARCHIVE_PATH="$HOME/Desktop/${PROJECT_NAME}.xcarchive"
EXPORT_PATH="$HOME/Desktop/${PROJECT_NAME}_Export"
EXPORT_OPTIONS="$HOME/Desktop/ExportOptions_${PROJECT_NAME}.plist"
# macOS exports .pkg, iOS/visionOS export .ipa
PACKAGE_PATH="${EXPORT_PATH}/${SCHEME_NAME}.${PACKAGE_EXT}"

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
if [[ "$UPLOAD_ONLY" == true ]]; then
    echo -e "${BLUE}║        TestFlight Upload (Upload Only)                 ║${NC}"
elif [[ "$APPSTORE_DISTRIBUTION" == true ]]; then
    echo -e "${BLUE}║      TestFlight Upload (App Store Distribution)        ║${NC}"
else
    echo -e "${BLUE}║      TestFlight Upload (Internal Testing Only)         ║${NC}"
fi
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}📱 Scheme:${NC}   $SCHEME_NAME"
if [[ "$UPLOAD_ONLY" != true ]]; then
    echo -e "${GREEN}📁 Project:${NC}  $PROJECT_FILE"
    if [[ -n "$DERIVED_DATA_PATH" ]]; then
        echo -e "${GREEN}📂 DerivedData:${NC} $DERIVED_DATA_PATH"
    fi
fi
echo -e "${GREEN}🎯 Platform:${NC} $PLATFORM"
if [[ "$APPSTORE_DISTRIBUTION" == true ]]; then
    echo -e "${GREEN}📦 Mode:${NC}     App Store (selectable for submission)"
else
    echo -e "${YELLOW}📦 Mode:${NC}     Internal Only (NOT selectable for App Store)"
fi
echo -e "${GREEN}🔑 API Key:${NC}  $API_KEY_ID"
echo ""

# Skip archive/export if --upload-only
if [[ "$UPLOAD_ONLY" == true ]]; then
    echo -e "${YELLOW}⏭️  Skipping archive/export (--upload-only mode)${NC}"
    echo ""
    
    if [[ ! -f "$PACKAGE_PATH" ]]; then
        echo -e "${RED}❌ Package not found: $PACKAGE_PATH${NC}"
        echo ""
        echo "Run full build first:"
        echo "  $0 $PROJECT_NAME $SCHEME_NAME"
        exit 1
    fi
    
    PACKAGE_SIZE=$(du -h "$PACKAGE_PATH" | cut -f1)
    echo -e "${GREEN}📦 Found existing package: $PACKAGE_PATH ($PACKAGE_SIZE)${NC}"
    echo ""
else
    # Step 1: Archive
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}🔨 Step 1/3: Building Archive${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo ""

    # Clean previous
    [[ -d "$ARCHIVE_PATH" ]] && rm -rf "$ARCHIVE_PATH"

    # Build archive command
    ARCHIVE_CMD="xcodebuild $PROJECT_FLAG \"$PROJECT_FILE\" \
        -scheme \"$SCHEME_NAME\" \
        archive \
        -archivePath \"$ARCHIVE_PATH\" \
        -destination \"$DESTINATION\""
    
    # Add derived data path for macOS workspaces
    if [[ -n "$DERIVED_DATA_PATH" ]]; then
        ARCHIVE_CMD="$ARCHIVE_CMD -derivedDataPath \"$DERIVED_DATA_PATH\""
    fi

    eval $ARCHIVE_CMD 2>&1 | grep -E "ARCHIVE SUCCEEDED|ARCHIVE FAILED|warning:|error:|Signing" || true

    if [[ ! -d "$ARCHIVE_PATH" ]]; then
        echo -e "${RED}❌ Archive failed${NC}"
        exit 1
    fi

    echo ""
    echo -e "${GREEN}✅ Archive created: $ARCHIVE_PATH${NC}"
    echo ""

    # Step 2: Export
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}📦 Step 2/3: Exporting IPA${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo ""

    # Clean previous
    [[ -d "$EXPORT_PATH" ]] && rm -rf "$EXPORT_PATH"

    # Create export options (uploadSymbols=false for rsync bug workaround)
    # testFlightInternalTestingOnly determines if build can be selected for App Store
    if [[ "$APPSTORE_DISTRIBUTION" == true ]]; then
        INTERNAL_ONLY_XML=""
        echo -e "${GREEN}📦 Distribution: App Store Connect (can be selected for App Store submission)${NC}"
    else
        INTERNAL_ONLY_XML="    <key>testFlightInternalTestingOnly</key>
    <true/>"
        echo -e "${YELLOW}📦 Distribution: TestFlight Internal Only (use --appstore for App Store submission)${NC}"
    fi
    
    cat > "$EXPORT_OPTIONS" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>compileBitcode</key>
    <false/>
    <key>destination</key>
    <string>export</string>
    <key>method</key>
    <string>app-store</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>teamID</key>
    <string>${TEAM_ID}</string>
${INTERNAL_ONLY_XML}
    <key>uploadSymbols</key>
    <false/>
</dict>
</plist>
EOF

    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportOptionsPlist "$EXPORT_OPTIONS" \
        -exportPath "$EXPORT_PATH" \
        -allowProvisioningUpdates \
        2>&1 | grep -E "EXPORT SUCCEEDED|EXPORT FAILED|error:|Exported" || true

    if [[ ! -f "$PACKAGE_PATH" ]]; then
        echo -e "${RED}❌ Export failed - package not found: $PACKAGE_PATH${NC}"
        echo ""
        echo "Check distribution logs:"
        echo "  ls -lt /var/folders/*/*/T/${SCHEME_NAME}_*.xcdistributionlogs/"
        exit 1
    fi

    PACKAGE_SIZE=$(du -h "$PACKAGE_PATH" | cut -f1)
    echo ""
    echo -e "${GREEN}✅ Package exported: $PACKAGE_PATH ($PACKAGE_SIZE)${NC}"
    echo ""
fi

# Upload Step
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
if [[ "$UPLOAD_ONLY" == true ]]; then
    echo -e "${YELLOW}🚀 Uploading to App Store Connect${NC}"
else
    echo -e "${YELLOW}🚀 Step 3/3: Uploading to App Store Connect${NC}"
fi
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}⏳ This may take 10-20 minutes for large IPAs...${NC}"
echo ""

xcrun altool --upload-package "$PACKAGE_PATH" \
    --type "$UPLOAD_TYPE" \
    --apiKey "$API_KEY_ID" \
    --apiIssuer "$ISSUER_ID" \
    --show-progress

UPLOAD_STATUS=$?

echo ""
if [[ $UPLOAD_STATUS -eq 0 ]]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              🎉 UPLOAD SUCCESSFUL! 🎉                  ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    if [[ "$APPSTORE_DISTRIBUTION" == true ]]; then
        echo "📋 Next Steps (App Store Distribution):"
        echo "   1. Wait 10-15 minutes for Apple processing"
        echo "   2. Check: https://appstoreconnect.apple.com/apps"
        echo "   3. Go to your app → App Store tab → select version"
        echo "   4. Click (+) next to Build and select this build"
        echo "   5. Submit for App Review"
    else
        echo "📋 Next Steps (Internal Testing Only):"
        echo "   1. Wait 10-15 minutes for Apple processing"
        echo "   2. Check: https://appstoreconnect.apple.com/apps"
        echo "   3. Go to your app → TestFlight tab"
        echo "   4. Add testers and distribute"
        echo ""
        echo -e "${YELLOW}⚠️  This build is for internal testing only.${NC}"
        echo -e "${YELLOW}   To submit to App Store, rebuild with --appstore flag:${NC}"
        echo -e "${YELLOW}   upload.sh $PROJECT_NAME $SCHEME_NAME --appstore${NC}"
    fi
    echo ""
    echo "🧹 Cleanup (optional):"
    echo "   rm -rf \"$ARCHIVE_PATH\" \"$EXPORT_PATH\" \"$EXPORT_OPTIONS\""
    echo ""
else
    echo -e "${RED}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                  ❌ UPLOAD FAILED                       ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Common issues:"
    echo "   • App doesn't exist in App Store Connect"
    echo "   • visionOS platform not enabled"
    echo "   • Invalid or expired API key"
    echo "   • Build number already uploaded"
    exit 1
fi
