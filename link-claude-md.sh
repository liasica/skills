#!/usr/bin/env bash
# 让 Claude Code 的全局记忆用上已有的 AGENTS.md
#   没有 CLAUDE.md，或内容与 AGENTS.md 相同：软链到 AGENTS.md
#   内容不同：备份后在 CLAUDE.md 开头加 `@` 导入，原内容不动
# 幂等，可重复执行
# 用法：`link-claude-md.sh [AGENTS.md 路径]`，默认读取 `${CODEX_HOME:-~/.codex}/AGENTS.md`
set -euo pipefail

agents="${1:-${CODEX_HOME:-$HOME/.codex}/AGENTS.md}"
claude_md="$HOME/.claude/CLAUDE.md"
stamp="$(date +%Y%m%d%H%M%S)"

[ -s "$agents" ] || { echo "未找到 $agents，或文件为空" >&2; exit 1; }
agents="$(cd "$(dirname "$agents")" && pwd)/$(basename "$agents")"

# 主目录下的路径写成 `~` 形式，同步到其他机器后仍然有效
case "$agents" in
  "$HOME"/*) import="@~${agents#"$HOME"}" ;;
  *)         import="@$agents" ;;
esac

mkdir -p "$(dirname "$claude_md")"

if [ ! -e "$claude_md" ]; then
  ln -s "$agents" "$claude_md"
  echo "link   $claude_md -> $agents"
elif [ "$claude_md" -ef "$agents" ]; then
  echo "skip   已指向同一文件"
elif cmp -s "$claude_md" "$agents"; then
  mv "$claude_md" "$claude_md.bak.$stamp"
  ln -s "$agents" "$claude_md"
  echo "link   $claude_md -> $agents，备份：$claude_md.bak.$stamp"
elif grep -qF "$import" "$claude_md"; then
  echo "skip   已有导入"
else
  case "$import" in
    *[[:space:]]*) echo "路径含空白字符，无法写成导入：$agents" >&2; exit 1 ;;
  esac
  cp "$claude_md" "$claude_md.bak.$stamp"
  # 经 cat 写回，CLAUDE.md 是软链时保留软链，也保留真实文件的权限
  tmp="$(mktemp)"
  { printf '%s\n\n' "$import"; cat "$claude_md"; } > "$tmp"
  cat "$tmp" > "$claude_md"
  rm "$tmp"
  echo "import $claude_md，备份：$claude_md.bak.$stamp"
fi
