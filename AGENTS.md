# liasica-skills

公开仓库，以 Claude Code plugin、Gemini CLI extension 与 `install.sh` 三种形式分发通用开发规范。

## 约定

- skill 与 `global-memory.md` 不写个人身份、服务器、内网地址与本机绝对路径
- `skills/merge-global-memory/global-memory.md` 是 `~/AGENTS.md` 的公开提炼版，通用规则变动时同步
- 增删 skill 时同步 `README.md` 与 `GEMINI.md` 的 skill 表，以及 `.claude-plugin/` 两个清单的描述
- Claude Code 只在版本号变化时更新插件，推送 `skills/` 或 `hooks/` 的改动时同步提升 `.claude-plugin/plugin.json`、`.claude-plugin/marketplace.json` 与 `gemini-extension.json` 的版本号
