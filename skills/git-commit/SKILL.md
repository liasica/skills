---
name: git-commit
description: 写提交信息或 PR 描述时使用。规定 Conventional Commits 格式、禁止 AI 署名、提交身份与分支。
---

# 提交规范

## 格式

遵循 [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)：

```
<type>(<scope>): <描述>
```

type 取 `feat` `fix` `refactor` `perf` `docs` `style` `test` `build` `ci` `chore`，不兼容变更在 type 后加 `!`。描述用中文，按标点符号规范书写，结尾不加句号。

## 禁止 AI 署名

提交信息与 PR 描述里不得出现任何 AI 署名或工具标识，正文与 trailer 都不允许：

- `Co-Authored-By: Claude ...`
- `Generated with Claude Code`
- 机器人 emoji 前缀

## 身份与分支

- 作者与 committer 均使用全局记忆或 `git config` 中配置的身份
- 默认分支 `master`
- 全局记忆未授予长期授权时，未经明确指令不执行 `git commit` 与 `git push`
- 一次联动需求跨多仓时各仓库独立提交，不把多仓改动混进同一个提交
