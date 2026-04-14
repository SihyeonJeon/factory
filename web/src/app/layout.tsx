import type { Metadata, Viewport } from "next";
import { Noto_Sans_KR } from "next/font/google";
import { PwaProvider } from "@/components/pwa/pwa-provider";
import { ExternalBrowserBanner } from "@/components/kakao/external-browser-banner";
import { BottomNav } from "@/components/nav/bottom-nav";
import "./globals.css";

const notoSansKR = Noto_Sans_KR({
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
  variable: "--font-sans",
  display: "swap",
});

export const metadata: Metadata = {
  title: "모먼트 — 프라이빗 모임 운영 플랫폼",
  description:
    "60초 만에 감성 이벤트 페이지를 만들고 카카오톡으로 공유하세요. 앱 설치 없이 RSVP, 참석 대시보드, 사진 타임라인, 정산까지.",
  manifest: "/manifest.json",
  appleWebApp: {
    capable: true,
    statusBarStyle: "default",
    title: "모먼트",
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 5,
  userScalable: true,
  viewportFit: "cover",
  themeColor: "#ffffff",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ko" className={`${notoSansKR.variable} h-full antialiased`}>
      <body className="min-h-full flex flex-col font-sans safe-top safe-bottom">
        <ExternalBrowserBanner />
        {children}
        <BottomNav />
        <PwaProvider />
      </body>
    </html>
  );
}
