# SKILLS

通用开发规范，做成 skill 与检查器，支持 Claude Code、Gemini CLI、Codex。

## 安装

### Claude Code

```
/plugin marketplace add liasica/skills
/plugin install liasica-skills@liasica-skills
```

装到 `~/.claude/plugins/cache/` 标准位置，skills 与 hook 一并生效，不改动 `settings.json`。更新用 `/plugin update`，按提交跟踪。检查器依赖 Python 3。

### Gemini CLI

```bash
gemini extensions install https://github.com/liasica/skills
```

extension 提供 skills 与上下文，不带 hook，检查器手动运行：`python3 hooks/check-punct.py <file>`。

同时运行了兜底脚本时，Gemini CLI 也会读取 `~/.agents/skills`，并提示 `Skill conflict detected`。两边内容相同，可以忽略。

### Codex 与其他

没有 plugin 机制的 harness 用兜底脚本，把 skills 软链进它的 skills 目录（Codex 为 `~/.agents/skills`）：

```bash
curl -fsSL https://raw.githubusercontent.com/liasica/skills/master/install.sh | bash
```

同一条命令负责安装和更新。默认克隆到 `~/.local/share/liasica-skills`，用 `SKILLS_DIR` 改；探测不到的 harness 用 `SKILL_TARGETS` 指定：

```bash
SKILL_TARGETS="$HOME/.foo/skills" curl -fsSL https://raw.githubusercontent.com/liasica/skills/master/install.sh | bash
```

脚本只建软链，不修改任何 harness 的配置文件。

### Windows

先安装 Git for Windows 和 Python 3。plugin 的 hook 经 Git Bash 运行，没有 Git for Windows 时不生效：

```powershell
winget install --id Git.Git -e
winget install --id Python.Python.3.14 -e
```

Claude Code 与 Gemini CLI 的安装命令同上。Codex 等没有 plugin 机制的 harness 在 PowerShell 里运行：

```powershell
irm https://raw.githubusercontent.com/liasica/skills/master/install.ps1 | iex
```

同一条命令负责安装和更新。脚本用 junction 接入 skills，不需要管理员权限或开发者模式，并把 `hooks` 目录写进用户 PATH，提供 `check-punct` 命令。默认克隆到 `%LOCALAPPDATA%\liasica-skills`，用 `SKILLS_DIR` 改；探测不到的 harness 用 `SKILL_TARGETS` 指定，多个路径用分号分隔。

| harness | 全局记忆 | skills |
| --- | --- | --- |
| Claude Code | `%USERPROFILE%\.claude\CLAUDE.md` | plugin |
| Codex | `%USERPROFILE%\.codex\AGENTS.md`，用 `CODEX_HOME` 改目录 | `%USERPROFILE%\.agents\skills` |
| Gemini CLI | `%USERPROFILE%\.gemini\GEMINI.md` | extension |

Claude Code 找不到 Git Bash 时，在 `%USERPROFILE%\.claude\settings.json` 里指定路径：

```json
{
  "env": {
    "CLAUDE_CODE_GIT_BASH_PATH": "C:\\Program Files\\Git\\bin\\bash.exe"
  }
}
```

按 `project-init` 建立的仓库里，`CLAUDE.md` 是指向 `AGENTS.md` 的软链。Git 未启用软链时，它会检出成内容只有 `AGENTS.md` 一行的普通文件，Claude Code 读不到项目记忆。在系统设置里打开开发者模式，再执行：

```powershell
git config --global core.symlinks true
```

已经克隆的仓库在根目录修复一次：

```powershell
git config core.symlinks true
Remove-Item CLAUDE.md
git checkout -- CLAUDE.md
```

在 WSL 里运行的 harness 按 Linux 处理，用 `install.sh` 与 `link-claude-md.sh`。WSL 的主目录与 Windows 相互独立。

## skills

Markdown + frontmatter，各 harness 通用。

| skill | 触发场景 |
| --- | --- |
| `project-init` | 初始化新项目或新建 git 仓库 |
| `git-commit` | 写提交信息或 PR 描述 |
| `github-actions` | 创建或修改工作流 |
| `superpowers-output` | 使用 superpowers 能力 |
| `go-style` | 写、改、重构或审查 Go 代码 |
| `merge-global-memory` | 用户要求把 liasica 的全局记忆合并到自己的全局记忆 |

## 合并全局记忆

`skills/merge-global-memory/global-memory.md` 收录一份通用的全局记忆：优先级、语言表达、工作方式、通用约定、标点符号与语言专项规则。

