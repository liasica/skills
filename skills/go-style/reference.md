# Golang 规范整理

基于 `~/Golang规范.html` 整理，并作为后续 Go 任务的主版本维护。

后续在任何 Go 项目中，默认按本文件执行。

如果项目级记忆对默认项有明确覆盖，或补充了更严格约束，则优先按项目约定执行。

优先级：用户指令 > 项目级记忆 > 本文件。

## 一、规范正文

### 1. 命名规范

规则说明：

- 命名必须符合真实业务语义。
- 禁止不同业务对象使用相同命名。
- 单数语义禁止使用复数命名。
- 同一作用域内，一个变量名只表达一个明确含义。
- 不允许为了省事过度缩写变量名。
- 当有包名冲突的时候，可缩写至2-3个字符。

说明原因：

- 看到名字就应当能判断对象的业务含义，减少二次猜测。
- 同名异义和过度缩写会显著增加维护成本。
- 单复数混乱容易导致“单体”和“集合”语义被误用。

### 2. 空格、空行、格式规范

规则说明：

- 禁止无意义空格。
- 禁止字符串中出现无意义空格。
- 方法体开头和结尾禁止无意义空行。
- `return` 前可以按需要保留一个空行。
- `return` 后禁止再出现无意义空行。
- `if / else / switch` 代码块内部禁止无意义空行。
- 大段代码必须按逻辑分块。
- 不同逻辑块之间必须用空行分隔。
- 不同语义的代码块之间，除了分隔，还必须辅以说明性注释。

推荐写法：

函数体按逻辑块分隔：

```go
func buildProfile(ctx context.Context, userID int64) (*Profile, error) {
	user, err := getUser(ctx, userID)
	if err != nil {
		return nil, err
	}

	profile := assembleProfile(user)

	return profile, nil
}
```

字符串不带无意义空格：

```go
message := "I am a text"
```

不推荐写法：

函数体存在多余空行：

```go
func buildProfile(ctx context.Context, userID int64) (*Profile, error) {

	user, err := getUser(ctx, userID)
	if err != nil {

		return nil, err

	}
	profile := assembleProfile(user)
	return profile, nil

}
```

字符串中存在无意义前导空格：

```go
message := " I am a text"
```

说明原因：

- 无意义空格和空行会破坏代码的视觉层次。
- 逻辑分块依赖有意图的空行，而不是随意换行。
- 统一格式能显著提升扫读效率和代码评审效率。

### 3. 注释规范

规则说明：

- 注释必须清晰、详细、有逻辑。
- 禁止出现无意义空格。
- 标点符号必须正确使用，禁止重复标点。
- 注释内容要体现逻辑顺序和业务意图。
- 除非其他文件定义，否则注释一律默认使用中文，并且注释的结尾不要添加中文或英文的句号：`.` / `。`。
- **冒号样式**：半角 `:` 后必须有且仅有一个空格（如 `协议来源: docs/...`），全角 `：` 自带间距、前后均不再补空格。
- **同行多键值对**：一行内多个 `label: value` 之间用全角逗号 `，` 分隔，禁止用多个连续空格做"对齐"（例：`指令(ML): 0x27，方向: 平台 → 设备`，**不要**写成 `指令(ML):0x27   方向:平台 -> 设备`）。
- **多空格的合法用途**：仅允许在字段表 / 字节布局 / 编号列表中用连续空格做列对齐（如 `[0]  允许标识 1B,0x01 开启`），其他位置一律单空格。
- **箭头**：方向示意优先 `→`（U+2192），不用 `->`；除非引用代码字面量（如 Go 的 `chan<-`）。
- **中英 / 中数字间距**：可保留 1 个空格提高可读性，但不强制；同一段内保持一致。
- **中文标点**（`，`、`。`、`；`、`：`、`（）`）前后不加空格；半角标点（`,`、`.`、`;`、`:`）后加 1 个空格。
- **冒号前**：禁止留空格（写 `标题:` 而不是 `标题 :`），无论中英文。

推荐写法：

```go
// 先加载骑手信息，因为后续定价依赖骑手等级
riderProfile, err := riderRepository.GetByID(ctx, riderID)
if err != nil {
	return err
}
```

不推荐写法：

```go
//  Query rider   first，，，
// // then go on
riderProfile, err := riderRepository.GetByID(ctx, riderID)
if err != nil {
	return err
}
```

