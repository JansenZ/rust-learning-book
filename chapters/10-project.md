# 第 10 章：实战项目

## 10.1 项目一：命令行工具

### grep 实现

```rust
// Cargo.toml
[package]
name = "minigrep"
version = "0.1.0"
edition = "2021"

[dependencies]
```

```rust
// src/main.rs
use std::env;
use std::fs;
use std::process;

struct Config {
    query: String,
    filename: String,
    case_sensitive: bool,
}

impl Config {
    fn new(args: &[String]) -> Result<Config, &'static str> {
        if args.len() < 3 {
            return Err("参数不足");
        }
        
        let query = args[1].clone();
        let filename = args[2].clone();
        let case_sensitive = env::var("CASE_INSENSITIVE").is_err();
        
        Ok(Config {
            query,
            filename,
            case_sensitive,
        })
    }
}

fn run(config: Config) -> Result<(), Box<dyn std::error::Error>> {
    let contents = fs::read_to_string(&config.filename)?;
    
    let results = if config.case_sensitive {
        search(&config.query, &contents)
    } else {
        search_case_insensitive(&config.query, &contents)
    };
    
    for line in results {
        println!("{}", line);
    }
    
    Ok(())
}

fn search<'a>(query: &str, contents: &'a str) -> Vec<&'a str> {
    contents
        .lines()
        .filter(|line| line.contains(query))
        .collect()
}

fn search_case_insensitive<'a>(
    query: &str,
    contents: &'a str,
) -> Vec<&'a str> {
    let query = query.to_lowercase();
    
    contents
        .lines()
        .filter(|line| line.to_lowercase().contains(&query))
        .collect()
}

fn main() {
    let args: Vec<String> = env::args().collect();
    
    let config = Config::new(&args).unwrap_or_else(|err| {
        eprintln!("参数错误：{}", err);
        process::exit(1);
    });
    
    if let Err(e) = run(config) {
        eprintln!("程序错误：{}", e);
        process::exit(1);
    }
}
```

### 使用示例

```bash
$ cargo run -- to search poem.txt
在诗中寻找 "to"

$ CASE_INSENSITIVE=1 cargo run -- to search poem.txt
不区分大小写搜索
```

## 10.2 项目二：Web 服务器

### 基础服务器

```rust
// Cargo.toml
[package]
name = "web_server"
version = "0.1.0"
edition = "2021"
```

```rust
// src/main.rs
use std::fs;
use std::io::{prelude::*, BufReader};
use std::net::{TcpListener, TcpStream};
use std::thread;
use std::time::Duration;

fn main() {
    let listener = TcpListener::bind("127.0.0.1:7878").unwrap();
    
    println!("服务器运行在 http://127.0.0.1:7878");
    
    for stream in listener.incoming() {
        let stream = stream.unwrap();
        
        thread::spawn(|| {
            handle_connection(stream);
        });
    }
}

fn handle_connection(mut stream: TcpStream) {
    let buf_reader = BufReader::new(&mut stream);
    let http_request: Vec<_> = buf_reader
        .lines()
        .map(|result| result.unwrap())
        .take_while(|line| !line.is_empty())
        .collect();
    
    let (status_line, filename) = match &http_request[..] {
        ["GET /", ..] => ("HTTP/1.1 200 OK", "hello.html"),
        ["GET /sleep", ..] => {
            thread::sleep(Duration::from_secs(5));
            ("HTTP/1.1 200 OK", "hello.html")
        },
        _ => ("HTTP/1.1 404 NOT FOUND", "404.html"),
    };
    
    let contents = fs::read_to_string(filename).unwrap_or_default();
    
    let response = format!(
        "{}\r\nContent-Length: {}\r\n\r\n{}",
        status_line,
        contents.len(),
        contents
    );
    
    stream.write_all(response.as_bytes()).unwrap();
}
```

### 线程池版本

```rust
// src/lib.rs
pub struct ThreadPool {
    workers: Vec<Worker>,
    sender: Option<mpsc::Sender<Job>>,
}

type Job = Box<dyn FnOnce() + Send + 'static>;

impl ThreadPool {
    pub fn new(size: usize) -> ThreadPool {
        assert!(size > 0);
        
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
    
    pub fn execute<F>(&self, f: F)
    where
        F: FnOnce() + Send + 'static,
    {
        let job = Box::new(f);
        self.sender.as_ref().unwrap().send(job).unwrap();
    }
}

impl Drop for ThreadPool {
    fn drop(&mut self) {
        drop(self.sender.take());
        
        for worker in &mut self.workers {
            println!("关闭 Worker {}", worker.id);
            
            if let Some(thread) = worker.thread.take() {
                thread.join().unwrap();
            }
        }
    }
}
```

