# 第 3 章：所有权和借用

> 💡 **所有权系统是 Rust 最核心的特性**，它保证了内存安全而无需垃圾回收器。

## 3.1 所有权规则

Rust 的所有权遵循三条简单规则：

1. **每个值都有一个所有者**
2. **同一时间只能有一个所有者**
3. **当所有者离开作用域，值被丢弃**

```rust
fn main() {
    {
        let s = String::from("hello");  // s 是所有者
    }  // s 离开作用域，内存被释放
}
```

## 3.2 String 类型

### String vs &str

```rust
fn main() {
    // String: 可增长、可变的字符串（堆上）
    let mut s = String::from("hello");
    s.push_str(", world!");
    
    // &str: 字符串切片（通常是栈上的引用）
    let literal: &str = "hello";
    let slice: &str = &s[0..5];
    
    println!("s = {}", s);
}
```

### 内存布局

```
String 结构：
┌─────────┬───────┬───────┐
│ pointer │ len   │ cap   │
│  0x100  │  5    │  10   │
└─────────┴───────┴───────┘
     ↓
┌─────────────────┐
│ h e l l o       │ (堆内存)
└─────────────────┘
```

## 3.3 移动语义（Move）

```rust
fn main() {
    let s1 = String::from("hello");
    let s2 = s1;  // 移动！s1 不再有效
    
    // println!("{}", s1);  // 错误！s1 已被移动
    
    println!("{}", s2);  // 正确
}
```

### 深层复制

```rust
fn main() {
    let s1 = String::from("hello");
    let s2 = s1.clone();  // 深拷贝
    
    println!("s1 = {}, s2 = {}", s1, s2);  // 都有效
}
```

### Copy trait

```rust
fn main() {
    let x = 5;
    let y = x;  // 复制（i32 实现了 Copy）
    
    println!("x = {}, y = {}", x, y);  // 都有效
    
    // 实现 Copy 的类型：
    // - 所有整数类型
    // - 布尔类型
    // - 浮点类型
    // - 字符类型
    // - 元组（仅当所有元素都实现 Copy）
}
```

## 3.4 所有权与函数

```rust
fn main() {
    let s = String::from("hello");
    takes_ownership(s);  // s 被移动
    
    // println!("{}", s);  // 错误！
    
    let x = 5;
    makes_copy(x);  // x 被复制
    println!("{}", x);  // 正确
}

fn takes_ownership(some_string: String) {
    println!("{}", some_string);
}  // some_string 离开作用域，内存释放

fn makes_copy(some_integer: i32) {
    println!("{}", some_integer);
}
```

### 返回所有权

```rust
fn main() {
    let s1 = gives_ownership();
    let s2 = String::from("hello");
    let s3 = takes_and_gives_back(s2);
    
    // s2 已被移动，不能使用
    println!("s1 = {}, s3 = {}", s1, s3);
}

fn gives_ownership() -> String {
    String::from("hello")
}

fn takes_and_gives_back(a_string: String) -> String {
    a_string
}
```

## 3.5 引用和借用

### 不可变引用

```rust
fn main() {
    let s = String::from("hello");
    
    let len = calculate_length(&s);  // &s 创建引用
    
    println!("{} 的长度是 {}", s, len);
}

fn calculate_length(s: &String) -> usize {
    s.len()
}  // s 离开作用域，但不释放内存（因为不是所有者）
```

### 可变引用

```rust
fn main() {
    let mut s = String::from("hello");
    
    change(&mut s);
    
    println!("{}", s);  // 输出：hello, world
}

fn change(some_string: &mut String) {
    some_string.push_str(", world");
}
```

### 引用规则

```rust
fn main() {
    let mut s = String::from("hello");
    
    // 规则 1: 同一时间只能有一个可变引用
    let r1 = &mut s;
    // let r2 = &mut s;  // 错误！
    
    // 规则 2: 可变引用时不能有不可变引用
    let r1 = &s;
    let r2 = &s;
    // let r3 = &mut s;  // 错误！
    
    println!("{}, {}, and {}", r1, r2, s);
}
```

### 作用域分离

```rust
fn main() {
    let mut s = String::from("hello");
    
    {
        let r1 = &mut s;
        r1.push_str(", world");
    }  // r1 离开作用域
    
    let r2 = &mut s;  // 正确！r1 已释放
    r2.push_str("!");
    
    println!("{}", s);
}
```

## 3.6 悬垂引用

```rust
// 错误示例：返回悬垂引用
fn dangle() -> &String {
    let s = String::from("hello");
    &s  // 错误！s 将被释放
}

// 正确：返回所有权
fn no_dangle() -> String {
    String::from("hello")
}
```

## 3.7 切片（Slices）

### 字符串切片

```rust
fn main() {
    let s = String::from("hello world");
    
    let hello = &s[0..5];  // "hello"
    let world = &s[6..11]; // "world"
    let hello = &s[..5];   // 简写
    let world = &s[6..];   // 简写
    let whole = &s[..];    // 整个字符串
    
    println!("{} {}", hello, world);
}
```

### 切片作为参数

```rust
fn main() {
    let s = String::from("hello world");
    let word = first_word(&s);
    
    println!("第一个单词：{}", word);
}

fn first_word(s: &str) -> &str {
    let bytes = s.as_bytes();
    
    for (i, &item) in bytes.iter().enumerate() {
        if item == b' ' {
            return &s[0..i];
        }
    }
    
    &s[..]
}
```

### 其他切片

```rust
fn main() {
    let arr = [1, 2, 3, 4, 5];
    
    let slice: &[i32] = &arr[1..3];  // [2, 3]
    
    println!("{:?}", slice);
}
```

## 3.8 实战示例

### 统计单词

```rust
fn count_words(text: &str) -> usize {
    text.split_whitespace().count()
}

fn main() {
    let s = String::from("Rust is awesome");
    let count = count_words(&s);
    println!("单词数：{}", count);  // 3
}
```

### 字符串处理

```rust
fn main() {
    let mut s = String::new();
    
    s.push_str("Hello");
    s.push('!');
    
    // 使用引用，不转移所有权
    let len = s.len();
    
    println!("{} (长度：{})", s, len);
}
```

## 3.9 常见陷阱

### 借用检查器错误

```rust
fn main() {
    let mut s = String::from("hello");
    
    let r1 = &s;
    let r2 = &s;
    
    println!("{} and {}", r1, r2);
    // r1 和 r2 不再使用
    
    let r3 = &mut s;  // 正确！r1, r2 作用域结束
    r3.push_str(", world");
}
```

### 迭代器借用

```rust
fn main() {
    let mut numbers = vec![1, 2, 3, 4, 5];
    
    // 错误：同时存在不可变和可变借用
    // for num in &numbers {
    //     numbers.push(*num);  // 错误！
    // }
    
    // 正确：先收集，再添加
    let to_add: Vec<i32> = numbers.iter().copied().collect();
    for num in to_add {
        numbers.push(num);
    }
}
```

## 3.10 练习题

1. 解释为什么 `let s2 = s1` 对 String 是移动，对 i32 是复制
2. 编写函数，接受 &str 参数，返回第一个字符
3. 修复代码中的借用错误
4. 使用切片反转字符串中的单词顺序

## 3.11 小结

- 所有权保证内存安全：一个值只有一个所有者
- 移动语义：赋值会转移所有权
- 引用允许借用而不获取所有权
- 同一时间只能有一个可变引用，或多个不可变引用
- 切片是对连续内存的引用，不拥有数据

---

[上一章：变量和数据类型 ←](02-variables-types.md) | [下一章：结构体和枚举 →](04-structs-enums.md)
