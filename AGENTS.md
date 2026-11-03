# liasica-skills

公开仓库，以 Claude Code plugin、Gemini CLI extension 与 `install.sh` 三种形式分发通用开发规范。

## 约定

- skill 与 `global-memory.md` 不写个人身份、服务器、内网地址与本机绝对路径
- `skills/merge-global-memory/global-memory.md` 是 `~/AGENTS.md` 的公开提炼版，通用规则变动时同步
- 增删 skill 时同步 `README.md` 与 `GEMINI.md` 的 skill 表，以及 `.claude-plugin/` 两个清单的描述
- `.claude-plugin/` 两个清单不写版本号，Claude Code 与 Gemini CLI 都按提交跟踪更新
- `hooks/hooks.json` 是 Claude Code 与 Gemini CLI 共用的默认路径，此路径不放文件；Claude Code 的 hook 配置为 `hooks/claude-hooks.json`
- `install.sh` 与 `install.ps1`、`link-claude-md.sh` 与 `link-claude-md.ps1` 行为对应，改动时同步
- `.ps1` 只用 ASCII 字符，注释与输出都写英文：带 BOM 时 `irm | iex` 报错，不带 BOM 时 Windows PowerShell 5.1 会读错非 ASCII 字符
- hook 命令在 Windows 上经 Git Bash 运行，脚本不依赖 `python3` 这个名字，用 `hooks/check-punct.sh` 探测可用的 Python
