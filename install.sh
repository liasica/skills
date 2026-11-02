#!/usr/bin/env bash
# 给没有 plugin 机制的 harness 用的兜底安装器
# Claude Code 与 Gemini CLI 请走各自的 plugin / extension 机制，见 README
#   本地仓库内执行：直接安装
#   curl 管道执行：先 clone 或 pull 再安装
# 把 skills 软链到探测到的每个 harness 的 skills 目录，
# 把检查器软链到 ~/.local/bin/check-punct，必要时将该目录写进 shell 配置
# 幂等，可重复执行；不修改任何 harness 的配置文件
set -euo pipefail

REPO_URL="${SKILLS_REPO:-https://github.com/liasica/skills.git}"
REPO_DIR="${SKILLS_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/liasica-skills}"
BIN="${XDG_BIN_HOME:-$HOME/.local/bin}"

# 取仓库：脚本自身在仓库里就地用，否则 clone 或 pull
SELF="${BASH_SOURCE[0]:-}"
if [ -n "$SELF" ] && [ -f "$SELF" ] && [ -d "$(dirname "$SELF")/skills" ]; then
  REPO="$(cd "$(dirname "$SELF")" && pwd)"
elif [ -d "$REPO_DIR/.git" ]; then
  git -C "$REPO_DIR" pull --ff-only -q
  REPO="$REPO_DIR"
  echo "pull  $REPO_DIR"
else
  mkdir -p "$(dirname "$REPO_DIR")"
  git clone -q "$REPO_URL" "$REPO_DIR"
  REPO="$REPO_DIR"
  echo "clone $REPO_DIR"
fi

# harness 的 skills 目录：装了 Codex 就用 ~/.agents/skills；追加目标用 SKILL_TARGETS 指定，空格分隔
CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
TARGETS=()
[ ! -d "$CODEX_DIR" ] || TARGETS+=("$HOME/.agents/skills")
if [ -n "${SKILL_TARGETS:-}" ]; then
  for extra in $SKILL_TARGETS; do TARGETS+=("$extra"); done
fi

# 清掉 Codex 弃用目录里指向本仓库的软链
for link in "$CODEX_DIR"/skills/*; do
  [ -L "$link" ] || continue
  case "$(readlink "$link")" in
    "$REPO"/skills/*) rm "$link"; echo "clean $link" ;;
  esac
done

installed=0
for target in ${TARGETS[@]+"${TARGETS[@]}"}; do
  mkdir -p "$target"
  for dir in "$REPO"/skills/*/; do
    name="$(basename "$dir")"
    link="$target/$name"
    if [ -e "$link" ] && [ ! -L "$link" ]; then
      echo "skip  $link（同名实体目录，未覆盖）"
      continue
    fi
    ln -sfn "${dir%/}" "$link"
  done
  echo "link  $target"
  installed=$((installed + 1))
done
[ "$installed" -gt 0 ] || echo "warn  没有探测到 harness，用 SKILL_TARGETS 指定 skills 目录"

# 检查器，harness 无关
mkdir -p "$BIN"
chmod +x "$REPO/hooks/check-punct.py"
ln -sfn "$REPO/hooks/check-punct.py" "$BIN/check-punct"
echo "link  $BIN/check-punct"

# PATH：不在就写进登录 shell 的配置文件
case ":${PATH}:" in
  *":$BIN:"*) ;;
  *)
    case "${SHELL:-}" in
      */zsh)  RC="$HOME/.zshrc" ;;
      */bash) RC="$HOME/.bashrc"; [ -f "$RC" ] || RC="$HOME/.bash_profile" ;;
      */fish) RC="$HOME/.config/fish/config.fish" ;;
      *)      RC="$HOME/.profile" ;;
    esac
    mkdir -p "$(dirname "$RC")"
    if grep -qs "$BIN" "$RC"; then
      echo "path  $RC 已有 $BIN，重开终端后生效"
    elif [ "${RC##*/}" = 'config.fish' ]; then
      printf '\n# check-punct\nfish_add_path %s\n' "$BIN" >> "$RC"
      echo "path  已写入 $RC，重开终端后生效"
    else
      printf '\n# check-punct\nexport PATH="%s:$PATH"\n' "$BIN" >> "$RC"
      echo "path  已写入 $RC，重开终端后生效"
    fi
    ;;
esac

echo
echo "完成"
