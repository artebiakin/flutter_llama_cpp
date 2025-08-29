#!/bin/bash
# Script to check current vendor dependency versions

set -e

VENDOR_PATH="src/vendor/llama.cpp"
VERSION_FILE="tool/version_info.yaml"

echo "🔍 Checking vendor dependency versions..."
echo ""

if [ -d "$VENDOR_PATH" ]; then
    echo "📦 llama.cpp Information:"
    echo "  Location: $VENDOR_PATH"
    
    # Check our version tracking file first
    if [ -f "$VERSION_FILE" ]; then
        TRACKED_VERSION=$(grep -A 1 "llama_cpp:" "$VERSION_FILE" | grep "version:" | cut -d'"' -f2 2>/dev/null || echo "")
        TRACKED_DATE=$(grep -A 5 "llama_cpp:" "$VERSION_FILE" | grep "added_date:" | cut -d'"' -f2 2>/dev/null || echo "")
        if [ ! -z "$TRACKED_VERSION" ]; then
            echo "  Tracked version: $TRACKED_VERSION"
        fi
        if [ ! -z "$TRACKED_DATE" ]; then
            echo "  Integration date: $TRACKED_DATE"
        fi
    fi
    
    cd "$VENDOR_PATH"
    
    # Check if it's a git directory
    if [ -d ".git" ]; then
        CURRENT_COMMIT=$(git rev-parse HEAD | cut -c1-7)
        echo "  Current commit: $CURRENT_COMMIT"
        
        # Get commit date
        COMMIT_DATE=$(git show -s --format=%ci HEAD | cut -d' ' -f1)
        echo "  Commit date: $COMMIT_DATE"
        
        # Get commit message
        COMMIT_MSG=$(git show -s --format=%s HEAD)
        echo "  Last change: $COMMIT_MSG"
    else
        echo "  Status: Vendored via git subtree (no local git history)"
        
        # Check for llama.cpp version indicators in source
        if [ -f "include/llama.h" ]; then
            SESSION_VERSION=$(grep "LLAMA_SESSION_VERSION" include/llama.h | awk '{print $3}' 2>/dev/null || echo "unknown")
            echo "  LLAMA_SESSION_VERSION: $SESSION_VERSION"
        fi
        
        # Check CMakeLists.txt for project info
        if [ -f "CMakeLists.txt" ]; then
            PROJECT_LINE=$(grep -i "project.*llama" CMakeLists.txt | head -1 || echo "")
            if [ ! -z "$PROJECT_LINE" ]; then
                echo "  CMake project: $PROJECT_LINE"
            fi
        fi
        
        # Check if there's a README with version info
        if [ -f "README.md" ]; then
            # Look for any version-like patterns in the first few lines
            VERSION_INFO=$(head -20 README.md | grep -i "version\|commit\|release" | head -2 || echo "")
            if [ ! -z "$VERSION_INFO" ]; then
                echo "  README info: $VERSION_INFO"
            fi
        fi
    fi
    
    cd - > /dev/null
    
else
    echo "❌ llama.cpp not found at $VENDOR_PATH"
fi

echo ""
echo "📋 To update llama.cpp, run:"
echo "  ./tool/update_llama_cpp.sh <new-commit-hash>"
echo ""
echo "📄 For detailed dependency info, see:"
echo "  cat $VERSION_FILE"
echo "  cat VENDOR_DEPENDENCIES.md"
