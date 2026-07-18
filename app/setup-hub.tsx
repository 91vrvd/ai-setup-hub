"use client";

import { useEffect, useMemo, useState } from "react";

type Platform = "mac-arm64" | "mac-x64" | "win-x64" | "win-arm64";

const repo = process.env.NEXT_PUBLIC_GITHUB_REPO || "https://github.com/91vrvd/ai-setup-hub";
const releaseBase = `${repo}/releases/latest/download`;

const platforms: Record<Platform, { label: string; detail: string; file: string; badge: string }> = {
  "mac-arm64": { label: "Apple 芯片 Mac", detail: "M1 / M2 / M3 / M4 / M5", file: "AI-Setup-Hub-Clash-macOS-Apple-Silicon.zip", badge: "推荐" },
  "mac-x64": { label: "Intel 芯片 Mac", detail: "2019 年及更早的部分 Mac", file: "AI-Setup-Hub-Clash-macOS-Intel.zip", badge: "Intel" },
  "win-x64": { label: "Windows x64", detail: "绝大多数 Windows 10 / 11", file: "AI-Setup-Hub-Clash-Windows-x64.zip", badge: "常用" },
  "win-arm64": { label: "Windows ARM64", detail: "骁龙 X 等 ARM 电脑", file: "AI-Setup-Hub-Clash-Windows-ARM64.zip", badge: "ARM" },
};

function detectPlatform(): Platform {
  if (typeof navigator === "undefined") return "win-x64";
  const ua = navigator.userAgent.toLowerCase();
  const platform = navigator.platform?.toLowerCase() ?? "";
  if (ua.includes("mac") || platform.includes("mac")) return "mac-arm64";
  if (ua.includes("arm64") || ua.includes("aarch64")) return "win-arm64";
  return "win-x64";
}

