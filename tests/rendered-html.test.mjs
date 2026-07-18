import assert from "node:assert/strict";
import { access, readFile } from "node:fs/promises";
import test from "node:test";

async function render() {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("test", `${process.pid}-${Date.now()}`);
  const { default: worker } = await import(workerUrl.href);

  return worker.fetch(
    new Request("http://localhost/", { headers: { accept: "text/html" } }),
    { ASSETS: { fetch: async () => new Response("Not found", { status: 404 }) } },
    { waitUntil() {}, passThroughOnException() {} },
  );
}

test("renders separate paths for offline recovery and direct AI setup", async () => {
  const response = await render();
  assert.equal(response.status, 200);
  assert.match(response.headers.get("content-type") ?? "", /^text\/html\b/i);

  const html = await response.text();
  assert.match(html, /<title>AI Setup Hub｜新电脑一键配置<\/title>/i);
  assert.match(html, /网络不通时才需要/);
  assert.match(html, /网络已经正常/);
  assert.match(html, /无需下载 Clash，直接安装 AI 工具/);
  assert.match(html, /公开下载 · 无账户限制/);
  assert.match(html, /AI-Setup-Hub-macOS\.command/);
  assert.match(html, /AI-Setup-Hub-Windows\.zip/);
  assert.doesNotMatch(html, /使用 GitHub 登录|等待白名单验证|登录服务尚未配置/);
});

test("removes the account stack and keeps downloads public", async () => {
  const [page, packageJson, privacy] = await Promise.all([
    readFile(new URL("../app/setup-hub.tsx", import.meta.url), "utf8"),
    readFile(new URL("../package.json", import.meta.url), "utf8"),
    readFile(new URL("../PRIVACY.md", import.meta.url), "utf8"),
  ]);

  assert.match(page, /href=\{`\$\{releaseBase\}\/AI-Setup-Hub-macOS\.command`\}/);
  assert.match(page, /href=\{`\$\{releaseBase\}\/AI-Setup-Hub-Windows\.zip`\}/);
  assert.doesNotMatch(page, /AuthPanel|Supabase|signInWithOAuth|allowed_users/);
  assert.doesNotMatch(packageJson, /supabase/i);
  assert.match(privacy, /不提供账户登录，也不维护用户白名单/);

  await assert.rejects(access(new URL("../app/auth-panel.tsx", import.meta.url)));
  await assert.rejects(access(new URL("../app/supabase.ts", import.meta.url)));
});