说明原因：

- 注释的价值是解释业务意图和执行顺序，而不是重复代码字面意思。
- 注释本身如果混乱，会比没有注释更误导读者。

### 4. 变量使用规范

规则说明：

- 同一作用域内，变量禁止重复声明。
- 如果某个变量已经声明过，后续必须复用该变量，不能再通过 `:=` 重新声明它。
- 典型场景是 `err`：如果前面已经声明了 `err`，后续其他函数返回了新参数，只声明新参数，再用 `=` 给已有 `err` 赋值。
- 已有明确含义的变量，不允许后续变成其他对象的容器。
- 错误变量名始终用 `err`，也即是：如果一个函数返回了 `error` 而 `err` 已被定义，不要重命名为 `xxxErr` 。

推荐写法：

已声明的 `err` 需要复用时，只声明新变量：

```go
a, err := someFunc()
if err != nil {
	return err
}

var b []byte
b, err = otherFunc()
if err != nil {
	return err
}
```

变量名始终保持同一业务含义：

```go
rawBody, err := io.ReadAll(resp.Body)
if err != nil {
	return err
}

userProfile, err := decodeUserProfile(rawBody)
if err != nil {
	return err
}
```

error变量名始终为 `err`：

```go
userJSON, err := marshalUser(user)
if err != nil {
	return err
}

var auditJSON []byte
auditJSON, err = marshalAudit(auditLog)
if err != nil {
	return err
}
```

不推荐写法：

同一作用域内重复声明已有变量：

```go
a, err := someFunc()
if err != nil {
	return err
}

b, err := otherFunc()
if err != nil {
	return err
}
```

把已有明确含义的变量复用成别的对象容器：

```go
var userJSON []byte

userJSON, err = marshalUser(user)
if err != nil {
	return err
}

userJSON, err = marshalAudit(auditLog)
if err != nil {
	return err
}
```

已有的error变量改名为其他非`err`变量名：

```go
userJSON, err := marshalUser(user)
if err != nil {
	return err
}

auditJSON, auditErr := marshalAudit(auditLog)
if auditErr != nil {
	return err
}
```

说明原因：

- 同一作用域重复声明会制造隐藏 bug，也会让变量生命周期变得不清晰。
- `err` 反复用 `:=` 重声明，是 Go 代码里非常常见的维护陷阱。
- 变量名一旦有了明确语义，就不应该再拿去承载别的对象。

### 5. 代码组织规范

规则说明：

- 大量代码堆积时，必须拆分代码块。
- 函数体上下文需要清晰分割。
- 初始化块、条件分支块、核心业务块、收尾块之间必须有分隔。
- 大范围重复代码禁止出现，应抽取公共逻辑。
- 低层级包禁止引用高层级包，依赖方向必须清晰。

推荐写法：

逻辑块分层清晰：

```go
func BuildOrderSummary(ctx context.Context, orderID int64) (*OrderSummary, error) {
	// 先加载订单基础数据
	order, err := orderRepository.GetByID(ctx, orderID)
	if err != nil {
		return nil, err
	}

	// 再组装订单摘要字段
	summary := assembleOrderSummary(order)

	return summary, nil
}
```

重复逻辑抽成公共函数：

```go
func fillAuditFields(model *AuditModel, operatorID int64) {
	model.UpdatedBy = operatorID
	model.UpdatedAt = time.Now()
}
```

低层包仅依赖稳定基础包：

```go
package repository

import "context"
```

不推荐写法：

不同语义的逻辑挤在一起，没有分块：

```go
func BuildOrderSummary(ctx context.Context, orderID int64) (*OrderSummary, error) {
	order, err := orderRepository.GetByID(ctx, orderID)
	if err != nil {
		return nil, err
	}
	summary := assembleOrderSummary(order)
	sendMetric("order_summary")
	return summary, nil
}
```

同类字段赋值在多个地方反复复制：

```go
order.UpdatedBy = operatorID
order.UpdatedAt = time.Now()

rider.UpdatedBy = operatorID
rider.UpdatedAt = time.Now()

user.UpdatedBy = operatorID
user.UpdatedAt = time.Now()
```

低层包反向依赖高层包：

```go
package repository

import (
	"context"
	"memora/internal/service"
)
```

说明原因：

