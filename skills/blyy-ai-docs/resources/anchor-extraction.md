# Anchor Extraction — 8 语言符号定位与 body 提取

> **何时读取**：
> - Mode A Phase A5（写 MANIFEST 时计算 `body_sha256`）
> - Mode B Phase B1（Tier 3 符号级失效检测）
> - Mode C Phase C0（全量锚点验证）
>
> **目的**：把 `[file#Symbol]` 锚点解析成"代码行范围 + 归一化签名 + body sha256"。本文件是**机械算法手册**，不含设计讨论。

## 通用流程

```
input:  file_path, symbol_name, language
output: { found: bool, line_start, line_end, signature, body_sha256 }

steps:
1. 用 language-specific 正则在 file_path 中定位 symbol_name 的声明行
2. 从声明行向下扫描，找到 body 的开闭符号（{ } / def: / class: / pub fn ... { ... }）
3. 提取 [line_start, line_end] 范围
4. 把 body 文本归一化（去注释、去末尾空白），写入临时文件
5. body_sha256 = git hash-object <临时文件>
6. signature = 声明行去除注释/空白后的字符串
```

> 实现注意：所有文件读取采用流式 `head -n {line_end} | tail -n +{line_start}`，避免把整文件载入内存。
>
> body_sha256 用 `git hash-object` 而非 `sha256sum`——zero-dependency、跨平台、与 git 自身的对象哈希一致。

---

## 一、C# / .NET

### 类 / 接口 / record

```regex
^\s*(public|internal|protected|private)?\s*(static\s+)?(abstract\s+|sealed\s+)?(partial\s+)?(class|interface|record|struct)\s+{{NAME}}\b
```

### 方法

```regex
^\s*(public|internal|protected|private)?\s*(static\s+)?(virtual\s+|override\s+|async\s+)*[\w<>,\s\?\[\]]+\s+{{NAME}}\s*\(
```

### body 范围

C# 用 `{` `}` 配对。从声明行开始扫描，记录大括号层级：第一个 `{` 时层级 +1，最后一个 `}` 层级归零时即为 `line_end`。

### partial class 特殊处理

`partial class Foo` 可能跨多文件——同名符号出现在 ≥ 2 个文件时，每个文件单独算一条 anchor 记录，`signature` 字段加上文件路径前缀消歧。

---

## 二、Java / Kotlin

### 类 / 接口

```regex
^\s*(public\s+|protected\s+|private\s+)?(abstract\s+|final\s+|sealed\s+)?(static\s+)?(class|interface|enum|record)\s+{{NAME}}\b
```

### 方法

```regex
^\s*(public|protected|private)?\s*(static\s+|final\s+|abstract\s+|synchronized\s+|default\s+)*[\w<>,\s\?\[\]]+\s+{{NAME}}\s*\(
```

### body 范围

同 C#：`{` `}` 配对。注意忽略字符串字面量中的 `{` `}`。

---

## 三、Python

### 类

```regex
^\s*class\s+{{NAME}}\s*[\(:]
```

### 函数 / 方法

```regex
^\s*(async\s+)?def\s+{{NAME}}\s*\(
```

### body 范围

Python 靠**缩进**而非大括号。算法：

1. 记录声明行的缩进数 `base_indent`
2. 从下一行开始扫描，跳过空行 / 纯注释行
3. 遇到第一个**非空且缩进 ≤ base_indent** 的行 → 该行 -1 即为 `line_end`
4. EOF → `line_end = 文件总行数`

### 装饰器

`@decorator` 行**不计入** body，但 `signature` 字段应当包含装饰器名以便检测装饰器变化（装饰器变 → signature 变 → STALE 触发）。

---

## 四、Go

### 函数

```regex
^func\s+(\(\w+\s+\*?\w+\)\s+)?{{NAME}}\s*\(
```

### struct / interface / type

```regex
^type\s+{{NAME}}\s+(struct|interface|=)\s*\{?
```

### body 范围

Go 用 `{` `}` 配对。**type alias**（`type X = Y`）无 body → `line_end = line_start`。

### 方法接收者消歧

`func (r *Receiver) Method()` 与 `func Method()` 同名时，`signature` 字段必须包含接收者类型，避免冲突。

---

## 五、TypeScript / JavaScript

### 类 / 接口

```regex
^\s*(export\s+)?(default\s+)?(abstract\s+)?(class|interface|type|enum)\s+{{NAME}}\b
```

### 函数

```regex
^\s*(export\s+)?(default\s+)?(async\s+)?function\s+{{NAME}}\s*[<\(]
```

### const arrow function

