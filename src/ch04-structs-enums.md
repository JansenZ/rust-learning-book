# 第 4 章：结构体和枚举

## 4.1 结构体（Struct）

### 定义结构体

```rust
struct User {
    username: String,
    email: String,
    sign_in_count: u64,
    active: bool,
}

fn main() {
    let user1 = User {
        email: String::from("someone@example.com"),
        username: String::from("someusername123"),
        active: true,
        sign_in_count: 1,
    };
    
    println!("{} - {}", user1.username, user1.email);
}
```

### 字段初始化简写

```rust
fn main() {
    let username = String::from("rustacean");
    let email = String::from("rust@example.com");
    
    let user = User {
        username,  // 等价于 username: username
        email,
        active: true,
        sign_in_count: 1,
    };
}
```

### 结构体更新语法

```rust
fn main() {
    let user1 = User {
        email: String::from("someone@example.com"),
        username: String::from("someusername123"),
        active: true,
        sign_in_count: 1,
    };
    
    let user2 = User {
        email: String::from("another@example.com"),
        ..user1  // 复用 user1 的其他字段
    };
    
    // user1.username 已被移动，不能使用
}
```

### 元组结构体

```rust
struct Color(i32, i32, i32);
struct Point(i32, i32, i32);

fn main() {
    let black = Color(0, 0, 0);
    let origin = Point(0, 0, 0);
    
    // 访问字段
    println!("R: {}", black.0);
    println!("X: {}", origin.0);
    
    // 解构
    let Color(r, g, b) = black;
}
```

### 单元结构体

```rust
struct AlwaysEqual;

fn main() {
    let subject = AlwaysEqual;
}
```

## 4.2 结构体方法

### impl 块

```rust
#[derive(Debug)]
struct Rectangle {
    width: u32,
    height: u32,
}

impl Rectangle {
    // 关联函数（构造器）
    fn new(width: u32, height: u32) -> Self {
        Rectangle { width, height }
    }
    
    // 实例方法
    fn area(&self) -> u32 {
        self.width * self.height
    }
    
    fn perimeter(&self) -> u32 {
        2 * (self.width + self.height)
    }
    
    // 可变方法
    fn scale(&mut self, factor: u32) {
        self.width *= factor;
        self.height *= factor;
    }
    
    // 多个参数
    fn can_hold(&self, other: &Rectangle) -> bool {
        self.width > other.width && self.height > other.height
    }
}

fn main() {
    let rect1 = Rectangle::new(30, 50);
    let rect2 = Rectangle::new(10, 20);
    
    println!("面积：{}", rect1.area());
    println!("周长：{}", rect1.perimeter());
    println!("rect1 能容纳 rect2: {}", rect1.can_hold(&rect2));
    
    println!("{:?}", rect1);  // 需要 Debug trait
}
```

### 多个 impl 块

```rust
impl Rectangle {
    fn area(&self) -> u32 {
        self.width * self.height
    }
}

impl Rectangle {
    fn perimeter(&self) -> u32 {
        2 * (self.width + self.height)
    }
}
```

## 4.3 枚举（Enum）

### 定义枚举

```rust
enum Direction {
    North,
    South,
    East,
    West,
}

fn main() {
    let dir = Direction::North;
    
    match dir {
        Direction::North => println!("向北"),
        Direction::South => println!("向南"),
        Direction::East => println!("向东"),
        Direction::West => println!("向西"),
    }
}
```

### 带数据的枚举

```rust
enum Message {
    Quit,                       // 无数据
    Move { x: i32, y: i32 },   // 命名字段
    Write(String),              // 单个值
    ChangeColor(i32, i32, i32), // 多个值
}

fn main() {
    let m1 = Message::Quit;
    let m2 = Message::Move { x: 10, y: 20 };
    let m3 = Message::Write(String::from("hello"));
    let m4 = Message::ChangeColor(255, 0, 0);
}
```

### Option 枚举

```rust
fn main() {
    let some_number: Option<i32> = Some(5);
    let absent_number: Option<i32> = None;
    
    // Option 是 Rust 中最常用的枚举
    // 替代 null，更安全
    
    match some_number {
        Some(n) => println!("数字：{}", n),
        None => println!("没有数字"),
    }
}
```

## 4.4 match 表达式

### 基础用法

