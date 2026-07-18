# 安全设计

## 秘密信息

AI Setup Hub 网站不接收 DeepSeek API Key、Clash 订阅地址或 YAML。它们只在本地脚本运行期间进入内存，并写入目标软件正常工作所需的本机配置。

安装助手不启用命令追踪，不主动打印 Key。CC Switch 的官方深度链接导入需要短暂把 Key 交给本机协议处理器；链接不经过网页，但可能短暂出现在本机进程参数中。高安全需求用户应跳过自动导入，改在 CC Switch 界面手动填写。

## 供应链

- 固定经过检查的稳定版本。
- 对 Clash Verge Rev、CC Switch 和 Codex 的下载执行 SHA-256 校验。
- OpenClaw 使用官方 HTTPS 安装脚本，并在安装后核对版本和运行状态。
- 离线包不修改第三方二进制。

## 备份

安装前备份 OpenClaw、CC Switch 和 Codex 的非认证配置。Codex 的 `auth.json` 不复制进备份，避免扩大凭据暴露面。

## 报告问题

请使用 GitHub Security Advisory 报告安全问题。不要在公开 Issue 中提交 API Key、Token、订阅地址、完整日志或个人路径。