装好后对 agent 说「把 liasica 的全局记忆合并到我的全局记忆」，Claude Code 也可以直接运行 `/liasica-skills:merge-global-memory`。agent 会定位当前 harness 的全局记忆文件，逐条比对后列出新增与冲突，经你确认并备份后写入。可重复执行，已有的规则会跳过。

## 接入已有的 AGENTS.md

本机已有全局 `AGENTS.md` 时，用 `link-claude-md.sh` 让 Claude Code 也读取它：

```bash
curl -fsSL https://raw.githubusercontent.com/liasica/skills/master/link-claude-md.sh | bash
```

默认读取 `${CODEX_HOME:-~/.codex}/AGENTS.md`，其他位置作为参数传入：

```bash
curl -fsSL https://raw.githubusercontent.com/liasica/skills/master/link-claude-md.sh | bash -s -- /path/to/AGENTS.md
```

| `~/.claude/CLAUDE.md` 现状 | 处理 |
| --- | --- |
| 不存在 | 软链到 `AGENTS.md` |
| 内容与 `AGENTS.md` 相同 | 备份后软链 |
| 内容不同 | 备份后在开头加 `@` 导入，原内容不动 |
| 已是软链或已有导入 | 不处理 |

可重复执行。运行后在 Claude Code 里用 `/memory` 查看加载结果。

Windows 在 PowerShell 里运行。这个版本不建软链，`CLAUDE.md` 不存在或内容相同时都写成一行 `@` 导入：

```powershell
irm https://raw.githubusercontent.com/liasica/skills/master/link-claude-md.ps1 | iex
```

其他位置作为参数传入：

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/liasica/skills/master/link-claude-md.ps1))) C:\path\AGENTS.md
```

- 导入后两份文件同时加载，互相矛盾的规则需要手动处理
- 主目录以外的路径部分含空白字符时无法写成导入，脚本报错退出，不改动文件
- 正本放在主目录（`~/AGENTS.md`）时，在没有 `CLAUDE.md` 的仓库里会加载两次
- 桌面端的 Cowork 会话不加载工作目录外的导入，也不加载软链的 `~/.claude/CLAUDE.md`

## check-punct

检查中英文标点混用、注释块尾句末标点，以及工作流里的中文 `name:`。目录树、数学表达、单位、箭头和状态标记可使用规范符号。只报不改。

Claude Code 装了 plugin 后由 PostToolUse hook 自动跑，写文件后立即反馈。其他场景手动调：

```bash
check-punct path/to/file.go
find . -name '*.dart' -exec check-punct {} \;
```

Windows 上由 `install.ps1` 提供，在 PowerShell 或 cmd 里调用 `check-punct path\to\file.go`。

覆盖 `.go` `.dart` `.ts` `.tsx` `.js` `.jsx` `.css` `.java` `.kt` `.swift` `.rs` `.c` `.h` `.cpp` 的注释，以及 `.yaml` `.yml` `.sh` `.bash` `.zsh` `.py` `.toml` `.ps1` 的 `#` 注释和 `.sql` 的 `#` 与 `--` 注释，均含行尾注释。反引号内、`「」` 内、`[Foo]` doc 引用、URL、`TODO:`、`//go:embed`、端口号、CSS 属性名、函数调用括号都不参与检查。误报时在该行加 `punct-ignore` 豁免。

无违规时静默退出 0；有违规时输出带 `decision` 与 `reason` 的 JSON，便于接进别的 hook 体系。

## 自动生效

Claude Code plugin 带一个 SessionStart hook，在会话启动、`/clear`、compact 之后注入一句硬要求：命中 skill 的场景必须先加载再动手，不许凭记忆作答。

注入内容只有一句约 160 字符，因为 skill 名与 description 本来就常驻在 skill 列表里，重复注入是浪费；缺的只是「必须加载」这条约束。

它把「得想起来有这个 skill」变成「开头就摆在面前」，是概率提升而非强制。真正的强制是检查器：标点靠 `check-punct` 在 PostToolUse 拦截，Go 靠 lint 在提交前把关。

## 设计取舍

**什么该做 skill**：有明确触发场景、内容超过几行的流程。需要时加载，平时不占上下文。

**什么不该做 skill**：一两句话的规则——skill 的 description 本身就占了差不多的 token，还多一次调用。这类规则留在常驻记忆里更划算。

**什么该做检查器而非 skill**：与书写默认相反、事后不自查就发现不了的细粒度规则。中文注释结尾不加句号就是典型：写的时候极易被「中文句子写完加句号」的默认压过去。skill 只是换个地方存同一条指令，仍然靠自觉；检查器由工具强制执行。

检查器只覆盖代码文件里的注释。约束对话、文档正文与提交信息的标点规范仍应留在常驻记忆里，两者是分工。
