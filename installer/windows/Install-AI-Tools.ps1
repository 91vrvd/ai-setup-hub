$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupRoot = Join-Path $env:USERPROFILE "AI-Setup-Hub-Backups\$Stamp"
$LogDir = Join-Path $env:LOCALAPPDATA "AI Setup Hub\Logs"
$WorkDir = Join-Path $env:TEMP "ai-setup-hub-$Stamp"
New-Item -ItemType Directory -Force -Path $BackupRoot, $LogDir, $WorkDir | Out-Null
$LogFile = Join-Path $LogDir "ai-tools-$Stamp.log"
Start-Transcript -Path $LogFile | Out-Null

function Get-VerifiedFile([string]$Url, [string]$Target, [string]$Sha256) {
  Invoke-WebRequest -Uri $Url -OutFile $Target -UseBasicParsing
  if ((Get-FileHash $Target -Algorithm SHA256).Hash.ToLowerInvariant() -ne $Sha256) { throw "$(Split-Path $Target -Leaf) 校验失败" }
}

try {
  Write-Host "`nAI Setup Hub · AI 工具安装`n===========================" -ForegroundColor Cyan
  Invoke-WebRequest -Uri "https://github.com" -Method Head -TimeoutSec 15 -UseBasicParsing | Out-Null

  Write-Host "[1/7] 备份已有配置…"
  $Backups = @(
    @{ Path = "$env:USERPROFILE\.openclaw"; Name = "openclaw" },
    @{ Path = "$env:USERPROFILE\.cc-switch"; Name = "cc-switch" },
    @{ Path = "$env:USERPROFILE\.codex\config.toml"; Name = "codex-config.toml" }
  )
  foreach ($Item in $Backups) { if (Test-Path $Item.Path) { Copy-Item $Item.Path (Join-Path $BackupRoot $Item.Name) -Recurse -Force } }

  $Arch = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64" -or $env:PROCESSOR_ARCHITEW6432 -eq "ARM64") { "arm64" } else { "x64" }
  Write-Host "[2/7] 安装 CC Switch 3.17.0…"
  if ($Arch -eq "arm64") {
    $CcUrl = "https://github.com/farion1231/cc-switch/releases/download/v3.17.0/CC-Switch-v3.17.0-Windows-arm64.msi"
    $CcSha = "e3b5c01d4d12914f3f98f715d386aeddb9ceaa39981984cb05f3050163933b6e"
  } else {
    $CcUrl = "https://github.com/farion1231/cc-switch/releases/download/v3.17.0/CC-Switch-v3.17.0-Windows.msi"
    $CcSha = "c541e1981023cc5cfe4d8357ce9c57a712eb8949bf2ae8cd49b087c75762607b"
  }
  $CcMsi = Join-Path $WorkDir "cc-switch.msi"
  Get-VerifiedFile $CcUrl $CcMsi $CcSha
  $CcProc = Start-Process msiexec.exe -ArgumentList "/i `"$CcMsi`" /qn /norestart" -Verb RunAs -Wait -PassThru
  if ($CcProc.ExitCode -notin @(0,3010)) { throw "CC Switch 安装失败：$($CcProc.ExitCode)" }

  Write-Host "[3/7] 安装官方 Codex 0.144.5（不修改登录与模型）…"
  if ($Arch -eq "arm64") {
    $CodexUrl = "https://github.com/openai/codex/releases/download/rust-v0.144.5/codex-aarch64-pc-windows-msvc.exe"
    $CodexSha = "636afb6d2482177b1ca36cab3752fc948658f2f2bcca6cd159df740e278a49da"
  } else {
    $CodexUrl = "https://github.com/openai/codex/releases/download/rust-v0.144.5/codex-x86_64-pc-windows-msvc.exe"
    $CodexSha = "efdb3540ef74b9909408c8d38da79483454797b36f471e3e004fc2bf2b70e22a"
  }
  $BinDir = Join-Path $env:LOCALAPPDATA "Programs\AI Setup Hub\bin"
  New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
  Get-VerifiedFile $CodexUrl (Join-Path $BinDir "codex.exe") $CodexSha
  $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
  if (($UserPath -split ";") -notcontains $BinDir) { [Environment]::SetEnvironmentVariable("Path", ($UserPath.TrimEnd(";") + ";" + $BinDir), "User") }
  $env:Path = "$BinDir;$env:Path"

  Write-Host "[4/7] 安装 OpenClaw 2026.7.1…"
  $OpenClawInstaller = Join-Path $WorkDir "openclaw-install.ps1"
  Invoke-WebRequest -Uri "https://openclaw.ai/install.ps1" -OutFile $OpenClawInstaller -UseBasicParsing
  & $OpenClawInstaller -NoOnboard
  $env:Path = "$env:USERPROFILE\.openclaw\bin;$env:APPDATA\npm;$env:Path"
  $OpenClaw = Get-Command openclaw -ErrorAction SilentlyContinue
  if (-not $OpenClaw) { throw "OpenClaw 已安装但命令不在 PATH" }

  Write-Host "[5/7] 配置 DeepSeek…"
  $SecureKey = Read-Host "DeepSeek API Key（输入不会显示）" -AsSecureString
  $Ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureKey)
  try { $DeepSeekKey = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($Ptr) } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($Ptr) }
  if ([string]::IsNullOrWhiteSpace($DeepSeekKey)) { throw "DeepSeek Key 不能为空" }
  & openclaw plugins install '@openclaw/deepseek-provider'
  & openclaw onboard --non-interactive --mode local --auth-choice deepseek-api-key --deepseek-api-key $DeepSeekKey --skip-health --accept-risk

  Write-Host "[6/7] 设置 Gateway 开机启动并验证…"
  & openclaw gateway install
  & openclaw gateway restart
  & openclaw doctor

  Write-Host "[7/7] 将 DeepSeek 添加到 CC Switch…"
  $CcLink = "ccswitch://v1/import?resource=provider&app=openclaw&name=DeepSeek&endpoint=https%3A%2F%2Fapi.deepseek.com&apiKey=$([Uri]::EscapeDataString($DeepSeekKey))&homepage=https%3A%2F%2Fplatform.deepseek.com&model=deepseek%2Fdeepseek-v4-flash&enabled=true"
  Start-Process $CcLink
  $DeepSeekKey = $null; $SecureKey = $null; $CcLink = $null
  Start-Process "http://127.0.0.1:18789/"
  Write-Host "`n安装完成。Codex 保持官方默认，请在需要时自行运行 codex login。`n备份：$BackupRoot`n日志：$LogFile" -ForegroundColor Green
} catch {
  Write-Host "`n安装未完成：$($_.Exception.Message)`n日志：$LogFile`n备份：$BackupRoot" -ForegroundColor Red
  exit 1
} finally {
  Remove-Item $WorkDir -Recurse -Force -ErrorAction SilentlyContinue
  Stop-Transcript | Out-Null
}
Read-Host "按回车关闭"
