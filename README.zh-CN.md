# Chrome Side-by-Side Launchers

[English](README.md) · [中文](README.zh-CN.md)

> **一台 Mac，两个完全独立的 Chrome。**
>
> 用官方 Chrome Beta 和 Chrome Canary 创建两个清晰、独立的入口：
> `Google Chrome1` 和 `Google Chrome2`。

## 为什么需要这个项目？

你是否遇到过这些情况？

- 工作账号和个人账号的 Cookie、登录状态互相干扰
- 测试扩展时不想污染日常 Chrome
- 一个浏览器需要代理，另一个浏览器保持直连
- 想同时打开两个真正隔离的 Chrome，而不是在同一个 Chrome 里切 Profile

这个项目基于官方 side-by-side Chrome Beta 和 Chrome Canary，生成两个独立的
启动入口：

| 入口 | 官方构建 | 独立内容 |
| --- | --- | --- |
| Google Chrome1 | Chrome Beta | 登录状态、Cookie、历史记录、扩展、代理配置 |
| Google Chrome2 | Chrome Canary | 登录状态、Cookie、历史记录、扩展、网络配置 |

两个入口使用不同的官方 Bundle ID 和不同的 user-data 目录。它们可以和
Stable Chrome 同时运行，也不会修改官方应用包、代码签名或 Stable Chrome。

## 你会得到什么？

- **两个真正的应用身份**：使用官方 side-by-side Bundle ID
- **干净的内容隔离**：登录状态、Cookie、历史记录、扩展和会话彼此独立
- **按入口配置网络**：需要时只给 Google Chrome1 配置代理
- **保留官方更新能力**：不修改 Beta/Canary 应用包
- **简单的桌面入口**：生成 `Google Chrome1.app` 和 `Google Chrome2.app`

## 魔改接口

这个项目把启动器当作一个稳定的实验底座。你可以在不修改官方 Chrome 包的
情况下，为两个浏览器分别接入自己的实验参数和启动逻辑：

- `EXTRA_ARGS_1_FILE` / `EXTRA_ARGS_2_FILE`：每行写一个 Chrome 启动参数
- `BEFORE_LAUNCH_1` / `BEFORE_LAUNCH_2`：启动 Chrome 前执行的本地 Hook
- `PROFILE_1` / `PROFILE_2`：为不同实验使用不同数据目录
- `PROXY_1` / `PROXY_2`：分别配置两个浏览器的代理

参数文件示例：

```text
# 每行一个完整参数
--enable-features=SomeFeature
--load-extension=/path/to/local/extension
```

启动 Hook 会收到两个参数：`$1` 是 Profile 目录，`$2` 是 Chrome 可执行文件
路径。个人参数和 Hook 建议放在 `local/` 目录中；该目录已加入 `.gitignore`，
不会被提交到公开仓库。

## 快速开始

### 使用条件

- macOS 和受支持的 CPU 架构
- 已安装官方 Google Chrome Beta 和 Canary
- 系统提供 `zsh`、`PlistBuddy`、`codesign` 和 `plutil`

复制配置示例，并按实际安装位置修改：

```sh
cp config.example.env .env
${EDITOR:-vi} .env
```

创建启动器：

```sh
./scripts/create-launchers.sh
```

验证官方应用和生成的启动器：

```sh
./scripts/validate-install.sh
```

脚本不会自动覆盖已有启动器。确认目标路径后，如确实需要替换，可以使用
`FORCE=1`。

## 工作原理

生成器会先检查官方 Bundle ID 和代码签名，再创建一个很小的本地 `.app`
包装器。包装器直接调用官方 Beta 或 Canary 包内的可执行文件，并传入独立的
`--user-data-dir` 和可选代理参数。

官方 Chrome 二进制不会提交到仓库，浏览器 Profile、Cookie、截图、DMG、日志和
钥匙串数据也不会提交。

## 钥匙串提示

Chrome 首次使用 Safe Storage 时，macOS 可能请求访问钥匙串。请先确认弹窗中
显示的应用身份，再决定是否授权；不要把钥匙串条目授权给所有应用。

## 许可证

MIT，详见 [LICENSE](LICENSE)。
