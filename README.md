# SKILLS

通用开发规范，做成 skill 与检查器，支持 Claude Code、Gemini CLI、Codex。

## 安装

### Claude Code

```
/plugin marketplace add liasica/skills
/plugin install liasica-skills@liasica-skills
```

装到 `~/.claude/plugins/cache/` 标准位置，skills 与 hook 一并生效，不改动 `settings.json`。更新用 `/plugin update`。

### Gemini CLI

```bash
gemini extensions install https://github.com/liasica/skills
```

### Codex 与其他

没有 plugin 机制的 harness 用兜底脚本，把 skills 软链进它的 `skills/` 目录：

```bash
curl -fsSL https://raw.githubusercontent.com/liasica/skills/master/install.sh | bash
```

同一条命令负责安装和更新。默认克隆到 `~/.local/share/liasica-skills`，用 `SKILLS_DIR` 改；探测不到的 harness 用 `SKILL_TARGETS` 指定：

```bash
SKILL_TARGETS="$HOME/.foo/skills" curl -fsSL https://raw.githubusercontent.com/liasica/skills/master/install.sh | bash
```

脚本只建软链，不修改任何 harness 的配置文件。

## skills

Markdown + frontmatter，各 harness 通用。

| skill | 触发场景 |
| --- | --- |
| `project-init` | 初始化新项目或新建 git 仓库 |
| `git-commit` | 写提交信息或 PR 描述 |
| `github-actions` | 创建或修改工作流 |
| `superpowers-output` | 使用 superpowers 能力 |
| `go-style` | 写、改、重构或审查 Go 代码 |

## check-punct

检查中英文标点混用、注释块尾句末标点，以及工作流里的中文 `name:`。目录树、数学表达、单位、箭头和状态标记可使用规范符号。只报不改。

Claude Code 装了 plugin 后由 PostToolUse hook 自动跑，写文件后立即反馈。其他场景手动调：

```bash
check-punct path/to/file.go
find . -name '*.dart' -exec check-punct {} \;
```

覆盖 `.go` `.dart` `.ts` `.tsx` `.js` `.css` 的注释，以及 `.yaml` `.sh` `.sql` `.py` 的 `#` 与 `--` 注释。反引号内、`「」` 内、`[Foo]` doc 引用、URL、`TODO:`、`//go:embed`、端口号、CSS 属性名、函数调用括号都不参与检查。误报时在该行加 `punct-ignore` 豁免。

无违规时静默退出 0；有违规时输出带 `decision` 与 `reason` 的 JSON，便于接进别的 hook 体系。

## 自动生效

plugin 带一个 SessionStart hook，在会话启动、`/clear`、compact 之后注入一句硬要求：命中 skill 的场景必须先加载再动手，不许凭记忆作答。

注入内容只有一句约 160 字符，因为 skill 名与 description 本来就常驻在 skill 列表里，重复注入是浪费；缺的只是「必须加载」这条约束。

它把「得想起来有这个 skill」变成「开头就摆在面前」，是概率提升而非强制。真正的强制是检查器：标点靠 `check-punct` 在 PostToolUse 拦截，Go 靠 `gclint` 在提交前把关。

## 设计取舍

**什么该做 skill**：有明确触发场景、内容超过几行的流程。需要时加载，平时不占上下文。

**什么不该做 skill**：一两句话的规则——skill 的 description 本身就占了差不多的 token，还多一次调用。这类规则留在常驻记忆里更划算。

**什么该做检查器而非 skill**：与书写默认相反、事后不自查就发现不了的细粒度规则。中文注释结尾不加句号就是典型：写的时候极易被「中文句子写完加句号」的默认压过去。skill 只是换个地方存同一条指令，仍然靠自觉；检查器由工具强制执行。

检查器只覆盖代码文件里的注释。约束对话、文档正文与提交信息的标点规范仍应留在常驻记忆里，两者是分工。
