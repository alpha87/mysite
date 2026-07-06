#!/bin/bash
set -e

# Pin Hugo version (Blowfish theme requires >0.122, CF Pages default 0.147.7 has type issues)
HUGO_VERSION="0.162.1"
ARCH=$(uname -m)
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

# Detect if we need to download Hugo (on CF Pages Linux, or the system version is wrong)
NEED_DOWNLOAD=false
if [ "$OS" = "linux" ]; then
    # On CF Pages or any Linux build environment
    if ! command -v hugo &> /dev/null || ! hugo version | grep -q "v${HUGO_VERSION}"; then
        NEED_DOWNLOAD=true
    fi
fi

if [ "$NEED_DOWNLOAD" = true ]; then
    echo "=== Installing Hugo ${HUGO_VERSION} ==="
    mkdir -p bin
    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        HUGO_URL="https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-arm64.tar.gz"
    else
        HUGO_URL="https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz"
    fi
    echo "Downloading from ${HUGO_URL}..."
    curl -sL "$HUGO_URL" | tar xz -C ./bin hugo 2>/dev/null
    chmod +x ./bin/hugo
    export PATH="./bin:$PATH"
    echo "Using Hugo $(hugo version)"
fi

echo "=== Step 1: Hugo build ==="
hugo

echo "=== Step 2: Remove alias redirect files ==="
find public -name "*.html" -type f | while read -r f; do
    lines=$(wc -l < "$f")
    if [ "$lines" -lt 15 ]; then
        if grep -q 'http-equiv="refresh"' "$f" 2>/dev/null; then
            rm "$f"
        fi
    fi
done
find public -type d -empty -delete 2>/dev/null || true

echo "=== Step 3: Remove XML RSS files ==="
# Hugo 为每个标签、分类自动生成 RSS feed（没人用）
# 保留 index.xml 和其他根级 XML（sitemap.xml等）
find public -name "*.xml" -type f ! -name "index.xml" ! -name "sitemap.xml" -delete
find public -type d -empty -delete 2>/dev/null || true

echo "=== Step 4: File count before Pagefind ==="
echo "  Total files : $(find public -type f | wc -l)"
echo "  HTML files  : $(find public -name '*.html' | wc -l)"
echo "  JSON files  : $(find public -name '*.json' | wc -l)"
echo "  CSS files   : $(find public -name '*.css' | wc -l)"
echo "  JS files    : $(find public -name '*.js' | wc -l)"
echo "  XML files   : $(find public -name '*.xml' | wc -l)"
echo "  Other files : $(find public -type f ! -name '*.html' ! -name '*.json' ! -name '*.css' ! -name '*.js' ! -name '*.xml' | wc -l)"

echo "=== Step 5: Pagefind index ==="
npx pagefind --site public

echo "=== Step 6: Final file count ==="
total=$(find public -type f | wc -l)
echo "  Total files: $total"
echo "  HTML files : $(find public -name '*.html' | wc -l)"
echo "  JSON files : $(find public -name '*.json' | wc -l)"
echo "  JS files   : $(find public -name '*.js' | wc -l)"
echo "  CSS files  : $(find public -name '*.css' | wc -l)"
echo "  Pagefind   : $(find public/pagefind -type f 2>/dev/null | wc -l)"

if [ "$total" -gt 20000 ]; then
    echo "  WARNING: Over 20,000 files! Exceeds Cloudflare limit by $((total - 20000))"
    echo ""
    echo "  Top 10 largest directories:"
    du -sh public/*/ 2>/dev/null | sort -rh | head -10
    echo ""
    echo "  File type breakdown:"
    find public -type f | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -20
fi

echo "=== Build complete ==="
