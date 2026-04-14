import { type NextRequest, NextResponse } from "next/server";
import { updateSession } from "@/lib/supabase/middleware";
import { createServerClient } from "@supabase/ssr";

/** Routes that require authentication — redirect to /login if no session */
const PROTECTED_PREFIXES = ["/create", "/dashboard", "/my", "/crew", "/profile"];

/** Public sub-routes under protected prefixes (no auth required to view) */
const PUBLIC_EXCEPTIONS = ["/crew/join"];

export async function middleware(request: NextRequest) {
  // Always refresh the session cookie
  const response = await updateSession(request);

  // Check if this is a protected route
  const { pathname } = request.nextUrl;
  const isPublicException = PUBLIC_EXCEPTIONS.some((p) =>
    pathname.startsWith(p),
  );
  const isProtected =
    !isPublicException &&
    PROTECTED_PREFIXES.some((p) => pathname.startsWith(p));

  if (!isProtected) {
    return response;
  }

  // For protected routes, verify the user has a valid session
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll() {
          // No-op: cookies are already set by updateSession above
        },
      },
    },
  );

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    const loginUrl = request.nextUrl.clone();
    loginUrl.pathname = "/login";
    loginUrl.searchParams.set("next", pathname);
    return NextResponse.redirect(loginUrl);
  }

  return response;
}

export const config = {
  matcher: [
    // Match all routes except static files and _next internals
    "/((?!_next/static|_next/image|favicon.ico|sw.js|manifest.json|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)",
  ],
};
