---
name: project-init
description: 初始化新项目或新建 git 仓库时使用。建立 AGENTS.md 正本与 CLAUDE.md 导入、master 默认分支、自包含 .gitignore。
---

# 项目初始化

## 仓库

```bash
git init -b master
```

工具默认建了 `main` 就重命名为 `master`，推远程同样以 `master` 为默认分支。

## 项目记忆

`AGENTS.md` 是正本，`CLAUDE.md` 只有一行 `@AGENTS.md` 导入，只维护正本，两者都纳入版本控制：

```bash
echo '@AGENTS.md' > CLAUDE.md
```

Windows 上在 PowerShell 里执行（PowerShell 5.1 的 `>` 会写成 UTF-16）：

```powershell
[IO.File]::WriteAllText("$PWD\CLAUDE.md", "@AGENTS.md`n")
```

`AGENTS.md` 只写从代码和 git 历史里读不出来的内容：项目目标、应用划分、技术栈与版本、关键约束与安全边界、开发约定。能从代码直接读出的目录结构不要抄进去。

## .gitignore

按项目语言、框架与所用工具补齐：构建产物、依赖目录、本地配置与密钥、编辑器与系统文件、缓存。目标是仓库自包含，不依赖个人全局忽略配置。
