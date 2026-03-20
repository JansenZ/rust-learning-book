# 第 6 章：错误处理

## 6.1 Rust 的错误处理哲学

Rust 将错误分为两类：

1. **可恢复错误** - 使用 `Result<T, E>`
2. **不可恢复错误** - 使用 `panic!`

```rust
// 可恢复错误：文件不存在，可以尝试其他路径
let file = File::open("hello.txt");

// 不可恢复错误：逻辑错误，无法继续
panic!("crash and burn!");
```

## 6.2 panic! 宏

### 触发 panic

```rust
fn main() {
    panic!("出错了！");
    
    // 数组越界
    let v = vec![1, 2, 3];
    v[99];  // panic!
    
    // 除零（调试模式）
    // let x = 1 / 0;
}
```

### 调用栈

```bash
$ cargo run
thread 'main' panicked at '出错了！', src/main.rs:2:5
stack backtrace:
   0: std::panicking::begin_panic
   1: my_program::main
   ...
```

### 环境变量

```bash
# 发布模式：panic 时直接中止（更快更小）
RUSTFLAGS="-C panic=abort" cargo build --release

# 调试模式：展开栈（默认）
```

### 何时使用 panic!

```rust
// ✅ 适合 panic 的场景：
// 1. 示例/原型代码
// 2. 测试代码
// 3. 逻辑上不可能发生的情况
// 4. 无法恢复的错误状态

// ❌ 避免 panic 的场景：
// 1. 用户输入错误
// 2. 文件不存在
// 3. 网络错误
// 4. 任何预期可能失败的操作
```

## 6.3 Result 枚举

### Result 定义

```rust
enum Result<T, E> {
    Ok(T),   // 成功
    Err(E),  // 错误
}
```

### 处理 Result

```rust
use std::fs::File;

fn main() {
    let file_result = File::open("hello.txt");
    
    let file = match file_result {
        Ok(file) => file,
        Err(error) => panic!("打开文件失败：{:?}", error),
    };
}
```

### 匹配具体错误

```rust
use std::fs::File;
use std::io::ErrorKind;

fn main() {
    let file = match File::open("hello.txt") {
        Ok(file) => file,
        Err(error) => match error.kind() {
            ErrorKind::NotFound => {
                match File::create("hello.txt") {
                    Ok(fc) => fc,
                    Err(e) => panic!("创建文件失败：{:?}", e),
                }
            },
            other_error => {
                panic!("打开文件失败：{:?}", other_error)
            },
        },
    };
}
```

## 6.4 简化错误处理

### unwrap

```rust
use std::fs::File;

fn main() {
    // Ok 时返回值，Err 时 panic
    let file = File::open("hello.txt").unwrap();
}
```

### expect

```rust
use std::fs::File;

fn main() {
    // 类似 unwrap，但可自定义错误信息
    let file = File::open("hello.txt")
        .expect("无法打开 hello.txt");
}
```

### unwrap_or 和 unwrap_or_else

```rust
fn main() {
    // 失败时使用默认值
    let file = File::open("hello.txt")
        .unwrap_or(create_default_file());
    
    // 失败时执行闭包
    let file = File::open("hello.txt")
        .unwrap_or_else(|_| create_default_file());
}
```

## 6.5 传播错误

### match 传播

```rust
use std::fs::File;
use std::io::{self, Read};

fn read_file() -> Result<String, io::Error> {
    let file = match File::open("hello.txt") {
        Ok(f) => f,
        Err(e) => return Err(e),
    };
    
    let mut contents = String::new();
    match file.read_to_string(&mut contents) {
        Ok(_) => Ok(contents),
        Err(e) => Err(e),
    }
}
```

### ? 运算符

```rust
use std::fs::File;
use std::io::{self, Read};

fn read_file() -> Result<String, io::Error> {
    let mut file = File::open("hello.txt")?;
    let mut contents = String::new();
    file.read_to_string(&mut contents)?;
    Ok(contents)
}
```

### 链式调用

```rust
use std::fs::File;
use std::io::{self, Read};

fn read_file() -> Result<String, io::Error> {
    let mut contents = String::new();
    File::open("hello.txt")?
        .read_to_string(&mut contents)?;
    Ok(contents)
}
```

### ? 的使用限制

```rust
// ✅ 正确：函数返回 Result
fn read_file() -> Result<String, io::Error> {
    File::open("hello.txt")?;
    Ok(String::new())
}

// ❌ 错误：函数返回 Option
// fn get_first() -> Option<i32> {
//     let file = File::open("hello.txt")?;  // 类型不匹配
//     Some(1)
// }
```

## 6.6 错误类型转换

### From trait

