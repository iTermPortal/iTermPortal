#!/bin/bash

# Create the sync directory that the Finder Sync extension monitors
echo "Creating sync directory..."
mkdir -p "/Users/Shared/MySyncExtension Documents"

echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Build and run the app from Xcode"
echo "2. Open System Settings > Privacy & Security > Extensions > Added Extensions"
echo "3. Enable 'fPortalExtension'"
echo "4. Navigate to '/Users/Shared/MySyncExtension Documents' in Finder"
echo "5. You should see the fPortal toolbar icon appear!"

