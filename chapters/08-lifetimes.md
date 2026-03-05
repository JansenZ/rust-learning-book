# 第 8 章：生命周期

## 8.1 什么是生命周期？

生命周期是**引用的有效作用域**。Rust 使用生命周期确保引用不会变成悬垂引用。

```rust
{
    let x = 5;      // x 的生命周期开始
    let r = &x;     // r 借用 x
    println!("{}", r);
}                   // x 和 r 都离开作用域
```

## 8.2 生命周期注解

### 基本语法

```rust
// &i32        - 引用
// &'a i32     - 带有生命周期的引用
// &'a mut i32 - 带有生命周期的可变引用
```

### 函数中的生命周期

```rust
// 错误：编译器无法推断
// fn longest(x: &str, y: &str) -> &str {
//     if x.len() > y.len() { x } else { y }
// }

// 正确：添加生命周期注解
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() {
        x
    } else {
        y
    }
}

fn main() {
    let s1 = String::from("long");
    let s2 = String::from("short");
    
    let result = longest(&s1, &s2);
    println!("更长的是：{}", result);
}
```

### 生命周期含义

```rust
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str
```

含义：**返回值的生命周期与 x 和 y 中较短的那个相同**

## 8.3 生命周期规则

### 规则 1：省略规则

```rust
// 每个引用参数获得独立的生命周期
fn first_word(s: &str) -> &str {
    // 实际是：fn first_word<'a>(s: &'a str) -> &'a str
    let bytes = s.as_bytes();
    for (i, &item) in bytes.iter().enumerate() {
        if item == b' ' {
            return &s[0..i];
        }
    }
    s
}
```

### 规则 2：一个输入生命周期

```rust
// 如果只有一个输入生命周期，它被赋值给所有输出
fn first_word(s: &str) -> &str {
    // 输入生命周期自动赋值给输出
}
```

### 规则 3：&self 和 &mut self

```rust
impl<'a> MyStruct<'a> {
    // self 的生命周期自动推断
    fn method(&self) -> &str {
        // ...
    }
}
```

## 8.4 结构体中的生命周期

```rust
struct ImportantExcerpt<'a> {
    part: &'a str,
}

fn main() {
    let novel = String::from("Rust 编程...");
    let first_sentence = novel.split('.').next().unwrap();
    
    let excerpt = ImportantExcerpt {
        part: first_sentence,
    };
    
    println!("摘录：{}", excerpt.part);
}
```

### 方法实现

```rust
impl<'a> ImportantExcerpt<'a> {
    fn level(&self) -> i32 {
        3
    }
    
    fn announce_and_return_part(&self, announcement: &str) -> &str {
        println!("通知：{}", announcement);
        self.part
    }
}
```

## 8.5 静态生命周期

```rust
// 'static: 程序整个运行期间都有效
let s: &'static str = "字符串字面量";

// 所有字符串字面量都有 'static 生命周期
fn main() {
    let greeting = "Hello";  // &'static str
}

// 注意：'static 不意味着"永远"，而是"程序运行期间"
```

## 8.6 生命周期约束

### 约束语法

```rust
// T 必须存活至少 'a 这么久
fn process<T>(data: &'a T) 
where 
    T: 'a + Display 
{
    // ...
}
```

### 多个约束

```rust
fn process<T, U>(t: &'a T, u: &'b U) 
where 
    T: 'a + Display,
    U: 'b + Debug,
    'a: 'b,  // 'a 至少和 'b 一样长
{
    // ...
}
```

## 8.7 复杂示例

### 返回引用的结构体方法

```rust
struct Parser<'a> {
    input: &'a str,
}

impl<'a> Parser<'a> {
    fn new(input: &'a str) -> Self {
        Parser { input }
    }
    
    fn parse(&self) -> &'a str {
        self.input.trim()
    }
}

fn main() {
    let text = String::from("  hello  ");
    let parser = Parser::new(&text);
    let result = parser.parse();
    println!("解析结果：{}", result);
}
```

### 持有引用的枚举

```rust
enum Cow<'a> {
    Borrowed(&'a str),
    Owned(String),
}

impl<'a> Cow<'a> {
    fn to_owned(&self) -> Cow<'a> {
        match self {
            Cow::Borrowed(s) => Cow::Owned(s.to_string()),
            Cow::Owned(s) => Cow::Owned(s.clone()),
        }
    }
}

fn main() {
    let borrowed = Cow::Borrowed("hello");
    let owned = borrowed.to_owned();
}
```

## 8.8 生命周期和闭包

```rust
fn make_closure<'a>(x: &'a i32) -> impl Fn() -> i32 + 'a {
    move || *x
}

fn main() {
    let num = 5;
    let closure = make_closure(&num);
    println!("{}", closure());
}
```

## 8.9 常见模式

### 迭代器

```rust
fn process_items(items: &[i32]) {
    for item in items.iter() {
        println!("{}", item);
    }
}

// 或
fn process_items<'a>(items: &'a [i32]) {
    for item in items {
        println!("{}", item);
    }
}
```

### 切片

```rust
fn first_element(slice: &[i32]) -> Option<&i32> {
    slice.first()
}
```

### 多个引用

```rust
fn select<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() { x } else { y }
}
```

## 8.10 实战示例

### 缓存系统

```rust
struct Cache<'a> {
    data: &'a str,
    cached_result: Option<String>,
}

impl<'a> Cache<'a> {
    fn new(data: &'a str) -> Self {
        Cache {
            data,
            cached_result: None,
        }
    }
    
    fn get_result(&mut self) -> &str {
        if self.cached_result.is_none() {
            self.cached_result = Some(self.data.to_uppercase());
        }
        self.cached_result.as_ref().unwrap()
    }
}

fn main() {
    let text = String::from("hello");
    let mut cache = Cache::new(&text);
    println!("{}", cache.get_result());
}
```

### 配置解析器

```rust
struct Config<'a> {
    raw: &'a str,
}

impl<'a> Config<'a> {
    fn new(raw: &'a str) -> Self {
        Config { raw }
    }
    
    fn get(&self, key: &str) -> Option<&'a str> {
        for line in self.raw.lines() {
            if line.starts_with(key) {
                return Some(line.split('=').nth(1)?.trim());
            }
        }
        None
    }
}

fn main() {
    let config_text = "host=localhost\nport=8080";
    let config = Config::new(config_text);
    println!("host: {:?}", config.get("host"));
}
```

## 8.11 调试生命周期错误

### 常见错误

```rust
// 错误：返回局部变量的引用
// fn dangling() -> &i32 {
//     let x = 5;
//     &x  // x 在函数结束时被释放
// }

// 正确：返回所有权
fn not_dangling() -> i32 {
    let x = 5;
    x
}
```

### 生命周期不匹配

```rust
// 错误
// fn longest<'a>(x: &'a str, y: &str) -> &'a str {
//     x  // y 没有生命周期注解
// }

// 正确
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() { x } else { y }
}
```

## 8.12 练习题

1. 为持有字符串切片的结构体添加生命周期
2. 编写函数返回两个切片中较长的一个
3. 解释为什么某些函数不需要显式生命周期注解
4. 创建持有多个引用的结构体

## 8.13 小结

- 生命周期确保引用始终有效
- 使用 `'a` 等标注生命周期
- 编译器有省略规则，多数情况不需要显式标注
- 结构体持有引用时需要生命周期参数
- `'static` 表示程序运行期间都有效
- 生命周期是编译时检查，无运行时开销

---

[上一章：泛型和 trait ←](07-generics-traits.md) | [下一章：并发编程 →](09-concurrency.md)
