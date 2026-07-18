import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({ variable: "--font-geist-sans", subsets: ["latin"] });
const geistMono = Geist_Mono({ variable: "--font-geist-mono", subsets: ["latin"] });

export const metadata: Metadata = {
  title: "AI Setup Hub｜新电脑一键配置",
  description: "安全安装 Clash Verge Rev、CC Switch、Codex 和 OpenClaw。Key 只在本机处理。",
  openGraph: {
    title: "AI Setup Hub｜新电脑一键配置",
    description: "先恢复网络，再一次装好 AI 工具。",
    type: "website",
    locale: "zh_CN",
    images: [{ url: "/og.png", width: 1200, height: 630, alt: "AI Setup Hub，新电脑一次装好" }],
  },
  twitter: { card: "summary_large_image", title: "AI Setup Hub", description: "新电脑一键配置", images: ["/og.png"] },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="zh-CN">
      <body className={`${geistSans.variable} ${geistMono.variable}`}>{children}</body>
    </html>
  );
}
