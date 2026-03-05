# 第 9 章：并发编程

## 9.1 线程基础

### 创建线程

```rust
use std::thread;
use std::time::Duration;

fn main() {
    let handle = thread::spawn(|| {
        for i in 1..5 {
            println!("子线程：{}", i);
            thread::sleep(Duration::from_millis(100));
        }
    });
    
    for i in 1..5 {
        println!("主线程：{}", i);
        thread::sleep(Duration::from_millis(100));
    }
    
    // 等待子线程完成
    handle.join().unwrap();
}
```

### move 关键字

```rust
use std::thread;

fn main() {
    let vec = vec![1, 2, 3];
    
    // 错误：vec 可能被主线程释放
    // let handle = thread::spawn(|| {
    //     println!("{:?}", vec);
    // });
    
    // 正确：使用 move 转移所有权
    let handle = thread::spawn(move || {
        println!("{:?}", vec);
    });
    
    handle.join().unwrap();
}
```

## 9.2 消息传递

### 通道（Channel）

```rust
use std::sync::mpsc;
use std::thread;

fn main() {
    let (tx, rx) = mpsc::channel();
    
    thread::spawn(move || {
        let msg = String::from("你好");
        tx.send(msg).unwrap();
        // msg 已被移动，不能再使用
    });
    
    let received = rx.recv().unwrap();
    println!("收到：{}", received);
}
```

### 发送多个消息

```rust
use std::sync::mpsc;
use std::thread;
use std::time::Duration;

fn main() {
    let (tx, rx) = mpsc::channel();
    
    thread::spawn(move || {
        let messages = vec![
            String::from("消息 1"),
            String::from("消息 2"),
            String::from("消息 3"),
        ];
        
        for msg in messages {
            tx.send(msg).unwrap();
            thread::sleep(Duration::from_millis(200));
        }
    });
    
    // 接收所有消息
    for received in rx {
        println!("收到：{}", received);
    }
}
```

### 多生产者

```rust
use std::sync::mpsc;
use std::thread;
use std::time::Duration;

fn main() {
    let (tx, rx) = mpsc::channel();
    let tx2 = tx.clone();  // 克隆发送者
    
    thread::spawn(move || {
        for i in 1..5 {
            tx.send(format!("线程 1: {}", i)).unwrap();
            thread::sleep(Duration::from_millis(100));
        }
    });
    
    thread::spawn(move || {
        for i in 1..5 {
            tx2.send(format!("线程 2: {}", i)).unwrap();
            thread::sleep(Duration::from_millis(100));
        }
    });
    
    for received in rx {
        println!("收到：{}", received);
    }
}
```

## 9.3 共享状态

### Mutex

```rust
use std::sync::Mutex;

fn main() {
    let m = Mutex::new(5);
    
    {
        let mut num = m.lock().unwrap();
        *num = 6;
    }  // 锁在此释放
    
    println!("m = {:?}", m);
}
```

### Arc（原子引用计数）

```rust
use std::sync::{Arc, Mutex};
use std::thread;

fn main() {
    let counter = Arc::new(Mutex::new(0));
    let mut handles = vec![];
    
    for _ in 0..10 {
        let counter = Arc::clone(&counter);
        
        let handle = thread::spawn(move || {
            let mut num = counter.lock().unwrap();
            *num += 1;
        });
        
        handles.push(handle);
    }
    
    for handle in handles {
        handle.join().unwrap();
    }
    
    println!("结果：{}", *counter.lock().unwrap());
}
```

### Arc vs Rc

```rust
// Rc: 单线程引用计数
use std::rc::Rc;

// Arc: 多线程原子引用计数
use std::sync::Arc;

// 线程间共享用 Arc，单线程用 Rc
```

## 9.4 并发原语

### RwLock（读写锁）

```rust
use std::sync::{Arc, RwLock};
use std::thread;

fn main() {
    let data = Arc::new(RwLock::new(5));
    
    // 多个读锁
    let data1 = Arc::clone(&data);
    let handle1 = thread::spawn(move || {
        let read = data1.read().unwrap();
        println!("读：{}", *read);
    });
    
    let data2 = Arc::clone(&data);
    let handle2 = thread::spawn(move || {
        let read = data2.read().unwrap();
        println!("读：{}", *read);
    });
    
    // 一个写锁
    let data3 = Arc::clone(&data);
    let handle3 = thread::spawn(move || {
        let mut write = data3.write().unwrap();
        *write += 1;
    });
    
    handle1.join().unwrap();
    handle2.join().unwrap();
    handle3.join().unwrap();
}
```

### Once

```rust
use std::sync::Once;

static INIT: Once = Once::new();
static mut VALUE: Option<String> = None;

fn init() {
    INIT.call_once(|| {
        unsafe {
            VALUE = Some(String::from("初始化"));
        }
    });
}

fn main() {
    init();
    init();  // 不会再次执行
    
    unsafe {
        println!("{:?}", VALUE);
    }
}
```

## 9.5 原子类型

