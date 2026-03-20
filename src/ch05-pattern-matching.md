# 第 5 章：模式匹配

## 5.1 模式概述

模式是 Rust 中强大的匹配工具，用于**解构**和**匹配**数据结构。

### 模式出现的地方

```rust
// 1. match 表达式
match value {
    pattern => expression,
}

// 2. if let
if let pattern = value {
    // ...
}

// 3. let 语句
let pattern = value;

// 4. 函数参数
fn func(pattern: Type) { }

// 5. for 循环
for pattern in iterator { }
```

## 5.2 字面量模式

```rust
fn main() {
    let number = 5;
    
    match number {
        1 => println!("一"),
        2 => println!("二"),
        3 | 4 | 5 => println!("三到五"),  // 多模式
        _ => println!("其他"),
    }
}
```

### 字符和字符串

```rust
fn main() {
    let ch = 'a';
    
    match ch {
        'a'..='z' => println!("小写字母"),
        'A'..='Z' => println!("大写字母"),
        '0'..='9' => println!("数字"),
        _ => println!("其他字符"),
    }
    
    let s = "hello";
    match s {
        "hello" => println!("问候"),
        "bye" => println!("告别"),
        _ => println!("其他"),
    }
}
```

## 5.3 变量模式

```rust
fn main() {
    let x = Some(5);
    let y = 10;
    
    match x {
        Some(5) => println!("五"),
        Some(y) => println!("其他值：{}", y),  // 新变量 y
        None => println!("无"),
    }
    
    println!("外层的 y = {}", y);  // 仍然是 10
}
```

### 匹配守卫

```rust
fn main() {
    let num = Some(4);
    
    match num {
        Some(x) if x < 5 => println!("小于 5: {}", x),
        Some(x) => println!("大于等于 5: {}", x),
        None => println!("无"),
    }
}
```

### @ 绑定

```rust
fn main() {
    let msg = Some("hello");
    
    match msg {
        Some(s @ "hello") => println!("找到问候：{}", s),
        Some(s) => println!("其他：{}", s),
        None => println!("无"),
    }
    
    // 范围 + @
    let n = 5;
    match n {
        n @ 1..=5 => println!("小数字：{}", n),
        n @ 6..=10 => println!("中数字：{}", n),
        _ => println!("大数字"),
    }
}
```

## 5.4 解构模式

### 元组解构

```rust
fn main() {
    let point = (3, 5);
    
    // let 语句
    let (x, y) = point;
    println!("({}, {})", x, y);
    
    // match
    match point {
        (0, 0) => println!("原点"),
        (0, y) => println!("在 Y 轴上：{}", y),
        (x, 0) => println!("在 X 轴上：{}", x),
        (x, y) => println!("其他位置：({}, {})", x, y),
    }
    
    // 忽略部分
    let (x, ..) = point;  // 只取第一个
    let (.., y) = point;  // 只取最后一个
}
```

### 结构体解构

```rust
struct Point {
    x: i32,
    y: i32,
}

fn main() {
    let p = Point { x: 10, y: 20 };
    
    // 完整解构
    let Point { x, y } = p;
    println!("({}, {})", x, y);
    
    // 重命名
    let Point { x: a, y: b } = p;
    
    // 部分解构
    let Point { x, .. } = p;
    println!("x = {}", x);
    
    // match 中使用
    match p {
        Point { x, y: 0 } => println!("在 X 轴：{}", x),
        Point { x: 0, y } => println!("在 Y 轴：{}", y),
        Point { x, y } => println!("其他：({}, {})", x, y),
    }
}
```

### 结构体简写

```rust
fn main() {
    let p = Point { x: 10, y: 20 };
    
    // 字段名和变量名相同
    let Point { x, y } = p;
    
    // 等价于
    let Point { x: x, y: y } = p;
}
```

### 枚举解构

```rust
enum Message {
    Quit,
    Move { x: i32, y: i32 },
    Write(String),
    ChangeColor(i32, i32, i32),
}

fn main() {
    let msg = Message::Move { x: 10, y: 20 };
    
    match msg {
        Message::Quit => println!("退出"),
        Message::Move { x, y } => println!("移动到 ({}, {})", x, y),
        Message::Write(text) => println!("文本：{}", text),
        Message::ChangeColor(r, g, b) => {
            println!("颜色：RGB({}, {}, {})", r, g, b)
        },
    }
}
```

## 5.5 嵌套模式