export function SetupHub() {
  const [selected, setSelected] = useState<Platform>("win-x64");
  const [detected, setDetected] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const [notice, setNotice] = useState<string | null>(null);

  useEffect(() => {
    const timer = window.setTimeout(() => {
      setSelected(detectPlatform());
      setDetected(true);
    }, 0);
    return () => window.clearTimeout(timer);
  }, []);

  const selectedInfo = useMemo(() => platforms[selected], [selected]);
  const aiToolsAsset = selected.startsWith("mac")
    ? { label: "macOS", detail: "Apple 芯片 / Intel 自动识别", file: "AI-Setup-Hub-macOS.command" }
    : { label: "Windows 10 / 11", detail: "x64 / ARM64 自动识别", file: "AI-Setup-Hub-Windows.zip" };

  function beginDownload() {
    setNotice(`正在获取 ${selectedInfo.label} 离线包…`);
    window.location.href = `${releaseBase}/${selectedInfo.file}`;
    window.setTimeout(() => setNotice("如果下载没有开始，请打开 GitHub Releases 手动下载。"), 1800);
  }

  return (
    <main>
      <nav className="nav shell" aria-label="主导航">
        <a className="brand" href="#top" aria-label="AI Setup Hub 首页">
          <span className="brand-mark">AI</span>
          <span>Setup Hub</span>
        </a>
        <div className="nav-links">
          <a href="#flow">安装流程</a>
          <a href="#software">包含软件</a>
          <a href="#security">安全说明</a>
          <a href="#ai-tools">直接装 AI</a>
          <a className="github-link" href={repo} target="_blank" rel="noreferrer">GitHub 开源 ↗</a>
        </div>
        <button className="menu-button" onClick={() => setMenuOpen((value) => !value)} aria-expanded={menuOpen}>菜单</button>
        {menuOpen && <div className="mobile-menu"><a href="#flow">安装流程</a><a href="#security">安全说明</a><a href={repo}>GitHub</a></div>}
      </nav>

      <section className="hero shell" id="top">
        <div className="hero-copy">
          <div className="eyebrow"><span className="pulse" /> 新电脑，不再从零折腾</div>
          <h1>先恢复网络，<br /><span>再一次装好 AI。</span></h1>
          <p className="hero-lead">一个公开透明的装机助手。网络不通时先离线安装 Clash Verge Rev；网络已经正常，就直接安装 CC Switch、Codex 和 OpenClaw。</p>
          <div className="trust-row">
            <span>✓ Key 只留本机</span><span>✓ 官方安装包</span><span>✓ SHA-256 校验</span>
          </div>
        </div>

        <aside className="download-card" aria-labelledby="download-title">
          <div className="card-topline"><span>01</span><span>网络不通时才需要</span></div>
          <h2 id="download-title">需要安装 Clash？</h2>
          <p>下载包内已包含 Clash Verge Rev，不依赖新电脑提前访问 GitHub。</p>
          <a className="skip-clash" href="#ai-tools"><span><b>网络已经正常</b><small>无需下载 Clash，直接安装 AI 工具</small></span><em>跳过 →</em></a>
          <div className="platform-grid">
            {(Object.entries(platforms) as [Platform, (typeof platforms)[Platform]][]).map(([key, item]) => (
              <button key={key} onClick={() => setSelected(key)} className={`platform-option ${selected === key ? "selected" : ""}`} aria-pressed={selected === key}>
                <span className="radio" />
                <span><strong>{item.label}</strong><small>{item.detail}</small></span>
                <em>{item.badge}</em>
              </button>
            ))}
          </div>
          <button className="primary-button" onClick={beginDownload}>下载 {selectedInfo.label} 离线包 <span>↓</span></button>
          <div className="detected">{detected ? `已根据当前浏览器推荐：${platforms[detectPlatform()].label}` : "正在识别系统…"}</div>
          {notice && <div className="notice" role="status">{notice}</div>}
        </aside>
      </section>

      <section className="flow-section" id="flow">
        <div className="shell">
          <div className="section-heading"><span>HOW IT WORKS</span><h2>根据网络状态，选择入口</h2><p>网络不通先用离线包；网络已经正常，第一步可以直接跳过。</p></div>
          <div className="flow-grid">
            <article><div className="step-number">1</div><span className="step-tag offline">网络正常可跳过</span><h3>需要时恢复网络</h3><p>只有新电脑无法正常联网时，才需要解压并运行 Clash 离线安装助手。</p><ul><li>内置对应架构安装包</li><li>校验文件完整性</li><li>支持订阅链接或 YAML</li></ul></article>
            <div className="flow-arrow" aria-hidden="true">→</div>
            <article><div className="step-number">2</div><span className="step-tag online">无需登录</span><h3>直接安装 AI 工具</h3><p>只要网络已经正常，就能直接下载安装助手。已有配置会先备份。</p><ul><li>安装 CC Switch 与 Codex</li><li>安装并启动 OpenClaw</li><li>本机填写 DeepSeek Key</li></ul></article>
          </div>
        </div>
      </section>

      <section className="direct-setup shell" id="ai-tools">
        <div className="direct-copy">
          <span className="account-kicker">02 · 完整安装助手</span>
          <h2>网络正常？<br />从这里直接开始。</h2>
          <p>不需要账户，不需要 GitHub 登录。选择对应系统，下载后双击运行即可。Codex 只安装官方版本，不会修改你的登录和模型配置。</p>
          <div className="open-access"><span /> 公开下载 · 无账户限制</div>
        </div>
        <div className="direct-card">
          <div className="member-head"><div><small>DIRECT DOWNLOAD</small><h3>选择完整 AI 安装助手</h3></div><span>无需登录</span></div>
          <a className={`asset-link ${aiToolsAsset.label === "macOS" ? "recommended" : ""}`} href={`${releaseBase}/AI-Setup-Hub-macOS.command`}>
            <span><b>macOS</b><small>Apple 芯片 / Intel 自动识别</small></span><em>{aiToolsAsset.label === "macOS" ? "为你推荐 · " : ""}下载 ↓</em>
          </a>
          <a className={`asset-link ${aiToolsAsset.label.startsWith("Windows") ? "recommended" : ""}`} href={`${releaseBase}/AI-Setup-Hub-Windows.zip`}>
            <span><b>Windows 10 / 11</b><small>x64 / ARM64 自动识别</small></span><em>{aiToolsAsset.label.startsWith("Windows") ? "为你推荐 · " : ""}下载 ↓</em>
          </a>
          <div className="direct-note"><b>将会安装</b><span>CC Switch · Codex · OpenClaw</span><small>运行时再在本机填写 DeepSeek Key，网站不会收到 Key。</small></div>
        </div>
      </section>

      <section className="software shell" id="software">
        <div className="section-heading left"><span>WHAT YOU GET</span><h2>四个工具，各就各位</h2></div>
        <div className="software-grid">
          <article><div className="app-icon clash">CV</div><h3>Clash Verge Rev</h3><p>离线安装，支持订阅链接和本地 YAML。</p><span>网络入口</span></article>
          <article><div className="app-icon cc">CC</div><h3>CC Switch</h3><p>统一管理 Codex、OpenClaw 与 API 供应商。</p><span>配置中心</span></article>
          <article><div className="app-icon codex">⌁</div><h3>Codex</h3><p>只安装官方版本，不碰你的登录和模型设置。</p><span>保持默认</span></article>
          <article><div className="app-icon claw">OC</div><h3>OpenClaw</h3><p>单 Agent、DeepSeek、Gateway 与开机启动。</p><span>自动配置</span></article>
        </div>
      </section>

      <section className="security" id="security">
        <div className="shell security-grid">
          <div><div className="section-heading left light"><span>LOCAL FIRST</span><h2>你的 Key，网站看不见。</h2><p>DeepSeek Key、Clash 订阅和 YAML 都只在本地安装助手中处理，不经过网站服务器。</p></div><a href={`${repo}/blob/main/SECURITY.md`} target="_blank" rel="noreferrer">查看完整安全设计 →</a></div>
          <div className="security-terminal" aria-label="安全流程示意">
            <div className="terminal-head"><span /><span /><span /><em>AI Setup Hub · Local</em></div>
            <code><b>$</b> 输入 DeepSeek Key</code>
            <code><b>✓</b> 本地校验，不上传</code>
            <code><b>✓</b> 写入应用所需的本机配置</code>
            <code><b>✓</b> 安装日志自动隐藏敏感字段</code>
            <div className="terminal-status"><span /> SERVER RECEIVED: 0 SECRETS</div>
          </div>
        </div>
      </section>

      <section className="requirements shell">
        <div><span>支持系统</span><strong>macOS 12+ · Windows 10 / 11</strong></div>
        <div><span>支持架构</span><strong>Apple Silicon · Intel · x64 · ARM64</strong></div>
        <div><span>人工操作</span><strong>系统授权一次 · Codex 登录自行完成</strong></div>
      </section>

      <footer><div className="shell"><div className="brand"><span className="brand-mark">AI</span><span>Setup Hub</span></div><p>给每一台新电脑，一个干净的开始。</p><div><a href={repo}>源代码</a><a href={`${repo}/issues`}>问题反馈</a><a href={`${repo}/blob/main/PRIVACY.md`}>隐私</a></div></div></footer>
    </main>
  );
}
