#!/bin/bash
set -e

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