```rust
enum Color {
    Rgb(i32, i32, i32),
    Hsv(i32, i32, i32),
}

enum Message {
    Quit,
    Move { x: i32, y: i32 },
    Write(String),
    ChangeColor(Color),
}

fn main() {
    let msg = Message::ChangeColor(Color::Rgb(255, 0, 0));
    
    match msg {
        Message::ChangeColor(Color::Rgb(r, g, b)) => {
            println!("RGB: {}, {}, {}", r, g, b);
        },
        Message::ChangeColor(Color::Hsv(h, s, v)) => {
            println!("HSV: {}, {}, {}", h, s, v);
        },
        _ => println!("其他消息"),
    }
}
```

## 5.6 引用和模式

```rust
fn main() {
    let point = Box::new(Point { x: 10, y: 20 });
    
    // 解构 Box
    let Point { x, y } = *point;
    
    // 引用匹配
    let c = Some('x');
    match &c {
        Some(&ch) => println!("字符：{}", ch),
        None => println!("无"),
    }
    
    // 或
    match c {
        Some(ch) => println!("字符：{}", ch),
        None => println!("无"),
    }
}
```

## 5.7 忽略模式

### 使用 _

```rust
fn main() {
    let (x, _, z) = (1, 2, 3);  // 忽略中间值
    
    // 忽略多个
    let (a, .., b) = (1, 2, 3, 4, 5);
    println!("{} {}", a, b);  // 1 5
}
```

### 多个 _

```rust
fn main() {
    struct Point {
        x: i32,
        y: i32,
        z: i32,
    }
    
    let origin = Point { x: 0, y: 0, z: 0 };
    
    // 只匹配 x
    match origin {
        Point { x, .. } => println!("x = {}", x),
    }
    
    // 忽略整个值
    let _ = Some(5);  // 不绑定变量
}
```

## 5.8 实战示例

### 解析命令

```rust
enum Command {
    Move { x: i32, y: i32 },
    Draw { shape: String, color: String },
    Quit,
}

fn parse_command(input: &str) -> Option<Command> {
    match input.split_whitespace().collect::<Vec<_>>().as_slice() {
        ["move", x, y] => {
            Some(Command::Move {
                x: x.parse().ok()?,
                y: y.parse().ok()?,
            })
        },
        ["draw", shape, color] => {
            Some(Command::Draw {
                shape: shape.to_string(),
                color: color.to_string(),
            })
        },
        ["quit"] => Some(Command::Quit),
        _ => None,
    }
}

fn main() {
    let cmd = parse_command("move 10 20");
    match cmd {
        Some(Command::Move { x, y }) => println!("移动到 ({}, {})", x, y),
        _ => println!("无效命令"),
    }
}
```

### 配置解析

```rust
#[derive(Debug)]
enum ConfigValue {
    String(String),
    Number(i32),
    Boolean(bool),
    None,
}

fn get_config_value(key: &str) -> ConfigValue {
    match key {
        "host" => ConfigValue::String("localhost".to_string()),
        "port" => ConfigValue::Number(8080),
        "debug" => ConfigValue::Boolean(true),
        _ => ConfigValue::None,
    }
}

fn main() {
    let value = get_config_value("port");
    match value {
        ConfigValue::Number(n) => println!("端口：{}", n),
        _ => println!("不是数字"),
    }
}
```

## 5.9 match 的高级用法

### 返回值的 match

```rust
fn main() {
    let result = match 5 {
        1 => "一",
        2 => "二",
        n if n < 5 => "小数字",
        _ => "其他",
    };
    
    println!("{}", result);
}
```

### 链式方法调用

```rust
fn main() {
    let x = Some(5);
    
    let y = match x {
        Some(n) => n * 2,
        None => 0,
    };
    
    println!("{}", y);  // 10
}
```

## 5.10 练习题

1. 使用模式匹配解构嵌套的元组 `((1, 2), (3, 4))`
2. 创建一个表示 HTTP 请求的枚举，匹配不同的请求方法
3. 使用匹配守卫检查数字是否为正偶数
4. 解构包含 Option 的结构体

## 5.11 小结

- 模式用于匹配和解构数据
- match 强制穷尽性检查
- 可以使用守卫添加额外条件
- @ 语法同时绑定和匹配
- _ 用于忽略不需要的值
- 模式可以嵌套，处理复杂数据结构

---

[上一章：结构体和枚举 ←](04-structs-enums.md) | [下一章：错误处理 →](06-error-handling.md)
