#!/bin/bash
# Quick validation script for local unback feature
# Creates a minimal test backup and shows expected behavior

TEST_DIR="/tmp/unback_validation_$$"
BACKUP_DIR="$TEST_DIR/backup"
UDID="0123456789ABCDEF0123456789ABCDEF01234567"  # Valid 40-char hex UDID

echo "Creating test iOS backup in: $BACKUP_DIR"

# Setup
mkdir -p "$BACKUP_DIR/$UDID"

# Create minimal Info.plist
cat > "$BACKUP_DIR/$UDID/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Target Identifier</key>
    <string>0123456789ABCDEF0123456789ABCDEF01234567</string>
</dict>
</plist>
EOF

# Create Manifest.plist (unencrypted)
cat > "$BACKUP_DIR/$UDID/Manifest.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>IsEncrypted</key>
    <false/>
</dict>
</plist>
EOF

# Create Manifest.db
sqlite3 "$BACKUP_DIR/$UDID/Manifest.db" << 'EOSQL'
CREATE TABLE Files (fileID TEXT PRIMARY KEY, domain TEXT, relativePath TEXT, flags INTEGER, file BLOB);
INSERT INTO Files (fileID, domain, relativePath) VALUES 
    ('a1b2c3d4e5f6', 'HomeDomain', 'Library/Preferences/test.plist'),
    ('1a2b3c4d5e6f', 'MediaDomain', 'DCIM/100APPLE/IMG_0001.JPG');
EOSQL

# Create backup files
echo "Test preference file content" > "$BACKUP_DIR/$UDID/a1b2c3d4e5f6"
echo "Fake JPEG data" > "$BACKUP_DIR/$UDID/1a2b3c4d5e6f"

echo ""
echo "✓ Test backup created at: $BACKUP_DIR"
echo "✓ UDID: $UDID"
echo "✓ Files: 2"
echo ""
echo "Directory structure:"
tree "$BACKUP_DIR" 2>/dev/null || find "$BACKUP_DIR" -type f
echo ""
echo "To test with idevicebackup2 (after compilation):"
echo "  cd $BACKUP_DIR"
echo "  idevicebackup2 unback ."
echo ""
echo "Expected result:"
echo "  - Auto-detects UDID: $UDID"
echo "  - Creates _unback_/ directory"
echo "  - Unpacks 2 files to original paths:"
echo "    • HomeDomain/Library/Preferences/test.plist"
echo "    • MediaDomain/DCIM/100APPLE/IMG_0001.JPG"
echo ""
echo "Test directory will remain for manual testing: $TEST_DIR"
echo "(Delete with: rm -rf $TEST_DIR)"