```regex
^\s*(export\s+)?const\s+{{NAME}}\s*[:=]
```

### body 范围

`{` `}` 配对，但**arrow function** 可能没有 body 块（`const x = () => 42`）。算法：

1. 找到声明行
2. 若声明行包含 `{` → 走大括号配对
3. 若声明行以 `;` 结束或不含 `{` → `line_end = line_start`（单行符号）

### JSX 处理

JSX 标签 `<Foo>...</Foo>` 不参与大括号配对，但 `{expr}` 内嵌表达式参与——需要简单的标签栈跟踪。v0.1 简化：JSX 区块按整体跳过，不递归。

---

## 六、Rust

### struct / enum / trait

```regex
^(pub\s+(\([^)]*\)\s+)?)?(struct|enum|trait|union|type)\s+{{NAME}}\b
```

### fn

```regex
^(pub\s+(\([^)]*\)\s+)?)?(async\s+|const\s+|unsafe\s+)*fn\s+{{NAME}}\s*[<\(]
```

### impl 块

`impl Foo` / `impl Trait for Foo` → 不算独立 anchor，里面的 fn 才是。

### body 范围

`{` `}` 配对。注意 Rust 的 `where` 子句可能跨多行——签名提取需读到第一个 `{` 为止。

---

## 七、Ruby

### 类 / 模块

```regex
^\s*(class|module)\s+{{NAME}}\b
```

### 方法

```regex
^\s*def\s+(self\.)?{{NAME}}\b
```

### body 范围

Ruby 用 `end` 关键字。算法：

1. 从声明行开始，维护 "block 深度" 计数
2. 每遇到 `class` / `module` / `def` / `do` / `if` / `case` / `begin` / `while` 开头的行 → 深度 +1
3. 每遇到 `end` 单独成词的行 → 深度 -1
4. 深度归零时该 `end` 行即为 `line_end`

> Ruby 多关键字嵌套时正则容易出错——v0.1 简化：直接用 ruby `--ast` (如可用) 或 `ripper` ；缺失时降级到 `end` 计数 + 提示用户精度可能下降。

---

## 八、PHP

### 类 / 接口

```regex
^\s*(abstract\s+|final\s+)?(class|interface|trait|enum)\s+{{NAME}}\b
```

### 方法

```regex
^\s*(public|protected|private)?\s*(static\s+|abstract\s+|final\s+)*function\s+{{NAME}}\s*\(
```

### body 范围

`{` `}` 配对，规则同 C#。

---

## 通用：归一化与 signature

### body 归一化（用于 sha256）

1. 去除单行注释（`//`、`#`、`--`，按语言）
2. 去除多行注释 `/* ... */`、`""" ... """`
3. 去除每行首尾空白
4. 去除空行
5. 保留缩进结构（仅 Python 需要）

### signature 提取

1. 取声明行（含装饰器）
2. 同样做注释剥离
3. 多行签名（参数列表换行）→ 拼接成一行后保存
4. 截断到 ≤ 200 字符（超长签名只用前 200 字符，足以检测变化）

---

## 失败模式与降级

| 失败 | 处理 |
|------|------|
| 正则未匹配（符号不存在） | 该 anchor 标记为 **MISSING** → 引用此 anchor 的 doc 全部 STALE |
| 多个匹配（重载 / 同名） | 优先使用 `[file#Symbol(ParamType)]` 形式消歧；仍冲突 → 取第一个并记入 INIT-AI-REPORT |
| body 跨 1000+ 行 | 截取前 200 行做 body_sha256 + 签名；标 `partial: true` 提示 AI |
| 文件二进制 / 不可读 | 跳过该文件 anchor；记入 STALE |
| 语言未在本文件覆盖 | 退化为**文件级 anchor**（仅 path + sha256），不做符号级跟踪 |

---

## 给 Phase A5 / B1 / C0 的实现伪代码

```
function extract_anchor(file_path, symbol_name):
    lang = detect_language(file_path)
    if lang not in SUPPORTED:
        return file_only_anchor(file_path)

    content = read_file(file_path)
    decl_match = find_declaration(content, symbol_name, lang)
    if decl_match is None:
        return { found: false }

    line_start = decl_match.line
    line_end = find_body_end(content, line_start, lang)
    body = normalize(content[line_start..line_end], lang)
    signature = normalize_signature(content[line_start], lang)

    return {
        found: true,
        line_start, line_end,
        signature,
        body_sha256: git_hash_object(body)
    }
```

> 实现时注意：**不要**把整个文件 dump 到子代理上下文——按行流式读，找到 `line_end` 立即停止扫描。
