# 第 7 章：泛型和 trait

## 7.1 泛型（Generics）

### 函数中的泛型

```rust
// 泛型函数
fn largest<T: PartialOrd>(list: &[T]) -> &T {
    let mut largest = &list[0];
    
    for item in list {
        if item > largest {
            largest = item;
        }
    }
    
    largest
}

fn main() {
    let numbers = vec![34, 50, 25, 100, 65];
    println!("最大数字：{}", largest(&numbers));
    
    let chars = vec!['y', 'm', 'a', 'q'];
    println!("最大字符：{}", largest(&chars));
}
```

### 结构体中的泛型

```rust
struct Point<T> {
    x: T,
    y: T,
}

fn main() {
    let integer = Point { x: 5, y: 10 };
    let float = Point { x: 1.0, y: 4.0 };
}
```

### 多个泛型参数

```rust
struct Point<T, U> {
    x: T,
    y: U,
}

fn main() {
    let p = Point { x: 5, y: 10.0 };  // T=i32, U=f64
}
```

### 枚举中的泛型

```rust
enum Option<T> {
    Some(T),
    None,
}

enum Result<T, E> {
    Ok(T),
    Err(E),
}

fn main() {
    let some_number: Option<i32> = Some(5);
    let some_char: Option<char> = Some('a');
    
    let ok: Result<i32, &str> = Ok(5);
    let err: Result<i32, &str> = Err("错误");
}
```

### 方法实现

```rust
struct Point<T> {
    x: T,
    y: T,
}

impl<T> Point<T> {
    fn x(&self) -> &T {
        &self.x
    }
    
    fn y(&self) -> &T {
        &self.y
    }
}

// 特定类型的实现
impl Point<f32> {
    fn distance_from_origin(&self) -> f32 {
        (self.x.powi(2) + self.y.powi(2)).sqrt()
    }
}

fn main() {
    let p = Point { x: 3.0, y: 4.0 };
    println!("x = {}", p.x());
    println!("距离原点：{}", p.distance_from_origin());
}
```

## 7.2 Trait

### 定义 Trait

```rust
pub trait Summary {
    fn summarize(&self) -> String;
    
    // 默认实现
    fn summary(&self) -> String {
        String::from("(更多内容...)")
    }
}
```

### 实现 Trait

```rust
pub struct NewsArticle {
    pub headline: String,
    pub location: String,
    pub author: String,
    pub content: String,
}

impl Summary for NewsArticle {
    fn summarize(&self) -> String {
        format!("{}, by {} ({})", 
                self.headline, self.author, self.location)
    }
}

pub struct Tweet {
    pub username: String,
    pub content: String,
}

impl Summary for Tweet {
    fn summarize(&self) -> String {
        format!("{}: {}", self.username, self.content)
    }
}

fn main() {
    let tweet = Tweet {
        username: String::from("rustlang"),
        content: String::from("Rust 很棒！"),
    };
    
    println!("推文：{}", tweet.summarize());
}
```

### Trait 作为参数

```rust
pub fn notify(item: &impl Summary) {
    println!("通知：{}", item.summarize());
}

// 等价于
pub fn notify<T: Summary>(item: &T) {
    println!("通知：{}", item.summarize());
}
```

### 多个 Trait 约束

```rust
// impl Trait 语法
pub fn notify(item: &(impl Summary + Display)) { }

// 泛型语法
pub fn notify<T: Summary + Display>(item: &T) { }

// where 子句（更清晰）
pub fn notify<T>(item: &T) 
where 
    T: Summary + Display 
{
    println!("通知：{}", item.summarize());
}
```

### 返回实现 Trait 的类型

```rust
fn returns_summary() -> impl Summary {
    Tweet {
        username: String::from("rustlang"),
        content: String::from("Rust 很棒！"),
    }
}

// 注意：只能返回单一类型
// 不能有时返回 Tweet，有时返回 NewsArticle
```

### 条件实现

```rust
impl<T: Display> Summary for Pair<T> {
    fn summarize(&self) -> String {
        format!("({}, {})", self.x, self.y)
    }
}

// 仅当 T 和 U 都实现 PartialOrd 时
impl<T: PartialOrd + Display, U: PartialOrd + Display> 
    Pair<T, U> 
{
    fn cmp_display(&self) {
        if self.x >= self.y {
            println!("最大是 x = {}", self.x);
        } else {
            println!("最大是 y = {}", self.y);
        }
    }
}
```

