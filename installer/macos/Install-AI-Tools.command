#!/bin/bash
set -Eeuo pipefail
IFS=$'\n\t'

ROOT="$(cd "$(dirname "$0")" && pwd)"
ARCH="$(uname -m)"
BACKUP_ROOT="$HOME/AI-Setup-Hub-Backups/$(date +%Y%m%d-%H%M%S)"
WORK_DIR="$(mktemp -d)"
LOG_DIR="$HOME/Library/Logs/AI Setup Hub"
mkdir -p "$BACKUP_ROOT" "$LOG_DIR" "$HOME/.local/bin"
LOG_FILE="$LOG_DIR/ai-tools-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1
trap 'rm -rf "$WORK_DIR"' EXIT
fail() { printf '\n安装未完成：%s\n日志：%s\n备份：%s\n' "$1" "$LOG_FILE" "$BACKUP_ROOT"; read -r -p "按回车关闭…"; exit 1; }
trap 'fail "第 $LINENO 行发生错误"' ERR

download_verify() {
  local url="$1" target="$2" sha="$3"
  curl --fail --location --retry 3 --proto '=https' --tlsv1.2 "$url" -o "$target"
  [[ "$(shasum -a 256 "$target" | awk '{print $1}')" == "$sha" ]] || fail "$(basename "$target") 校验失败"
}

backup_path() {
  local source="$1" label="$2"
  [[ -e "$source" ]] && ditto "$source" "$BACKUP_ROOT/$label"
}

printf '\nAI Setup Hub · AI 工具安装\n===========================\n'
curl --fail --silent --max-time 15 https://github.com >/dev/null || fail "网络尚未恢复，请先运行 Clash 并确认可以访问 GitHub"

printf '[1/7] 备份已有配置…\n'
backup_path "$HOME/.openclaw" "openclaw"
backup_path "$HOME/.cc-switch" "cc-switch"
[[ -f "$HOME/.codex/config.toml" ]] && ditto "$HOME/.codex/config.toml" "$BACKUP_ROOT/codex-config.toml"

printf '[2/7] 安装 CC Switch 3.17.0…\n'
CC_DMG="$WORK_DIR/cc-switch.dmg"
download_verify "https://github.com/farion1231/cc-switch/releases/download/v3.17.0/CC-Switch-v3.17.0-macOS.dmg" "$CC_DMG" "18647ef31cc8a3a2c177ab41007406dca9cabafc7e0f69b2faee1d505d9f0889"
CC_MOUNT="$(hdiutil attach "$CC_DMG" -nobrowse -readonly | awk '/\/Volumes\// {sub(/^.*\/Volumes\//,"/Volumes/"); print; exit}')"
CC_APP="$(find "$CC_MOUNT" -maxdepth 2 -name 'CC Switch.app' -print -quit)"
[[ -n "$CC_APP" ]] || fail "CC Switch DMG 内容异常"
sudo ditto "$CC_APP" "/Applications/CC Switch.app"
hdiutil detach "$CC_MOUNT" -quiet || true

printf '[3/7] 安装官方 Codex 0.144.5（不修改登录与模型）…\n'
if [[ "$ARCH" == "arm64" ]]; then
  CODEX_URL="https://github.com/openai/codex/releases/download/rust-v0.144.5/codex-aarch64-apple-darwin.tar.gz"
  CODEX_SHA="a5b77d2fb393f201777809425ab28d9beb65ee0c0b2bf792f09eaf8ef1151592"
else
  CODEX_URL="https://github.com/openai/codex/releases/download/rust-v0.144.5/codex-x86_64-apple-darwin.tar.gz"
  CODEX_SHA="ff5c894a9ffa6d97c225c8d3c869c7ef7573dcbd0cf9b762ecfb9fa96dbb7d88"
fi
CODEX_TAR="$WORK_DIR/codex.tar.gz"
download_verify "$CODEX_URL" "$CODEX_TAR" "$CODEX_SHA"
tar -xzf "$CODEX_TAR" -C "$WORK_DIR"
CODEX_BIN="$(find "$WORK_DIR" -type f -name 'codex*apple-darwin' -perm +111 -print -quit)"
[[ -n "$CODEX_BIN" ]] || CODEX_BIN="$(find "$WORK_DIR" -type f -name codex -print -quit)"
[[ -n "$CODEX_BIN" ]] || fail "Codex 压缩包内容异常"
install -m 0755 "$CODEX_BIN" "$HOME/.local/bin/codex"
grep -q 'HOME/.local/bin' "$HOME/.zprofile" 2>/dev/null || printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$HOME/.zprofile"
export PATH="$HOME/.local/bin:$PATH"

printf '[4/7] 安装 OpenClaw 2026.7.1…\n'
curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install.sh -o "$WORK_DIR/openclaw-install.sh"
bash "$WORK_DIR/openclaw-install.sh" --no-onboard
export PATH="$HOME/.openclaw/bin:$HOME/.local/bin:$PATH"
OPENCLAW_BIN="$(command -v openclaw || true)"
[[ -n "$OPENCLAW_BIN" ]] || fail "OpenClaw 已安装但命令不在 PATH"

printf '[5/7] 配置 DeepSeek（输入不会显示）…\n'
read -r -s -p "DeepSeek API Key: " DEEPSEEK_KEY
printf '\n'
[[ -n "$DEEPSEEK_KEY" ]] || fail "DeepSeek Key 不能为空"
"$OPENCLAW_BIN" plugins install @openclaw/deepseek-provider
"$OPENCLAW_BIN" onboard --non-interactive --mode local --auth-choice deepseek-api-key --deepseek-api-key "$DEEPSEEK_KEY" --skip-health --accept-risk

printf '[6/7] 设置 Gateway 开机启动并验证…\n'
"$OPENCLAW_BIN" gateway install || true
"$OPENCLAW_BIN" gateway restart || true
"$OPENCLAW_BIN" doctor || true

printf '[7/7] 将 DeepSeek 添加到 CC Switch…\n'
open -a "/Applications/CC Switch.app"
sleep 3
ENCODED_KEY="$(SETUP_DEEPSEEK_KEY="$DEEPSEEK_KEY" osascript -l JavaScript -e 'ObjC.import("stdlib"); encodeURIComponent($.getenv("SETUP_DEEPSEEK_KEY"))')"
CC_URL="ccswitch://v1/import?resource=provider&app=openclaw&name=DeepSeek&endpoint=https%3A%2F%2Fapi.deepseek.com&apiKey=$ENCODED_KEY&homepage=https%3A%2F%2Fplatform.deepseek.com&model=deepseek%2Fdeepseek-v4-flash&enabled=true"
open "$CC_URL"
unset DEEPSEEK_KEY SETUP_DEEPSEEK_KEY ENCODED_KEY CC_URL

open http://127.0.0.1:18789/ || true
printf '\n安装完成。Codex 保持官方默认，请在需要时自行运行 codex login。\n备份：%s\n日志：%s\n' "$BACKUP_ROOT" "$LOG_FILE"
read -r -p "按回车关闭…"