```rust
fn main() {
    let coin = "head";
    
    match coin {
        "head" => println!("正面！"),
        "tail" => println!("反面！"),
        _ => println!("边缘？"),
    }
}
```

### 匹配枚举

```rust
enum Coin {
    Penny,
    Nickel,
    Dime,
    Quarter,
}

fn value_in_cents(coin: Coin) -> u8 {
    match coin {
        Coin::Penny => {
            println!("幸运便士！");
            1
        },
        Coin::Nickel => 5,
        Coin::Dime => 10,
        Coin::Quarter => 25,
    }
}
```

### 匹配 Option

```rust
fn plus_one(x: Option<i32>) -> Option<i32> {
    match x {
        None => None,
        Some(i) => Some(i + 1),
    }
}

fn main() {
    let five = Some(5);
    let six = plus_one(five);
    let none = plus_one(None);
}
```

### 通配符和占位符

```rust
fn main() {
    let dice = 3;
    
    match dice {
        1 => println!("一"),
        2 => println!("二"),
        3..=6 => println!("三到六"),  // 范围
        _ => println!("其他"),         // 通配符
    }
    
    let x = Some(5);
    match x {
        Some(5) => println!("五"),
        Some(_) => println!("其他值"),  // 占位符
        None => println!("无"),
    }
}
```

## 4.5 if let

```rust
fn main() {
    let config_max = Some(3u8);
    
    // 简洁的 match
    if let Some(max) = config_max {
        println!("最大值：{}", max);
    }
    
    // 带 else
    let coin = Some("head");
    if let Some(side) = coin {
        println!("正面：{}", side);
    } else {
        println!("反面");
    }
}
```

## 4.6 实战示例

### 用户系统

```rust
#[derive(Debug)]
struct User {
    id: u64,
    username: String,
    email: String,
}

impl User {
    fn new(id: u64, username: &str, email: &str) -> Self {
        User {
            id,
            username: username.to_string(),
            email: email.to_string(),
        }
    }
    
    fn display(&self) {
        println!("用户 #{}: {} <{}>", 
                 self.id, self.username, self.email);
    }
}

fn main() {
    let user = User::new(1, "rustacean", "rust@example.com");
    user.display();
}
```

### 形状计算

```rust
#[derive(Debug)]
enum Shape {
    Circle(f64),           // 半径
    Rectangle(f64, f64),   // 宽，高
    Triangle(f64, f64),    // 底，高
}

impl Shape {
    fn area(&self) -> f64 {
        match self {
            Shape::Circle(r) => std::f64::consts::PI * r * r,
            Shape::Rectangle(w, h) => w * h,
            Shape::Triangle(b, h) => 0.5 * b * h,
        }
    }
}

fn main() {
    let shapes = vec![
        Shape::Circle(5.0),
        Shape::Rectangle(10.0, 5.0),
        Shape::Triangle(10.0, 5.0),
    ];
    
    for shape in shapes {
        println!("{:?} 面积：{:.2}", shape, shape.area());
    }
}
```

## 4.7 派生 Trait

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
struct Point {
    x: i32,
    y: i32,
}

fn main() {
    let p1 = Point { x: 10, y: 20 };
    let p2 = p1;  // Copy trait
    
    println!("{:?}", p1);  // Debug trait
    println!("{}", p1 == p2);  // PartialEq trait
}
```

### 常用派生宏

- `Debug` - 调试输出 `{:?}`
- `Clone` - 深拷贝 `.clone()`
- `Copy` - 隐式复制
- `PartialEq` - 比较 `==`
- `Eq` - 完全相等
- `Hash` - 哈希
- `Default` - 默认值

## 4.8 练习题

1. 创建一个表示学生的结构体，包含姓名、年龄、成绩
2. 为 Student 实现计算平均分的方法
3. 创建一个表示网络事件的枚举（连接、断开、数据）
4. 使用 match 处理不同的网络事件

## 4.9 小结

- 结构体用于创建自定义数据类型
- impl 块定义结构体的方法
- 枚举可以包含不同类型的数据
- match 强制穷尽性检查，更安全
- Option 枚举替代 null，避免空指针错误

---

[上一章：所有权和借用 ←](03-ownership-borrowing.md) | [下一章：模式匹配 →](05-pattern-matching.md)
