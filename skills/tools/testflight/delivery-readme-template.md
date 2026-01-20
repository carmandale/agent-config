# {{APP_NAME}} - Enterprise Delivery

**Version:** {{VERSION}}  
**Build:** {{BUILD}}  
**Date:** {{DATE}}  
**Platform:** {{PLATFORM}}  
**Bundle ID:** `{{BUNDLE_ID}}`

---

## Contents

```
{{FOLDER_NAME}}/
├── {{ARCHIVE_NAME}}.xcarchive   ({{ARCHIVE_SIZE}})
└── README.md
```

---

## What Is This?

{{APP_DESCRIPTION}}

This archive is signed for App Store distribution. To install on devices via your internal app store or MDM, you must **re-sign it with your enterprise certificate**.

---

## Re-Signing Instructions

### Option A: Xcode (Recommended)

1. **Import the archive**
   - Double-click `{{ARCHIVE_NAME}}.xcarchive`, or
   - Xcode → Window → Organizer → Archives (right-click → "Show in Finder" to import)

2. **Distribute with your signing identity**
   - Select the archive → "Distribute App"
   - Choose **"Enterprise"** or **"Ad Hoc"** (depending on your setup)
   - Select your enterprise team and signing certificate
   - Choose your provisioning profile for `{{BUNDLE_ID}}`
   - Click "Export"

3. **Deploy**
   - Upload the exported `.ipa` to your MDM / internal app store

### Option B: Command Line

1. **Create an ExportOptions.plist** for your enterprise signing:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>enterprise</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>{{BUNDLE_ID}}</key>
        <string>YOUR_PROVISIONING_PROFILE_NAME</string>
    </dict>
</dict>
</plist>
```

2. **Export the IPA:**

```bash
xcodebuild -exportArchive \
  -archivePath {{ARCHIVE_NAME}}.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath ./Export
```

3. **Deploy** the resulting `.ipa` via your MDM.

---

## Requirements

| Requirement | Details |
|-------------|---------|
| Xcode | 16.0 or later |
| Platform | {{PLATFORM_REQUIREMENTS}} |
| Certificate | Enterprise or Ad Hoc Distribution |
| Provisioning | Profile for `{{BUNDLE_ID}}` with target devices |

---

## Troubleshooting

**"No signing certificate found"**  
→ Ensure your enterprise distribution certificate is installed in Keychain.

**"Provisioning profile doesn't match"**  
→ Create a new provisioning profile for bundle ID `{{BUNDLE_ID}}` in your Apple Developer portal.

**"Device not included"** (Ad Hoc only)  
→ Add device UDIDs to your provisioning profile and regenerate.

---

## Support

**Groove Jones**  
Contact: Dale Carman  
Email: dale@groovejones.com  
Phone: (214) 810-7622

---

*Archive generated {{DATE}} by Groove Jones*
