import type { Provider } from "@supabase/supabase-js";
import { createClient } from "./supabase/client";

/**
 * Build the OAuth redirect URL for the current environment.
 * Always points to /auth/callback which exchanges the code for a session.
 */
function getRedirectUrl(): string {
  if (typeof window !== "undefined") {
    return `${window.location.origin}/auth/callback`;
  }
  // Fallback for SSR — NEXT_PUBLIC_SITE_URL must be set in production
  const siteUrl =
    process.env.NEXT_PUBLIC_SITE_URL ??
    process.env.NEXT_PUBLIC_VERCEL_URL ??
    "http://localhost:3000";
  const base = siteUrl.startsWith("http") ? siteUrl : `https://${siteUrl}`;
  return `${base}/auth/callback`;
}

/**
 * Initiate Kakao OAuth sign-in via Supabase Auth.
 *
 * Supabase Dashboard prerequisites:
 * 1. Enable Kakao provider under Authentication → Providers
 * 2. Set Kakao REST API Key as Client ID
 * 3. Set Kakao Client Secret
 * 4. Add redirect URL: <site>/auth/callback
 *
 * Scopes requested: profile_nickname, profile_image, account_email
 */
export async function signInWithKakao(redirectTo?: string) {
  const supabase = createClient();
  const callbackUrl = new URL(getRedirectUrl());

  // Preserve the page the user was on so we can redirect back after login
  if (redirectTo) {
    callbackUrl.searchParams.set("next", redirectTo);
  }

  return supabase.auth.signInWithOAuth({
    provider: "kakao" as Provider,
    options: {
      redirectTo: callbackUrl.toString(),
      queryParams: {
        // Request minimal scopes for MVP
        scope: "profile_nickname profile_image account_email",
      },
    },
  });
}

/**
 * Initiate Apple OAuth sign-in via Supabase Auth (fallback provider).
 *
 * Supabase Dashboard prerequisites:
 * 1. Enable Apple provider under Authentication → Providers
 * 2. Configure Apple Service ID, Team ID, Key ID, and private key
 * 3. Add redirect URL: <site>/auth/callback
 */
export async function signInWithApple(redirectTo?: string) {
  const supabase = createClient();
  const callbackUrl = new URL(getRedirectUrl());

  if (redirectTo) {
    callbackUrl.searchParams.set("next", redirectTo);
  }

  return supabase.auth.signInWithOAuth({
    provider: "apple",
    options: {
      redirectTo: callbackUrl.toString(),
    },
  });
}

/**
 * Sign the current user out and clear the session.
 */
export async function signOut() {
  const supabase = createClient();
  return supabase.auth.signOut();
}

/**
 * Get the current authenticated user (client-side).
 * Returns null if not authenticated.
 */
export async function getCurrentUser() {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  return user;
}
