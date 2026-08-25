import { createServerClient } from "@supabase/ssr";
import { NextResponse } from "next/server";

export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url);
  const code = searchParams.get("code");
  const next = searchParams.get("next") ?? "/dashboard";

  console.log("[auth/callback] code:", code ? "present" : "missing");

  if (code) {
    const supabaseResponse = NextResponse.next({ request });
    const cookieHeader = request.headers.get("cookie") ?? "";

    const supabase = createServerClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      {
        cookies: {
          getAll() {
            return cookieHeader
              .split(";")
              .map((c) => c.trim().split("="))
              .filter((c) => c.length >= 2)
              .map(([name, ...rest]) => ({
                name,
                value: decodeURIComponent(rest.join("=")),
              }));
          },
          setAll(cookiesToSet) {
            cookiesToSet.forEach(({ name, value, options }) =>
              supabaseResponse.cookies.set(name, value, options)
            );
          },
        },
      }
    );

    const { data, error } = await supabase.auth.exchangeCodeForSession(code);
    console.log("[auth/callback] exchange error:", error?.message ?? "none");
    console.log("[auth/callback] session user:", data?.user?.id ?? "none");

    if (!error) {
      return NextResponse.redirect(`${origin}${next}`, {
        headers: supabaseResponse.headers,
      });
    }
  }

  return NextResponse.redirect(`${origin}/login?error=auth_failed`);
}
