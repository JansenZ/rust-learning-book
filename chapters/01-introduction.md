# 第 1 章：Rust 简介和安装

## 1.1 什么是 Rust？

Rust 是一门系统编程语言，专注于**安全**、**并发**和**性能**。它由 Mozilla 研究团队开发，第一个稳定版本于 2015 年发布。

### Rust 的核心特点

- **内存安全**：无需垃圾回收器，通过所有权系统保证内存安全
- **零成本抽象**：高级特性不会带来运行时开销
- **并发安全**：编译时防止数据竞争
- **丰富的类型系统**：强大的类型推断和模式匹配

### 为什么选择 Rust？

```
🔒 内存安全 - 消除空指针、悬垂指针、缓冲区溢出
⚡ 高性能 - 与 C/C++ 相当的执行速度
🛠️ 优秀工具链 - Cargo 包管理器、rustfmt、clippy
📚 友好社区 - 完善的文档和活跃的社区支持
```

## 1.2 安装 Rust

### macOS / Linux

```bash
# 使用 rustup 安装（推荐）
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# 安装完成后，重启终端或运行：
source $HOME/.cargo/env

# 验证安装
rustc --version
cargo --version
```

### Windows

1. 访问 https://rustup.rs/
2. 下载 `rustup-init.exe`
3. 运行安装程序，按提示操作

### 验证安装

```bash
$ rustc --version
rustc 1.75.0 (82e1608df 2023-12-21)

$ cargo --version
cargo 1.75.0 (1d8b05cdd 2023-11-20)
```

## 1.3 更新和卸载

```bash
# 更新 Rust
rustup update

# 更新到特定版本
rustup update stable
rustup update nightly

# 卸载 Rust
rustup self uninstall
```

## 1.4 配置开发环境

### 编辑器推荐

- **VS Code** + rust-analyzer 插件（最流行）
- **IntelliJ IDEA** + Rust 插件
- **Neovim** + rust.vim

### VS Code 配置

1. 安装 Rust 官方插件：`rust-analyzer`
2. 可选插件：
   - `crates` - 依赖版本检查
   - `Better TOML` - TOML 文件支持

### 常用 Cargo 命令

```bash
# 创建新项目
cargo new my_project
cargo new --lib my_library

# 编译项目
cargo build
cargo build --release  # 优化编译

# 运行项目
cargo run

# 运行测试
cargo test

# 格式化代码
cargo fmt

# 代码检查
cargo clippy

# 查看依赖
cargo tree
```

## 1.5 第一个 Rust 程序

```bash
# 创建新项目
cargo new hello_rust
cd hello_rust
```

编辑 `src/main.rs`：

```rust
fn main() {
    println!("Hello, Rust!");
    println!("🦀 欢迎学习 Rust！");
}
```

运行程序：

```bash
$ cargo run
   Compiling hello_rust v0.1.0
    Finished dev [unoptimized + debuginfo] target(s)
     Running `target/debug/hello_rust`
Hello, Rust!
🦀 欢迎学习 Rust！
```

## 1.6 项目结构

```
hello_rust/
├── Cargo.toml      # 项目配置和依赖
├── Cargo.lock      # 依赖锁定文件
├── src/
│   └── main.rs     # 源代码
└── target/         # 编译输出（自动生成）
```

### Cargo.toml 示例

```toml
[package]
name = "hello_rust"
version = "0.1.0"
edition = "2021"

[dependencies]
# 在这里添加依赖
```

## 1.7 练习题

1. 安装 Rust 并验证版本
2. 创建一个新的 Cargo 项目
3. 修改程序输出你的名字
4. 尝试使用 `cargo build --release` 编译优化版本

## 1.8 小结

- Rust 是安全、并发、高性能的系统编程语言
- 使用 rustup 安装 Rust 是最简单的方式
- Cargo 是 Rust 的包管理器和构建工具
- `cargo new` 创建项目，`cargo run` 运行项目

---

[下一章：变量和数据类型 →](02-variables-types.md)
