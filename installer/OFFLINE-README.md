# AI Setup Hub 使用说明

## 第一步：恢复网络

- macOS：双击 `安装 Clash Verge.command`。如果系统阻止打开，请右键文件，选择“打开”。
- Windows：双击 `双击安装-Clash.bat`，并确认一次管理员权限。
- 安装助手会先校验包内官方安装文件，再安装 Clash Verge Rev。
- 你可以填写订阅链接，或选择本地 YAML 文件。
- 安装后请选择可用节点，并按需要开启“系统代理”。

## 第二步：安装 AI 工具

确认已经能够访问 GitHub 后，回到 AI Setup Hub 网站，用白名单内的 GitHub 账号登录并下载完整安装助手：

- macOS：双击 `安装 AI 工具.command`。
- Windows：双击 `联网后安装-AI工具.bat`。
- 助手会安装 CC Switch、Codex 和 OpenClaw。
- DeepSeek Key 在本机输入，不会发送给 AI Setup Hub 网站。
- Codex 只安装，不会修改你的登录或模型配置。

## 备份与日志

- 备份：用户目录下的 `AI-Setup-Hub-Backups`。
- macOS 日志：`~/Library/Logs/AI Setup Hub`。
- Windows 日志：`%LOCALAPPDATA%\AI Setup Hub\Logs`。

不要把日志、订阅链接或 API Key 发到公开 Issue。需要反馈时先检查并删除敏感信息。