## 7.3 常用标准库 Trait

### Display 和 Debug

```rust
use std::fmt;

struct Point {
    x: i32,
    y: i32,
}

// Debug: 调试输出 {:?}
impl fmt::Debug for Point {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "Point {{ x: {}, y: {} }}", self.x, self.y)
    }
}

// Display: 用户友好输出 {}
impl fmt::Display for Point {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "({}, {})", self.x, self.y)
    }
}

fn main() {
    let p = Point { x: 10, y: 20 };
    println!("{:?}", p);  // Debug
    println!("{}", p);    // Display
}
```

### Clone 和 Copy

```rust
#[derive(Clone, Debug)]
struct Person {
    name: String,
    age: u32,
}

fn main() {
    let p1 = Person {
        name: String::from("Alice"),
        age: 30,
    };
    
    let p2 = p1.clone();  // 深拷贝
    
    println!("{:?}", p1);
    println!("{:?}", p2);
}
```

### PartialEq 和 Eq

```rust
#[derive(PartialEq, Eq, Debug)]
struct Rectangle {
    width: u32,
    height: u32,
}

fn main() {
    let rect1 = Rectangle { width: 30, height: 50 };
    let rect2 = Rectangle { width: 30, height: 50 };
    
    println!("相等：{}", rect1 == rect2);
}
```

### Default

```rust
#[derive(Default, Debug)]
struct User {
    username: String,
    active: bool,
}

fn main() {
    let user = User::default();
    println!("{:?}", user);
}
```

## 7.4 Trait 对象

### 动态分发

```rust
trait Draw {
    fn draw(&self);
}

struct Button {
    label: String,
}

impl Draw for Button {
    fn draw(&self) {
        println!("绘制按钮：{}", self.label);
    }
}

struct TextField {
    content: String,
}

impl Draw for TextField {
    fn draw(&self) {
        println!("绘制文本框：{}", self.content);
    }
}

// Trait 对象
fn draw_screen(components: &[&dyn Draw]) {
    for component in components {
        component.draw();
    }
}

fn main() {
    let button = Button { label: String::from("确定") };
    let text = TextField { content: String::from("输入...") };
    
    let components: Vec<&dyn Draw> = vec![&button, &text];
    draw_screen(&components);
}
```

### Box<dyn Trait>

```rust
fn main() {
    // 存储不同类型的 Trait 对象
    let components: Vec<Box<dyn Draw>> = vec![
        Box::new(Button { label: String::from("确定") }),
        Box::new(TextField { content: String::from("输入") }),
    ];
    
    for component in components {
        component.draw();
    }
}
```

## 7.5 实战示例

### 通用容器

```rust
struct Stack<T> {
    items: Vec<T>,
}

impl<T> Stack<T> {
    fn new() -> Self {
        Stack { items: Vec::new() }
    }
    
    fn push(&mut self, item: T) {
        self.items.push(item);
    }
    
    fn pop(&mut self) -> Option<T> {
        self.items.pop()
    }
    
    fn is_empty(&self) -> bool {
        self.items.is_empty()
    }
}

fn main() {
    let mut int_stack = Stack::new();
    int_stack.push(1);
    int_stack.push(2);
    
    let mut string_stack = Stack::new();
    string_stack.push(String::from("hello"));
}
```

### 可比较类型

```rust
fn find_max<T: PartialOrd + Copy>(slice: &[T]) -> Option<T> {
    if slice.is_empty() {
        return None;
    }
    
    let mut max = slice[0];
    for &item in slice.iter() {
        if item > max {
            max = item;
        }
    }
    
    Some(max)
}

fn main() {
    let numbers = [3, 7, 2, 9, 1];
    println!("最大值：{:?}", find_max(&numbers));
    
    let chars = ['a', 'z', 'm'];
    println!("最大字符：{:?}", find_max(&chars));
}
```

## 7.6 练习题

1. 创建一个泛型函数，交换两个值的位置
2. 为自定义类型实现 Display trait
3. 使用 Trait 对象创建图形渲染系统
4. 实现一个泛型的链表结构

## 7.7 小结

- 泛型允许编写适用于多种类型的代码
- Trait 定义共享行为
- impl Trait 简化函数签名
- where 子句使复杂约束更清晰
- Trait 对象实现运行时多态
- 标准库提供常用 Trait：Display, Debug, Clone, Copy 等

---

[上一章：错误处理 ←](06-error-handling.md) | [下一章：生命周期 →](08-lifetimes.md)
