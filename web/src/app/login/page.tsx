import type { Metadata } from "next";
import { LoginView } from "@/components/auth/login-view";

export const metadata: Metadata = {
  title: "로그인 — 모먼트",
  description: "카카오 또는 Apple 계정으로 로그인하세요.",
};

interface LoginPageProps {
  searchParams: Promise<{ error?: string; next?: string }>;
}

export default async function LoginPage({ searchParams }: LoginPageProps) {
  const { error, next } = await searchParams;
  return <LoginView error={error} redirectTo={next} />;
}
