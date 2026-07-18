#!/bin/bash
set -Eeuo pipefail
IFS=$'\n\t'

ROOT="$(cd "$(dirname "$0")" && pwd)"
EXPECTED_ARCH="__EXPECTED_ARCH__"
DMG_NAME="__DMG_NAME__"
EXPECTED_SHA="__EXPECTED_SHA__"
BACKUP_ROOT="$HOME/AI-Setup-Hub-Backups/$(date +%Y%m%d-%H%M%S)"
LOG_DIR="$HOME/Library/Logs/AI Setup Hub"
mkdir -p "$LOG_DIR" "$BACKUP_ROOT"
LOG_FILE="$LOG_DIR/clash-bootstrap-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

fail() { printf '\n安装未完成：%s\n日志：%s\n' "$1" "$LOG_FILE"; read -r -p "按回车关闭…"; exit 1; }
trap 'fail "第 $LINENO 行发生错误"' ERR

printf '\nAI Setup Hub · 网络救援\n========================\n'
ACTUAL_ARCH="$(uname -m)"
[[ "$ACTUAL_ARCH" == "$EXPECTED_ARCH" ]] || fail "安装包架构为 $EXPECTED_ARCH，但这台 Mac 是 $ACTUAL_ARCH"
[[ -f "$ROOT/$DMG_NAME" ]] || fail "离线包缺少 $DMG_NAME"

printf '[1/4] 校验官方安装包…\n'
ACTUAL_SHA="$(shasum -a 256 "$ROOT/$DMG_NAME" | awk '{print $1}')"
[[ "$ACTUAL_SHA" == "$EXPECTED_SHA" ]] || fail "SHA-256 不一致，文件可能损坏"

printf '[2/4] 备份现有应用…\n'
if [[ -d "/Applications/Clash Verge.app" ]]; then
  ditto "/Applications/Clash Verge.app" "$BACKUP_ROOT/Clash Verge.app"
fi

printf '[3/4] 安装 Clash Verge Rev（系统可能要求输入密码）…\n'
MOUNT="$(hdiutil attach "$ROOT/$DMG_NAME" -nobrowse -readonly | awk '/\/Volumes\// {sub(/^.*\/Volumes\//,"/Volumes/"); print; exit}')"
APP_PATH="$(find "$MOUNT" -maxdepth 2 -name 'Clash Verge.app' -print -quit)"
[[ -n "$APP_PATH" ]] || fail "DMG 中没有找到 Clash Verge.app"
sudo ditto "$APP_PATH" "/Applications/Clash Verge.app"
hdiutil detach "$MOUNT" -quiet || true

printf '[4/4] 导入网络配置…\n'
open -a "/Applications/Clash Verge.app"
sleep 3
CHOICE="$(osascript -e 'button returned of (display dialog "你想怎样导入 Clash 配置？" buttons {"稍后自己设置", "选择 YAML", "填写订阅链接"} default button "填写订阅链接" with title "AI Setup Hub")')"
if [[ "$CHOICE" == "填写订阅链接" ]]; then
  SUB_URL="$(osascript -e 'text returned of (display dialog "请输入 Clash 订阅链接。链接只在本机处理。" default answer "" with hidden answer with title "AI Setup Hub")')"
  if [[ -n "$SUB_URL" ]]; then
    ENCODED="$(SETUP_SUB_URL="$SUB_URL" osascript -l JavaScript -e 'ObjC.import("stdlib"); encodeURIComponent($.getenv("SETUP_SUB_URL"))')"
    open "clash://install-config?url=$ENCODED"
    unset SUB_URL SETUP_SUB_URL ENCODED
  fi
elif [[ "$CHOICE" == "选择 YAML" ]]; then
  YAML_PATH="$(osascript -e 'POSIX path of (choose file with prompt "选择 Clash YAML 配置文件")')"
  open -R "$YAML_PATH"
  osascript -e 'display dialog "Clash 已打开。请把刚刚选中的 YAML 文件拖进 Clash 的订阅页面。" buttons {"知道了"} default button 1 with title "最后一步"'
fi

printf '\nClash Verge Rev 已安装。请选择可用节点，并按需要开启系统代理。\n备份：%s\n' "$BACKUP_ROOT"
read -r -p "按回车关闭…"
