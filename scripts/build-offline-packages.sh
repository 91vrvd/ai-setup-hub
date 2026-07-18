#!/bin/bash
set -Eeuo pipefail
IFS=$'\n\t'

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT="$ROOT/release-assets"
CACHE="$ROOT/work/package-cache"
mkdir -p "$OUTPUT" "$CACHE"

fetch() {
  local url="$1" target="$2" sha="$3"
  if [[ ! -f "$target" ]] || [[ "$(shasum -a 256 "$target" | awk '{print $1}')" != "$sha" ]]; then
    curl --fail --location --retry 3 --proto '=https' --tlsv1.2 "$url" -o "$target"
  fi
  [[ "$(shasum -a 256 "$target" | awk '{print $1}')" == "$sha" ]] || { echo "Checksum failed: $target" >&2; exit 1; }
}

write_windows_powershell() {
  node "$ROOT/scripts/write-windows-powershell.mjs" "$1" "$2"
}

package_mac() {
  local key="$1" arch="$2" asset="$3" sha="$4" url="$5" label="$6"
  local stage="$ROOT/work/package-$key"
  mkdir -p "$stage"
  cp "$ROOT/installer/macos/Install-Clash.command" "$stage/安装 Clash Verge.command"
  sed -i '' -e "s/__EXPECTED_ARCH__/$arch/g" -e "s/__DMG_NAME__/$asset/g" -e "s/__EXPECTED_SHA__/$sha/g" "$stage/安装 Clash Verge.command"
  chmod +x "$stage/安装 Clash Verge.command"
  fetch "$url" "$CACHE/$asset" "$sha"
  cp "$CACHE/$asset" "$stage/$asset"
  cp "$ROOT/installer/OFFLINE-README.md" "$stage/使用说明.md"
  (cd "$stage" && zip -qry "$OUTPUT/AI-Setup-Hub-Clash-macOS-$label.zip" .)
}

package_windows() {
  local key="$1" arch="$2" asset="$3" sha="$4" url="$5" label="$6"
  local stage="$ROOT/work/package-$key"
  mkdir -p "$stage"
  write_windows_powershell "$ROOT/installer/windows/Install-Clash.ps1" "$stage/Install-Clash.ps1"
  perl -0pi -e "s/__EXPECTED_ARCH__/$arch/g; s/__INSTALLER_NAME__/$asset/g; s/__EXPECTED_SHA__/$sha/g" "$stage/Install-Clash.ps1"
  cp "$ROOT/installer/windows/Start-Clash-Setup.bat" "$stage/双击安装-Clash.bat"
  fetch "$url" "$CACHE/$asset" "$sha"
  cp "$CACHE/$asset" "$stage/$asset"
  cp "$ROOT/installer/OFFLINE-README.md" "$stage/使用说明.md"
  (cd "$stage" && zip -qry "$OUTPUT/AI-Setup-Hub-Clash-Windows-$label.zip" .)
}

package_mac "mac-arm64" "arm64" "Clash.Verge_2.5.1_aarch64.dmg" "a2016a77922b67ac058b6c247aad7809893b429f238ee7aeee1fee6e3bf70e2b" "https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v2.5.1/Clash.Verge_2.5.1_aarch64.dmg" "Apple-Silicon"
package_mac "mac-x64" "x86_64" "Clash.Verge_2.5.1_x64.dmg" "bbe4894d80383510f4307e18d0bc6dfd89ccde4a8a82f3d6280989a902e5b04a" "https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v2.5.1/Clash.Verge_2.5.1_x64.dmg" "Intel"
package_windows "win-x64" "AMD64" "Clash.Verge_2.5.1_x64-setup.exe" "203bf29f7a5f0dc5fbc5e42772de6a474501603a19120c2f1259bb27c067df51" "https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v2.5.1/Clash.Verge_2.5.1_x64-setup.exe" "x64"
package_windows "win-arm64" "ARM64" "Clash.Verge_2.5.1_arm64-setup.exe" "26610cfd44a21cb95ae4c3e94a0ec8b412a30b06da4ee0e20cb70f122bc6a0d0" "https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v2.5.1/Clash.Verge_2.5.1_arm64-setup.exe" "ARM64"

cp "$ROOT/installer/macos/Install-AI-Tools.command" "$OUTPUT/AI-Setup-Hub-macOS.command"
chmod +x "$OUTPUT/AI-Setup-Hub-macOS.command"
WINDOWS_STAGE="$ROOT/work/package-ai-windows"
mkdir -p "$WINDOWS_STAGE"
write_windows_powershell "$ROOT/installer/windows/Install-AI-Tools.ps1" "$WINDOWS_STAGE/Install-AI-Tools.ps1"
cp "$ROOT/installer/windows/Start-AI-Setup.bat" "$WINDOWS_STAGE/双击安装-AI工具.bat"
(cd "$WINDOWS_STAGE" && zip -qry "$OUTPUT/AI-Setup-Hub-Windows.zip" .)

shasum -a 256 "$OUTPUT"/*.zip > "$OUTPUT/SHA256SUMS.txt"
echo "Offline packages created in $OUTPUT"
