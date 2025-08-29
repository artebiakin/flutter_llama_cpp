#!/bin/bash
# Script to update llama.cpp version

set -e

REPO_URL="https://github.com/ggerganov/llama.cpp"
VENDOR_PATH="src/vendor/llama.cpp"
VERSION_FILE="tool/version_info.yaml"

if [ -z "$1" ]; then
    echo "Usage: $0 <commit-hash>"
    echo "Example: $0 b6316"
    exit 1
fi

NEW_COMMIT="$1"
CURRENT_DATE=$(date +%Y-%m-%d)

echo "Updating llama.cpp to commit: $NEW_COMMIT"

# Update the subtree
git subtree pull --prefix="$VENDOR_PATH" "$REPO_URL" "$NEW_COMMIT" --squash

# Update version info
sed -i.bak "s/version: \".*\"/version: \"$NEW_COMMIT\"/" "$VERSION_FILE"
sed -i.bak "s/commit_hash: \".*\"/commit_hash: \"$NEW_COMMIT\"/" "$VERSION_FILE"
sed -i.bak "s/added_date: \".*\"/added_date: \"$CURRENT_DATE\"/" "$VERSION_FILE"
rm "${VERSION_FILE}.bak"

echo "✅ llama.cpp updated to $NEW_COMMIT"
echo "📝 Updated $VERSION_FILE"
echo ""
echo "Next steps:"
echo "1. Test the build: flutter pub get && cd example && flutter run"
echo "2. Run tests: flutter test"
echo "3. Update CHANGELOG.md with the new version"
echo "4. Commit changes: git add . && git commit -m 'chore: update llama.cpp to $NEW_COMMIT'"