## 10.3 项目三：待办事项 CLI

### 数据结构

```rust
// src/lib.rs
use serde::{Deserialize, Serialize};
use std::fs;

#[derive(Serialize, Deserialize, Debug)]
struct Todo {
    id: u64,
    title: String,
    completed: bool,
}

#[derive(Default)]
pub struct TodoList {
    todos: Vec<Todo>,
    next_id: u64,
}

impl TodoList {
    pub fn new() -> Self {
        TodoList {
            todos: Vec::new(),
            next_id: 1,
        }
    }
    
    pub fn load(path: &str) -> Result<Self, Box<dyn std::error::Error>> {
        let contents = fs::read_to_string(path)?;
        let todos: Vec<Todo> = serde_json::from_str(&contents)?;
        let next_id = todos.iter().map(|t| t.id).max().unwrap_or(0) + 1;
        
        Ok(TodoList { todos, next_id })
    }
    
    pub fn save(&self, path: &str) -> Result<(), Box<dyn std::error::Error>> {
        let contents = serde_json::to_string_pretty(&self.todos)?;
        fs::write(path, contents)?;
        Ok(())
    }
    
    pub fn add(&mut self, title: String) -> &Todo {
        let todo = Todo {
            id: self.next_id,
            title,
            completed: false,
        };
        self.next_id += 1;
        self.todos.push(todo);
        self.todos.last().unwrap()
    }
    
    pub fn complete(&mut self, id: u64) -> Option<&Todo> {
        self.todos
            .iter_mut()
            .find(|t| t.id == id)
            .map(|t| {
                t.completed = true;
                t
            })
    }
    
    pub fn list(&self) -> &[Todo] {
        &self.todos
    }
    
    pub fn remove(&mut self, id: u64) -> Option<Todo> {
        if let Some(pos) = self.todos.iter().position(|t| t.id == id) {
            Some(self.todos.remove(pos))
        } else {
            None
        }
    }
}
```

### 命令行界面

```rust
// src/main.rs
use todo_lib::TodoList;
use std::env;

fn main() {
    let args: Vec<String> = env::args().collect();
    let mut todo_list = TodoList::load("todos.json")
        .unwrap_or_else(|_| TodoList::new());
    
    match args.get(1).map(|s| s.as_str()) {
        Some("add") => {
            let title = args.get(2).unwrap_or_else(|| {
                eprintln!("请提供标题");
                std::process::exit(1);
            });
            let todo = todo_list.add(title.clone());
            println!("添加：{} (ID: {})", todo.title, todo.id);
        },
        Some("list") => {
            for todo in todo_list.list() {
                let status = if todo.completed { "✓" } else { " " };
                println!("[{}] {}: {}", status, todo.id, todo.title);
            }
        },
        Some("complete") => {
            let id: u64 = args.get(2)
                .and_then(|s| s.parse().ok())
                .unwrap_or_else(|| {
                    eprintln!("请提供有效的 ID");
                    std::process::exit(1);
                });
            
            if let Some(todo) = todo_list.complete(id) {
                println!("完成：{}", todo.title);
            } else {
                eprintln!("未找到 ID: {}", id);
            }
        },
        Some("remove") => {
            let id: u64 = args.get(2)
                .and_then(|s| s.parse().ok())
                .unwrap_or_else(|| {
                    eprintln!("请提供有效的 ID");
                    std::process::exit(1);
                });
            
            if let Some(todo) = todo_list.remove(id) {
                println!("移除：{}", todo.title);
            } else {
                eprintln!("未找到 ID: {}", id);
            }
        },
        _ => {
            eprintln!("用法:");
            eprintln!("  todo add <标题>     添加待办");
            eprintln!("  todo list           列出待办");
            eprintln!("  todo complete <ID>  完成待办");
            eprintln!("  todo remove <ID>    删除待办");
        },
    }
    
    todo_list.save("todos.json").unwrap();
}
```

### 使用示例

```bash
$ cargo run -- add "学习 Rust"
添加：学习 Rust (ID: 1)

$ cargo run -- add "写代码"
添加：写代码 (ID: 2)

$ cargo run -- list
[ ] 1: 学习 Rust
[ ] 2: 写代码

$ cargo run -- complete 1
完成：学习 Rust

$ cargo run -- list
[✓] 1: 学习 Rust
[ ] 2: 写代码
```