```rust
use std::fs::File;
use std::io;
use std::num::ParseIntError;

fn read_and_parse() -> Result<i32, Box<dyn std::error::Error>> {
    let contents = std::fs::read_to_string("number.txt")?;
    let number: i32 = contents.trim().parse()?;
    Ok(number)
}
```

### 自定义错误类型

```rust
use std::fmt;
use std::error::Error;

#[derive(Debug)]
enum MyError {
    Io(std::io::Error),
    Parse(std::num::ParseIntError),
    NotFound(String),
}

impl fmt::Display for MyError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            MyError::Io(err) => write!(f, "IO 错误：{}", err),
            MyError::Parse(err) => write!(f, "解析错误：{}", err),
            MyError::NotFound(path) => write!(f, "文件不存在：{}", path),
        }
    }
}

impl Error for MyError {}

impl From<std::io::Error> for MyError {
    fn from(err: std::io::Error) -> MyError {
        MyError::Io(err)
    }
}

impl From<std::num::ParseIntError> for MyError {
    fn from(err: std::num::ParseIntError) -> MyError {
        MyError::Parse(err)
    }
}
```

## 6.7 thiserror 和 anyhow

### thiserror（库开发者）

```toml
# Cargo.toml
[dependencies]
thiserror = "1.0"
```

```rust
use thiserror::Error;

#[derive(Error, Debug)]
enum DataError {
    #[error("数据不存在：{0}")]
    NotFound(String),
    
    #[error("IO 错误")]
    Io(#[from] std::io::Error),
    
    #[error("解析失败：{0}")]
    Parse(#[from] std::num::ParseIntError),
}
```

### anyhow（应用开发者）

```toml
# Cargo.toml
[dependencies]
anyhow = "1.0"
```

```rust
use anyhow::{Context, Result};

fn read_config() -> Result<String> {
    let path = "config.txt";
    std::fs::read_to_string(path)
        .with_context(|| format!("无法读取配置文件：{}", path))
}

fn main() -> Result<()> {
    let config = read_config()?;
    println!("{}", config);
    Ok(())
}
```

## 6.8 实战示例

### 用户输入验证

```rust
#[derive(Debug)]
enum ValidationError {
    EmptyName,
    TooLong(String),
    InvalidAge,
}

fn validate_user(name: &str, age: u8) -> Result<(), ValidationError> {
    if name.is_empty() {
        return Err(ValidationError::EmptyName);
    }
    
    if name.len() > 50 {
        return Err(ValidationError::TooLong(name.to_string()));
    }
    
    if age < 1 || age > 150 {
        return Err(ValidationError::InvalidAge);
    }
    
    Ok(())
}

fn main() {
    match validate_user("", 25) {
        Ok(_) => println!("验证通过"),
        Err(e) => println!("验证失败：{:?}", e),
    }
}
```

### 文件操作

```rust
use std::fs::{self, File};
use std::io::{self, Write};

fn save_data(filename: &str, data: &str) -> Result<(), io::Error> {
    let mut file = File::create(filename)?;
    file.write_all(data.as_bytes())?;
    file.sync_all()?;
    Ok(())
}

fn load_data(filename: &str) -> Result<String, io::Error> {
    fs::read_to_string(filename)
}

fn main() -> Result<(), io::Error> {
    save_data("test.txt", "Hello, Rust!")?;
    let data = load_data("test.txt")?;
    println!("{}", data);
    Ok(())
}
```

## 6.9 何时使用 panic

```rust
// ✅ 适合 panic
fn divide(a: i32, b: i32) -> i32 {
    if b == 0 {
        panic!("除数不能为零");  // 调用者错误
    }
    a / b
}

// ✅ 适合 panic
fn get_first(v: &[i32]) -> i32 {
    *v.first().expect("切片不能为空")  // 逻辑错误
}

// ❌ 应该用 Result
fn parse_number(s: &str) -> Result<i32, std::num::ParseIntError> {
    s.parse()  // 用户输入，预期可能失败
}
```

## 6.10 练习题

1. 编写函数，读取文件并返回行数，使用 ? 运算符
2. 创建自定义错误类型处理用户注册验证
3. 使用 anyhow 简化错误处理
4. 实现一个安全的除法函数，返回 Result

## 6.11 小结

- 使用 `panic!` 处理不可恢复错误
- 使用 `Result<T, E>` 处理可恢复错误
- `?` 运算符简化错误传播
- 库代码使用具体错误类型，应用代码可用 anyhow
- thiserror 简化自定义错误定义
- 始终优先使用 Result 而非 panic

---

[上一章：模式匹配 ←](05-pattern-matching.md) | [下一章：泛型和 trait →](07-generics-traits.md)
