#!/bin/sh
# Update version.asm with new version from cog
# Usage: update-version.sh <version>
# Example: update-version.sh 0.2.0

VERSION="$1"

if [ -z "$VERSION" ]; then
    echo "Error: Version argument required"
    exit 1
fi

# Parse major and minor from semver (ignore patch)
MAJOR=$(echo "$VERSION" | cut -d. -f1)
MINOR=$(echo "$VERSION" | cut -d. -f2)

# Update version.asm (Alpine sed uses -i without extension argument)
sed -i "s/^\.const VERSION_MAJOR = .*/.const VERSION_MAJOR = ${MAJOR}/" version.asm
sed -i "s/^\.const VERSION_MINOR = .*/.const VERSION_MINOR = ${MINOR}/" version.asm

# Stage the change
git add version.asm

echo "Updated version.asm to v${MAJOR}.${MINOR}"