- 逻辑块分明后，函数的执行路径和职责边界更清楚。
- 重复代码越多，后续修改越容易漏改。
- 依赖方向稳定，才能避免包循环和层次污染。

### 6. JSON / Map 规范

规则说明：

- JSON 的 key 禁止使用中文。
- 包括代码中生成的 JSON 字符串，key 也禁止使用中文。
- Go 中固化的 map key 禁止使用中文。
- 临时性的 map key 可以酌情放宽。

推荐写法：

```go
payload := map[string]any{
	"user_name": "liasica",
	"status":    "active",
}
```

不推荐写法：

```go
payload := map[string]any{
	"用户名": "liasica",
	"状态":  "active",
}
```

说明原因：

- JSON 和固化 map key 往往会进入接口、日志、存储或跨系统通信。
- 一旦 key 使用中文，后续兼容性、检索性和统一性都会变差。
- 使用英文 key 更适合长期维护和系统集成。

### 7. 返回值规范

规则说明：

- 如果函数使用了命名返回值，并且该命名返回值已经被赋值，则不要再直接返回具体值。
- 这类场景应当给命名返回值赋值后直接 `return`。

推荐写法：

```go
func (s *RiderService) CodeToOpenID(ctx context.Context, req *dto.WeappOpenidRequest) (res *dto.WeappOpenidResponse, err error) {
	res, err = s.codeToOpenID(ctx, req)
	if err != nil {
		return
	}

	return
}
```

不推荐写法：

```go
func (s *RiderService) CodeToOpenID(ctx context.Context, req *dto.WeappOpenidRequest) (res *dto.WeappOpenidResponse, err error) {
	res, err = s.codeToOpenID(ctx, req)
	if err != nil {
		return nil, err
	}

	return res, nil
}
```

说明原因：

- 既然已经使用命名返回值，就应该保持返回风格一致。
- 再次显式返回具体值，会让读者误以为这里存在特殊返回逻辑。
- 统一写法能减少维护时对返回路径的判断成本。

### 8. 函数调用入参格式规范

规则说明：

- 3 个及以内参数：全部写在同一行。
- 超过 3 个参数：开括号后立即换行，每个参数单独一行，最后一个参数以逗号结尾，闭括号单独一行。
- 禁止「半换行」写法：部分参数留在开括号同一行、剩下的参数另起一行。
- 适用于所有「括号包参数」场景：函数调用、ent 链式调用（`Where` / `Update` / `Delete` / `HasXxxWith`）、构造函数 `&Struct{...}`、`map` / `slice` 字面量等。

推荐写法：

3 个及以内参数同行：

```go
q.Where(litigationoverdueitem.SourceType(s), litigationoverdueitem.SourceID(id)).First(ctx)
```

超过 3 个参数全部换行且末尾保留逗号：

```go
return NewLitigationProgress().CreateBySystem(
    ctx,
    caseID,
    definition.LitigationProgressNodeAutoRemoved,
    "关联逾期已结清，自动删除",
    map[string]any{"sourceType": sourceType, "sourceId": sourceID},
)
```

不推荐写法：

部分参数留在开括号同一行：

```go
return NewLitigationProgress().CreateBySystem(ctx, caseID,
    definition.LitigationProgressNodeAutoRemoved,
    "关联逾期已结清，自动删除",
    map[string]any{"sourceType": sourceType, "sourceId": sourceID})
```

ent `Where` 半换行：

```go
q.Where(litigationoverdueitem.SourceType(s),
    litigationoverdueitem.SourceID(id)).First(ctx)
```

说明原因：

- 视觉对齐让函数边界一目了然，便于扫读。
- 末尾 trailing comma 让后续增删参数时只产生一行 diff。
- 与 `gofmt` 输出风格一致，避免格式工具反复回滚。

### 9. Writer 输出与错误处理规范

规则说明：

