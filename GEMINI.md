# liasica-skills

通用开发规范。以下 skill 按场景触发，需要时读取对应的 `skills/<name>/SKILL.md`：

| skill | 触发场景 |
| --- | --- |
| `project-init` | 初始化新项目或新建 git 仓库 |
| `git-commit` | 写提交信息或 PR 描述 |
| `github-actions` | 创建或修改工作流 |
| `superpowers-output` | 使用 superpowers 能力 |
| `go-style` | 写、改、重构或审查 Go 代码 |
| `merge-global-memory` | 用户要求把 liasica 的全局记忆合并到自己的全局记忆 |

`hooks/check-punct.py <file>` 检查代码注释里的中英文标点混用与句末标点，只报不改。
