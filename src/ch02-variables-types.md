# 第 2 章：变量和数据类型

## 2.1 变量声明

### 不可变变量（默认）

```rust
fn main() {
    let x = 5;      // 类型推断为 i32
    let y: i32 = 10; // 显式声明类型
    
    println!("x = {}, y = {}", x, y);
    
    // x = 6;  // 错误！不能重新赋值
}
```

### 可变变量

```rust
fn main() {
    let mut counter = 0;
    
    counter += 1;
    counter += 2;
    
    println!("counter = {}", counter);  // 输出：3
}
```

### 常量

```rust
const MAX_POINTS: u32 = 100_000;  // 必须标注类型
const PI: f64 = 3.14159;

fn main() {
    println!("MAX_POINTS = {}", MAX_POINTS);
}
```

### 变量遮蔽（Shadowing）

```rust
fn main() {
    let x = 5;
    let x = x + 1;  // 遮蔽之前的 x
    let x = x * 2;
    
    println!("x = {}", x);  // 输出：12
    
    // 遮蔽可以改变类型
    let spaces = "   ";
    let spaces = spaces.len();  // &str -> usize
}
```

## 2.2 基本数据类型

### 整数类型

| 类型 | 大小 | 范围 |
|------|------|------|
| i8 | 8-bit | -128 to 127 |
| i16 | 16-bit | -32,768 to 32,767 |
| i32 | 32-bit | -2,147,483,648 to 2,147,483,647 |
| i64 | 64-bit | 约 ±9×10¹⁸ |
| i128 | 128-bit | 约 ±1×10³⁸ |
| isize/usize | 指针大小 | 依赖架构 |

```rust
fn main() {
    let a: i32 = 42;
    let b: u64 = 100;
    let c: isize = -50;
    
    // 数字字面量
    let decimal = 99_220;      // 99220
    let hex = 0xff;            // 255
    let octal = 0o77;          // 63
    let binary = 0b1111_0000;  // 240
    let byte = b'A';           // 65 (u8)
}
```

### 浮点类型

```rust
fn main() {
    let x = 2.0;              // f64 (默认)
    let y: f32 = 3.0;         // f32
    
    println!("x = {}, y = {}", x, y);
}
```

### 布尔类型

```rust
fn main() {
    let t = true;
    let f: bool = false;
    
    let is_rust_fun = true;
}
```

### 字符类型

```rust
fn main() {
    let c = 'z';
    let heart = '❤️';
    let japanese = 'あ';
    
    println!("c = {}, heart = {}", c, heart);
    
    // char 是 4 字节的 Unicode 标量值
    println!("size of char: {} bytes", std::mem::size_of::<char>());
}
```

## 2.3 复合类型

### 元组（Tuple）

```rust
fn main() {
    let tuple: (i32, f64, char) = (50, 3.14, 'A');
    
    // 解构
    let (x, y, z) = tuple;
    println!("x = {}, y = {}, z = {}", x, y, z);
    
    // 索引访问
    let first = tuple.0;
    let second = tuple.1;
    
    // 空元组
    let unit: () = ();
}
```

### 数组（Array）

```rust
fn main() {
    // 固定长度数组
    let arr: [i32; 5] = [1, 2, 3, 4, 5];
    
    // 简写：重复元素
    let zeros = [0; 5];  // [0, 0, 0, 0, 0]
    
    // 访问元素
    let first = arr[0];
    let second = arr[1];
    
    // 数组长度
    let len = arr.len();
    
    println!("数组长度：{}", len);
}
```

### 数组越界示例

```rust
fn main() {
    let arr = [1, 2, 3, 4, 5];
    
    // 运行时检查，越界会 panic
    let index = 10;
    let value = arr[index];  // 运行时错误！
}
```

## 2.4 类型转换

### 数值转换

```rust
fn main() {
    // 显式转换（不会溢出检查）
    let a: u8 = 255;
    let b: u32 = a as u32;
    
    // 可能丢失精度
    let c: f64 = 3.9;
    let d: u32 = c as u32;  // 3 (截断小数)
    
    println!("b = {}, d = {}", b, d);
}
```

### 类型推断失败

```rust
fn main() {
    // 需要类型注解
    let guess: u32 = "42".parse().expect("不是数字！");
    
    // 或者使用 turbofish
    let guess = "42".parse::<u32>().expect("不是数字！");
}
```

## 2.5 实战示例

### 温度转换器

```rust
fn main() {
    let celsius = 25.0;
    let fahrenheit = celsius_to_fahrenheit(celsius);
    
    println!("{}°C = {}°F", celsius, fahrenheit);
}

fn celsius_to_fahrenheit(c: f64) -> f64 {
    (c * 9.0 / 5.0) + 32.0
}
```

### 数组统计

```rust
fn main() {
    let numbers = [10, 20, 30, 40, 50];
    
    let sum: i32 = numbers.iter().sum();
    let avg = sum as f64 / numbers.len() as f64;
    
    println!("总和：{}, 平均值：{}", sum, avg);
}
```

## 2.6 常见陷阱

### 整数溢出

```rust
fn main() {
    let x: u8 = 255;
    // let y = x + 1;  // 调试模式：panic；发布模式：溢出
    
    // 安全的运算方法
    let (y, overflowed) = x.overflowing_add(1);
    println!("y = {}, overflowed = {}", y, overflowed);
}
```

### 类型不匹配

```rust
fn main() {
    let x = 5;
    let y = 5.0;
    
    // let z = x + y;  // 错误！不能直接相加
    
    let z = x as f64 + y;  // 正确
}
```

## 2.7 练习题

1. 声明一个可变变量，初始值为 10，然后将其增加到 100
2. 创建一个包含姓名、年龄、身高的元组
3. 创建一个有 7 个元素的数组，表示一周的天数
4. 编写函数将华氏温度转换为摄氏温度

## 2.8 小结

- 变量默认不可变，使用 `mut` 声明可变变量
- Rust 有强类型系统，支持类型推断
- 整数类型分有符号（i）和无符号（u）
- 数组是固定长度的，越界访问会 panic
- 使用 `as` 进行显式类型转换

---

[上一章：Rust 简介和安装 ←](01-introduction.md) | [下一章：所有权和借用 →](03-ownership-borrowing.md)
