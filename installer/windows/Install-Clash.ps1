$ErrorActionPreference = "Stop"
$ExpectedArch = "__EXPECTED_ARCH__"
$InstallerName = "__INSTALLER_NAME__"
$ExpectedSha = "__EXPECTED_SHA__"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupRoot = Join-Path $env:USERPROFILE "AI-Setup-Hub-Backups\$Stamp"
$LogDir = Join-Path $env:LOCALAPPDATA "AI Setup Hub\Logs"
New-Item -ItemType Directory -Force -Path $BackupRoot, $LogDir | Out-Null
$LogFile = Join-Path $LogDir "clash-bootstrap-$Stamp.log"
Start-Transcript -Path $LogFile | Out-Null

try {
  Write-Host "`nAI Setup Hub · 网络救援`n========================" -ForegroundColor Cyan
  $ActualArch = if ([Environment]::Is64BitOperatingSystem) {
    if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64" -or $env:PROCESSOR_ARCHITEW6432 -eq "ARM64") { "ARM64" } else { "AMD64" }
  } else { "x86" }
  if ($ActualArch -ne $ExpectedArch) { throw "安装包架构为 $ExpectedArch，但系统是 $ActualArch" }
  $Installer = Join-Path $Root $InstallerName
  if (-not (Test-Path $Installer)) { throw "离线包缺少 $InstallerName" }

  Write-Host "[1/4] 校验官方安装包…"
  if ((Get-FileHash $Installer -Algorithm SHA256).Hash.ToLowerInvariant() -ne $ExpectedSha) { throw "SHA-256 不一致，文件可能损坏" }

  Write-Host "[2/4] 备份现有配置…"
  $Candidates = @(
    "$env:APPDATA\io.github.clash-verge-rev.clash-verge-rev",
    "$env:APPDATA\clash-verge-rev"
  )
  foreach ($Path in $Candidates) { if (Test-Path $Path) { Copy-Item $Path $BackupRoot -Recurse -Force } }

  Write-Host "[3/4] 安装 Clash Verge Rev（可能出现 UAC 确认）…"
  $Process = Start-Process -FilePath $Installer -ArgumentList "/S" -Verb RunAs -Wait -PassThru
  if ($Process.ExitCode -ne 0) { throw "安装程序返回代码 $($Process.ExitCode)" }

  Write-Host "[4/4] 打开 Clash Verge Rev…"
  $ExeCandidates = @(
    "$env:ProgramFiles\Clash Verge\Clash Verge.exe",
    "$env:LOCALAPPDATA\Programs\Clash Verge\Clash Verge.exe"
  )
  $ClashExe = $ExeCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
  if ($ClashExe) { Start-Process $ClashExe; Start-Sleep -Seconds 3 }

  Add-Type -AssemblyName Microsoft.VisualBasic
  $Mode = [Microsoft.VisualBasic.Interaction]::InputBox("输入 1：订阅链接；输入 2：YAML 文件；留空：稍后设置", "AI Setup Hub", "1")
  if ($Mode -eq "1") {
    $SubUrl = [Microsoft.VisualBasic.Interaction]::InputBox("请输入 Clash 订阅链接。链接只在本机处理。", "AI Setup Hub", "")
    if ($SubUrl) { Start-Process ("clash://install-config?url=" + [Uri]::EscapeDataString($SubUrl)); $SubUrl = $null }
  } elseif ($Mode -eq "2") {
    Add-Type -AssemblyName System.Windows.Forms
    $Dialog = New-Object System.Windows.Forms.OpenFileDialog
    $Dialog.Filter = "YAML 配置 (*.yaml;*.yml)|*.yaml;*.yml|所有文件 (*.*)|*.*"
    if ($Dialog.ShowDialog() -eq "OK") {
      Start-Process explorer.exe -ArgumentList "/select,`"$($Dialog.FileName)`""
      [System.Windows.Forms.MessageBox]::Show("Clash 已打开。请把选中的 YAML 文件拖进订阅页面。", "AI Setup Hub") | Out-Null
    }
  }
  Write-Host "`n安装完成。请选择可用节点，并按需要开启系统代理。`n备份：$BackupRoot" -ForegroundColor Green
} catch {
  Write-Host "`n安装未完成：$($_.Exception.Message)`n日志：$LogFile" -ForegroundColor Red
  exit 1
} finally { Stop-Transcript | Out-Null }
Read-Host "按回车关闭"
