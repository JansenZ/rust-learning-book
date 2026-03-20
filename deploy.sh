#!/bin/bash
# 部署脚本：将 book/ 目录推送到 gh-pages 分支

set -e

echo "🚀 开始部署 Rust 学习笔记到 GitHub Pages..."

# 保存当前分支
CURRENT_BRANCH=$(git branch --show-current)

# 创建临时目录
TMP_DIR=$(mktemp -d)
cp -r book/* "$TMP_DIR/"

# 切换到 gh-pages 分支
git checkout --orphan gh-pages 2>/dev/null || git checkout gh-pages

# 删除所有文件，只保留部署文件
git rm -rf . 2>/dev/null || true

# 复制静态文件
cp -r "$TMP_DIR"/* .

# 添加 .nojekyll 防止 Jekyll 处理
touch .nojekyll

# 提交并推送
git add -A
git commit -m "Deploy to GitHub Pages: $(date '+%Y-%m-%d %H:%M:%S')" || true
git push origin gh-pages --force

# 切回原分支
git checkout "$CURRENT_BRANCH"

# 清理临时目录
rm -rf "$TMP_DIR"

echo "✅ 部署完成！"
echo "🌐 访问地址: https://jansenz.github.io/rust-learning-book/"