## 10.4 项目四：API 客户端

### HTTP 客户端

```rust
// Cargo.toml
[dependencies]
reqwest = { version = "0.11", features = ["json", "blocking"] }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
```

```rust
// src/main.rs
use reqwest::blocking::Client;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug)]
struct Post {
    userId: u32,
    id: Option<u32>,
    title: String,
    body: String,
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let client = Client::new();
    
    // GET 请求
    let response = client
        .get("https://jsonplaceholder.typicode.com/posts/1")
        .send()?;
    
    let post: Post = response.json()?;
    println!("获取帖子：{:?}", post);
    
    // POST 请求
    let new_post = Post {
        userId: 1,
        id: None,
        title: "我的帖子".to_string(),
        body: "这是内容".to_string(),
    };
    
    let response = client
        .post("https://jsonplaceholder.typicode.com/posts")
        .json(&new_post)
        .send()?;
    
    let created: Post = response.json()?;
    println!("创建帖子：{:?}", created);
    
    Ok(())
}
```

## 10.5 项目五：文件处理器

### 并行文件处理

```rust
use std::fs;
use std::io::{self, BufRead, Write};
use std::path::Path;
use std::thread;

fn process_file(path: &str) -> io::Result<usize> {
    let file = fs::File::open(path)?;
    let reader = io::BufReader::new(file);
    
    let mut line_count = 0;
    for line in reader.lines() {
        let _ = line?;
        line_count += 1;
    }
    
    Ok(line_count)
}

fn parallel_process(paths: Vec<String>) -> Vec<io::Result<usize>> {
    let mut handles = vec![];
    
    for path in paths {
        let handle = thread::spawn(move || {
            process_file(&path)
        });
        handles.push(handle);
    }
    
    handles.into_iter()
        .map(|h| h.join().unwrap())
        .collect()
}

fn main() -> io::Result<()> {
    let files = vec![
        "file1.txt".to_string(),
        "file2.txt".to_string(),
        "file3.txt".to_string(),
    ];
    
    let results = parallel_process(files);
    
    for (i, result) in results.iter().enumerate() {
        match result {
            Ok(count) => println!("文件 {}: {} 行", i + 1, count),
            Err(e) => println!("文件 {} 错误：{}", i + 1, e),
        }
    }
    
    Ok(())
}
```

## 10.6 最佳实践

### 项目结构

```
my_project/
├── Cargo.toml
├── Cargo.lock
├── src/
│   ├── main.rs      # 程序入口
│   ├── lib.rs       # 库代码
│   ├── bin/         # 多个二进制文件
│   ├── modules/     # 模块
│   └── utils.rs     # 工具函数
├── tests/           # 集成测试
├── benches/         # 基准测试
└── examples/        # 示例代码
```

### 代码组织

```rust
// 良好的模块结构
mod config;
mod database;
mod handlers;
mod models;
mod utils;

use config::Config;
use database::Database;
use handlers::RequestHandler;
```

### 测试

```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_add() {
        let mut list = TodoList::new();
        let todo = list.add("test".to_string());
        assert_eq!(todo.title, "test");
        assert!(!todo.completed);
    }
    
    #[test]
    fn test_complete() {
        let mut list = TodoList::new();
        list.add("test".to_string());
        list.complete(1);
        assert!(list.list()[0].completed);
    }
}
```

## 10.7 下一步

### 进阶主题

- 异步编程（async/await）
- 宏编程（macro）
- FFI（与其他语言交互）
- 性能优化
- 嵌入式 Rust

### 学习资源

- [The Rust Programming Language](https://doc.rust-lang.org/book/)
- [Rust by Example](https://doc.rust-lang.org/rust-by-example/)
- [Rustlings](https://github.com/rust-lang/rustlings)
- [Are we web yet?](https://www.arewewebyet.org/)

## 10.8 总结

恭喜你完成了 Rust 学习小册！你已经掌握了：

- ✅ Rust 基础语法和所有权系统
- ✅ 结构体、枚举和模式匹配
- ✅ 错误处理和泛型
- ✅ 生命周期和并发编程
- ✅ 实际项目开发

继续实践，参与开源项目，Rust 社区欢迎你！🦀

---

[上一章：并发编程 ←](09-concurrency.md)