```rust
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::Arc;
use std::thread;

fn main() {
    let counter = Arc::new(AtomicUsize::new(0));
    let mut handles = vec![];
    
    for _ in 0..10 {
        let counter = Arc::clone(&counter);
        
        let handle = thread::spawn(move || {
            counter.fetch_add(1, Ordering::SeqCst);
        });
        
        handles.push(handle);
    }
    
    for handle in handles {
        handle.join().unwrap();
    }
    
    println!("计数：{}", counter.load(Ordering::SeqCst));
}
```

### Ordering 类型

```rust
use std::sync::atomic::Ordering;

// Relaxed: 无顺序保证
// Acquire: 获取语义
// Release: 释放语义
// AcqRel: 获取 + 释放
// SeqCst: 顺序一致（默认，最安全）
```

## 9.6 智能并发类型

### Sender/Receiver 模式

```rust
use std::sync::mpsc;
use std::thread;

enum Message {
    Quit,
    Write(String),
    ChangeColor(u8, u8, u8),
}

fn main() {
    let (tx, rx) = mpsc::channel();
    
    thread::spawn(move || {
        tx.send(Message::Write(String::from("hello"))).unwrap();
        tx.send(Message::ChangeColor(255, 0, 0)).unwrap();
        tx.send(Message::Quit).unwrap();
    });
    
    for msg in rx {
        match msg {
            Message::Write(text) => println!("文本：{}", text),
            Message::ChangeColor(r, g, b) => {
                println!("颜色：RGB({}, {}, {})", r, g, b)
            },
            Message::Quit => break,
        }
    }
}
```

## 9.7 实战示例

### 线程池

```rust
use std::sync::{mpsc, Arc, Mutex};
use std::thread;

struct ThreadPool {
    workers: Vec<Worker>,
    sender: Option<mpsc::Sender<Job>>,
}

type Job = Box<dyn FnOnce() + Send + 'static>;

struct Worker {
    id: usize,
    thread: Option<thread::JoinHandle<()>>,
}

impl ThreadPool {
    fn new(size: usize) -> ThreadPool {
        let (sender, receiver) = mpsc::channel();
        let receiver = Arc::new(Mutex::new(receiver));
        
        let mut workers = Vec::with_capacity(size);
        
        for id in 0..size {
            workers.push(Worker::new(id, Arc::clone(&receiver)));
        }
        
        ThreadPool {
            workers,
            sender: Some(sender),
        }
    }
    
    fn execute<F>(&self, f: F)
    where
        F: FnOnce() + Send + 'static,
    {
        let job = Box::new(f);
        self.sender.as_ref().unwrap().send(job).unwrap();
    }
}

impl Worker {
    fn new(id: usize, receiver: Arc<Mutex<mpsc::Receiver<Job>>>) -> Worker {
        let thread = thread::spawn(move || {
            loop {
                let job = receiver.lock().unwrap().recv();
                
                match job {
                    Ok(job) => {
                        println!("Worker {} 执行任务", id);
                        job();
                    },
                    Err(_) => {
                        println!("Worker {} 断开", id);
                        break;
                    },
                }
            }
        });
        
        Worker {
            id,
            thread: Some(thread),
        }
    }
}
```

### 并行计算

```rust
use std::thread;

fn parallel_map<T, U, F>(data: Vec<T>, f: F) -> Vec<U>
where
    T: Send + 'static,
    U: Send + 'static,
    F: Fn(T) -> U + Send + Sync + 'static,
{
    let chunk_size = data.len() / 4 + 1;
    let chunks: Vec<_> = data.chunks(chunk_size).map(|c| c.to_vec()).collect();
    
    let mut handles = vec![];
    
    for chunk in chunks {
        let f = &f;
        let handle = thread::spawn(move || {
            chunk.into_iter().map(f).collect::<Vec<_>>()
        });
        handles.push(handle);
    }
    
    handles.into_iter()
        .flat_map(|h| h.join().unwrap())
        .collect()
}

fn main() {
    let data: Vec<i32> = (0..100).collect();
    let result = parallel_map(data, |x| x * 2);
    println!("{:?}", &result[..10]);
}
```

## 9.8 并发安全

### Send 和 Sync

```rust
// Send: 可以安全地在线程间转移所有权
// Sync: 可以安全地在多个线程中引用 (&T)

// 大多数类型自动实现 Send 和 Sync
// 例外：Rc 不实现 Send，原始指针不实现 Send/Sync
```

### 数据竞争

```rust
// 数据竞争的条件：
// 1. 两个或多个指针访问同一数据
// 2. 至少一个是写操作
// 3. 没有同步机制

// Rust 在编译时防止数据竞争
```

## 9.9 练习题

1. 创建两个线程，一个打印偶数，一个打印奇数
2. 使用 Mutex 和 Arc 实现线程安全的计数器
3. 使用通道实现生产者 - 消费者模式
4. 实现简单的线程池

## 9.10 小结

- 使用 `thread::spawn` 创建线程
- 使用 `join` 等待线程完成
- 通道（channel）用于线程间消息传递
- Mutex + Arc 实现共享状态
- 原子类型提供无锁并发
- Rust 在编译时保证线程安全

---

[上一章：生命周期 ←](08-lifetimes.md) | [下一章：实战项目 →](10-project.md)
