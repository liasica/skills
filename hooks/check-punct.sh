#!/usr/bin/env bash
# 启动检查器。Windows 的 python3 可能只是 Microsoft Store 占位程序，要实际运行才能判断
for py in python3 python py; do
  if "$py" -c '' >/dev/null 2>&1 </dev/null; then
    exec "$py" "$(dirname "$0")/check-punct.py" "$@"
  fi
done
echo 'check-punct: 未找到可用的 Python' >&2
exit 1
