# AI Setup Hub

面向新电脑的开源安装入口：先用离线包安装 Clash Verge Rev，联网后再安装 CC Switch、Codex 和 OpenClaw。

## 支持范围

- macOS 12+：Apple Silicon、Intel
- Windows 10/11：x64、ARM64
- Clash Verge Rev 订阅链接或 YAML
- OpenClaw 单 Agent + DeepSeek + Gateway 开机启动
- Codex 官方版本，仅安装，不修改认证和模型配置

## 安全原则

- DeepSeek Key 和 Clash 配置只在本机处理。
- 下载的官方安装文件必须通过 SHA-256 校验。
- 安装前备份已有配置；失败时保留备份和已脱敏日志。
- 安装脚本、版本清单和打包过程全部公开。

## 本地开发

```bash
npm install
npm run dev
```

构建网站：

```bash
npm run build
```

生成四种离线包（会下载官方 Clash 安装文件）：

```bash
bash scripts/build-offline-packages.sh
```

## 重要提示

Windows 安装助手尚未在真实 Windows 设备上验收。请先阅读脚本，并在非关键设备上测试。遇到问题请提交脱敏后的 Issue。

## 上游项目

- [Clash Verge Rev](https://github.com/clash-verge-rev/clash-verge-rev) — GPL-3.0
- [CC Switch](https://github.com/farion1231/cc-switch) — MIT
- [Codex](https://github.com/openai/codex) — Apache-2.0
- [OpenClaw](https://github.com/openclaw/openclaw)

本仓库的原创代码采用 MIT License。离线包中的第三方软件仍受各自许可证约束。