- 向 `io.Writer`（`strings.Builder` / `bytes.Buffer` / `http.ResponseWriter` / `os.File` / `io.Pipe` 等）写入时，`fmt.Fprintf` / `fmt.Fprintln` / `fmt.Fprint` 一律写成 `_, _ = fmt.Fprintf(w, ...)`，显式丢弃 `(n int, err error)`。
- 禁止 `b.WriteString(fmt.Sprintf(...))` 这种「Builder + Sprintf」双层封装写法，会被 staticcheck `QF1012` 标红；直接用 `_, _ = fmt.Fprintf(&b, ...)`。
- 例外：`strings.Builder.WriteString` / `WriteByte` / `bytes.Buffer.WriteString` 等本身就保证返回 nil 错误的方法，直接调用即可，不必加 `_, _ =`。
- 真实 IO writer（文件、网络、`http.ResponseWriter`）的 `Write*` 错误一般也用 `_, _ =` 丢弃即可；如果业务上需要感知失败（落盘、回写客户端），改成显式 `if _, err := w.Write(...); err != nil { ... }` 处理。

推荐写法：

```go
var b strings.Builder

_, _ = fmt.Fprintf(&b, "SnapshotAt: %s (unix=%d)\n", ts, snapshotAt)

b.WriteString("(no stations)\n")
```

不推荐写法 — 包装 Sprintf 再 WriteString（staticcheck QF1012 报错）：

```go
b.WriteString(fmt.Sprintf("SnapshotAt: %s (unix=%d)\n", ts, snapshotAt))
```

不推荐写法 — 裸调 Fprintf 留下未处理 error（IDE / errcheck 标红）：

```go
fmt.Fprintf(&b, "SnapshotAt: %s (unix=%d)\n", ts, snapshotAt)
```

说明原因：

- `fmt.Fprintf` 比 `WriteString + Sprintf` 少一次中间字符串分配，可读性与性能都更好。
- 项目里 lint 通常同时启用 `errcheck` 与 `staticcheck`：裸 `fmt.Fprintf` 会触发未处理 error，`WriteString(fmt.Sprintf(...))` 会触发 QF1012，`_, _ = fmt.Fprintf(...)` 是两者都接受的折中。
- 一处写法统一，避免「这里 `_, _ =`、那里裸调、又有 `WriteString(Sprintf(...))`」三种风格并存。

## 二、精简版规则清单

以下规则作为后续写 Go 代码时的默认硬性规则：

1. 命名必须贴合业务语义，不允许含糊缩写，不允许同名表达不同对象。
2. 单数对象不用复数命名，不同对象不用同一个名字。
3. 禁止无意义空格、空行、重复标点和脏格式。
4. 代码必须按逻辑分块，不同语义块之间必须空行分隔。
5. 大块逻辑必须加注释说明，除非其他文件定义，否则默认使用中文，注释的结尾不要添加 `.` 或 `。`。
6. 同一作用域里的变量禁止重复声明；如果 `err` 已声明，后续只声明新变量并用 `=` 赋值。
7. 禁止大范围重复代码，能抽取就抽取。
8. 低层包不能依赖高层包，依赖方向必须稳定。
9. JSON key 和固化 map key 禁止使用中文。
10. 使用命名返回值时，赋值后不要再直接 `return nil, err` 这类具体值。
11. 函数调用入参 ≤3 个全部同行；>3 个开括号后立即换行、每参一行、末尾保留 trailing comma，禁止半换行。
12. `fmt.Fprintf` / `fmt.Fprintln` / `fmt.Fprint` 写入 io.Writer 一律 `_, _ = fmt.Fprintf(w, ...)`；禁止 `b.WriteString(fmt.Sprintf(...))` 双层封装。
13. 写出来的代码要优先满足可读性、可维护性和逻辑清晰度。

## 三、后续执行约定

从现在开始：

- 我在任何 Go 项目中默认遵循本规范。
- 如果项目级记忆对默认项有明确覆盖，或补充了更严格规范，则优先按项目约定执行。
- 如果用户要求与本规范冲突，我会先指出冲突点，再按用户最终指令执行。

## 四、更新规范的方法

以后如果你要更新这套规范，按下面的方法处理：

1. 先更新本文件 `~/Golang规范.md`，它是规范的主版本。
2. 如果 Go 规范的触发条件、优先级或入口发生变化，再同步更新全局记忆文件 `~/AGENTS.md`。
3. `~/.codex/AGENTS.md` 和 `~/.claude/CLAUDE.md` 应保持指向 `~/AGENTS.md` 的软链，不单独维护内容。
4. 如果精简规则、触发条件或执行方式发生变化，再同步更新 skill 文件 `~/.codex/skills/go-style/SKILL.md`。
5. 开一个新会话，或者让我明确执行一次“同步 Go 规范记忆”，确保后续任务按最新版生效。
