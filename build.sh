#!/bin/bash
set -e

echo "=== Step 1: Hugo build ==="
hugo

echo "=== Step 2: Remove alias redirect files ==="
# Alias files are small HTML redirects containing <meta http-equiv="refresh">
# They typically have only a few lines and no real page content
find public -name "*.html" -type f | while read -r f; do
    # Check if file has the pattern of an alias redirect (small, has meta refresh)
    lines=$(wc -l < "$f")
    if [ "$lines" -lt 15 ]; then
        if grep -q 'http-equiv="refresh"' "$f" 2>/dev/null; then
            rm "$f"
            # Also check if parent dir index was the only file, clean up empty dirs
            dir=$(dirname "$f")
            if [ -d "$dir" ] && [ -z "$(ls -A "$dir" 2>/dev/null)" ]; then
                rmdir "$dir" 2>/dev/null || true
            fi
        fi
    fi
done

echo "Alias files cleaned. Remaining HTML files: $(find public -name '*.html' | wc -l)"

echo "=== Step 3: Pagefind index ==="
npx pagefind --site public

echo "=== Build complete ==="
