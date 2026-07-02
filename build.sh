#!/bin/bash
set -e

echo "=== Step 1: Hugo build ==="
hugo

echo "=== Step 2: Remove alias redirect files ==="
# Hugo生成的别名文件有3个特征：
# 1. 包含 <meta http-equiv="refresh"
# 2. 文件较小（< 15行）
# 3. 内容结构是标准的 HTML redirect 模板
count_before=$(find public -name "*.html" | wc -l)
find public -name "*.html" -type f | while read -r f; do
    lines=$(wc -l < "$f")
    if [ "$lines" -lt 15 ]; then
        if grep -q 'http-equiv="refresh"' "$f" 2>/dev/null; then
            rm "$f"
        fi
    fi
done
# 清理空目录
find public -type d -empty -delete 2>/dev/null || true
count_after=$(find public -name "*.html" | wc -l)
echo "HTML files: $count_before -> $count_after ($((count_after - count_before)) alias files removed)"

echo "=== Step 3: Pagefind index ==="
npx pagefind --site public
echo "=== Build complete ==="
