"use client";

import { useCallback, useEffect, useState } from "react";
import type { User } from "@supabase/supabase-js";
import { getSupabase } from "./supabase";

type Member = { github_username: string; role: "admin" | "member" };

const repo = process.env.NEXT_PUBLIC_GITHUB_REPO || "https://github.com/91vrvd/ai-setup-hub";
const releaseBase = `${repo}/releases/latest/download`;

export function AuthPanel() {
  const [user, setUser] = useState<User | null>(null);
  const [membership, setMembership] = useState<Member | null>(null);
  const [members, setMembers] = useState<Member[]>([]);
  const [newMember, setNewMember] = useState("");
  const supabase = getSupabase();
  const [status, setStatus] = useState(() => supabase ? "正在检查登录状态…" : "登录服务尚未配置，公开离线包仍可下载");

  const loadMembership = useCallback(async (nextUser: User | null) => {
    setUser(nextUser);
    if (!supabase || !nextUser) { setMembership(null); setStatus(nextUser ? "登录服务尚未配置" : "登录后可下载完整 AI 安装助手"); return; }
    const username = String(nextUser.user_metadata?.user_name || nextUser.user_metadata?.preferred_username || "").toLowerCase();
    const { data, error } = await supabase.from("allowed_users").select("github_username,role").eq("github_username", username).maybeSingle();
    if (error || !data) { setMembership(null); setStatus("这个 GitHub 账号不在白名单中，请联系管理员添加。"); return; }
    setMembership(data as Member);
    setStatus(`已通过白名单：@${username}`);
    if (data.role === "admin") {
      const result = await supabase.from("allowed_users").select("github_username,role").order("created_at");
      if (result.data) setMembers(result.data as Member[]);
    }
  }, [supabase]);

  useEffect(() => {
    if (!supabase) return;
    supabase.auth.getUser().then(({ data }) => loadMembership(data.user));
    const { data } = supabase.auth.onAuthStateChange((_event, session) => loadMembership(session?.user ?? null));
    return () => data.subscription.unsubscribe();
  }, [loadMembership, supabase]);

  async function signIn() {
    if (!supabase) { setStatus("部署者需要先配置 Supabase GitHub 登录"); return; }
    await supabase.auth.signInWithOAuth({ provider: "github", options: { redirectTo: `${window.location.origin}/#account` } });
  }

  async function signOut() { await supabase?.auth.signOut(); setMembership(null); }

  async function addMember() {
    const username = newMember.trim().replace(/^@/, "").toLowerCase();
    if (!supabase || !username) return;
    const { error } = await supabase.from("allowed_users").insert({ github_username: username, role: "member" });
    if (error) { setStatus(`添加失败：${error.message}`); return; }
    setMembers((list) => [...list, { github_username: username, role: "member" }]);
    setNewMember(""); setStatus(`已添加 @${username}`);
  }

  async function removeMember(username: string) {
    if (!supabase || !confirm(`确定移除 @${username}？`)) return;
    const { error } = await supabase.from("allowed_users").delete().eq("github_username", username);
    if (!error) setMembers((list) => list.filter((item) => item.github_username !== username));
  }

  return (
    <section className="account shell" id="account">
      <div className="account-copy">
        <span className="account-kicker">02 · 完整安装助手</span>
        <h2>网络恢复后，登录继续。</h2>
        <p>GitHub 白名单只控制完整 AI 安装助手。离线 Clash 救援包永远可以直接下载。</p>
        <div className="account-status"><span className={membership ? "ok" : ""} />{status}</div>
        {!user ? <button className="github-button" onClick={signIn}>使用 GitHub 登录 <b>↗</b></button> : <button className="text-button" onClick={signOut}>退出 {String(user.user_metadata?.user_name || "GitHub")}</button>}
      </div>
      <div className="member-card">
        {!membership ? (
          <div className="locked"><div className="lock-icon">⌁</div><h3>等待白名单验证</h3><p>通过后这里会出现 macOS 和 Windows 完整安装助手。</p></div>
        ) : (
          <div>
            <div className="member-head"><div><small>ACCESS GRANTED</small><h3>完整 AI 安装助手</h3></div><span>@{membership.github_username}</span></div>
            <a className="asset-link" href={`${releaseBase}/AI-Setup-Hub-macOS.command`}><span><b>macOS</b><small>Apple Silicon / Intel 自动识别</small></span><em>下载 ↓</em></a>
            <a className="asset-link" href={`${releaseBase}/AI-Setup-Hub-Windows.zip`}><span><b>Windows 10 / 11</b><small>x64 / ARM64 自动识别</small></span><em>下载 ↓</em></a>
            {membership.role === "admin" && <div className="admin-box"><label htmlFor="github-user">添加 GitHub 白名单</label><div><input id="github-user" value={newMember} onChange={(event) => setNewMember(event.target.value)} placeholder="GitHub 用户名" /><button onClick={addMember}>添加</button></div>{members.length > 0 && <ul>{members.map((member) => <li key={member.github_username}><span>@{member.github_username} · {member.role}</span>{member.role !== "admin" && <button onClick={() => removeMember(member.github_username)}>移除</button>}</li>)}</ul>}</div>}
          </div>
        )}
      </div>
    </section>
  );
}
