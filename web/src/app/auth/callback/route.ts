import { NextResponse } from "next/server";
import { createServerClient } from "@supabase/ssr";

/**
 * OAuth callback handler for Kakao / Apple sign-in.
 *
 * Flow:
 * 1. Supabase Auth redirects here with ?code=<auth_code>
 * 2. We exchange the code for a session (sets auth cookies)
 * 3. Redirect the user to `next` param or home page
 *
 * This route must NOT be a page.tsx — it's a server-side route handler
 * that needs to set cookies on the response before redirecting.
 */
export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url);
  const code = searchParams.get("code");
  const rawNext = searchParams.get("next") ?? "/";
  const next = rawNext.startsWith("/") && !rawNext.startsWith("//") && !rawNext.includes("@") ? rawNext : "/";

  if (!code) {
    // No code means the user cancelled or something went wrong
    return NextResponse.redirect(`${origin}/login?error=no_code`);
  }

  // Build a response we can attach cookies to
  const response = NextResponse.redirect(`${origin}${next}`);

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          // Parse cookies from the incoming request
          const cookieHeader = request.headers.get("cookie") ?? "";
          return cookieHeader.split(";").map((c) => {
            const [name, ...rest] = c.trim().split("=");
            return { name: name ?? "", value: rest.join("=") };
          }).filter((c) => c.name);
        },
        setAll(cookiesToSet) {
          for (const { name, value, options } of cookiesToSet) {
            response.cookies.set(name, value, options);
          }
        },
      },
    },
  );

  const { error } = await supabase.auth.exchangeCodeForSession(code);

  if (error) {
    // Exchange failed — redirect to login with error info
    return NextResponse.redirect(
      `${origin}/login?error=auth_exchange_failed`,
    );
  }

  return response;
}
