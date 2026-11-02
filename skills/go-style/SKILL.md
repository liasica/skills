---
name: go-style
description: 写、改、重构或审查 Go 代码时使用。命名、空行分块、err 不重复声明、JSON key 不用中文、命名返回值、入参换行、Fprintf 返回值处理等硬性规则，以及提交前的 lint 检查。
---

# Go 规范

以下为默认硬性规则，完整细则见同目录 `reference.md`。

1. 命名贴合业务语义，不用含糊缩写，不同对象不用同一个名字，单数对象不用复数命名
2. 只在包名真冲突时才把变量缩写成 2 至 3 个字符
3. 同一作用域禁止重复声明。`err` 已声明时，后续只声明新变量再用 `=` 赋值：

   ```go
   var b []byte
   b, err = otherFunc()
   ```

4. 代码按逻辑分块，不同语义块之间空行分隔；禁止无意义空格、空行与重复标点
5. 大块逻辑加注释，除非其他文件另有约定否则用中文，注释结尾不加 `.` 或 `。`
6. 禁止大范围重复代码，能抽取就抽取
7. 低层包不依赖高层包，依赖方向保持稳定
8. JSON key 与固化的 map key 禁止使用中文
9. 用了命名返回值就在赋值后裸 `return`，不再返回 `nil, err` 这类具体值
10. 函数入参 3 个及以内全部同行；超过 3 个则开括号后立即换行、每行一个参数、末尾保留 trailing comma，禁止半换行
11. `fmt.Fprintf` / `Fprintln` / `Fprint` 写入 `io.Writer` 一律写成 `_, _ = fmt.Fprintf(w, ...)`；禁止 `b.WriteString(fmt.Sprintf(...))` 双层封装，staticcheck QF1012 会报
12. 可读性、可维护性与逻辑清晰优先于取巧

## 提交前

项目内有 `.golangci.yml` 时必须无 issue：

```bash
golangci-lint run --config .golangci.yml --new-from-rev=HEAD~1 --timeout=10m
```

本机有 `gclint`（带自定义规则的 golangci-lint 构建）时用它代替 `golangci-lint`。lint 的规则比本文更严且会直接报错，与本文冲突时以 lint 为准。
