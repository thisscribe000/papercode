import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import SignOutButton from "@/components/sign-out-button";
import ProjectsList from "@/components/projects-list";
import Link from "next/link";

/* eslint-disable @typescript-eslint/no-explicit-any */

export default async function AdminPage() {
  const supabase = createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect("/login");

  const { data: memberships } = await supabase
    .from("project_members")
    .select("project_id, is_admin")
    .eq("user_id", user.id)
    .eq("is_admin", true);

  if (!memberships || memberships.length === 0) {
    return (
      <div className="min-h-screen bg-slate-50">
        <header className="bg-white border-b border-slate-200">
          <div className="max-w-6xl mx-auto px-4 sm:px-6 py-3 flex items-center justify-between">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 bg-indigo-600 rounded-lg flex items-center justify-center">
                <svg className="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                </svg>
              </div>
              <span className="text-sm font-semibold text-slate-900">PaperCode</span>
            </div>
            <div className="flex items-center gap-4">
              <Link href="/dashboard" className="text-sm text-slate-500 hover:text-slate-700">
                Dashboard
              </Link>
              <SignOutButton />
            </div>
          </div>
        </header>
        <main className="max-w-6xl mx-auto px-4 sm:px-6 py-16 text-center">
          <p className="text-slate-500 text-sm">You don&apos;t have admin access to any projects.</p>
        </main>
      </div>
    );
  }

  const projectIds = memberships.map((m) => m.project_id);

  const { data: projects } = await supabase
    .from("projects")
    .select("id, name, status, created_at")
    .in("id", projectIds)
    .order("created_at", { ascending: false });

  const { data: assets } = await supabase
    .from("assets")
    .select("project_id")
    .in("project_id", projectIds);

  const { data: members } = await supabase
    .from("project_members")
    .select("project_id, user_id, is_admin, profiles(email)")
    .in("project_id", projectIds);

  const assetCounts: Record<string, number> = {};
  for (const a of assets ?? []) {
    assetCounts[a.project_id] = (assetCounts[a.project_id] ?? 0) + 1;
  }

  const assetIds = (assets ?? []).map((a: any) => a.id).filter(Boolean);

  const commentCounts: Record<string, number> = {};
  if (assetIds.length > 0) {
    const { data: comments } = await supabase
      .from("comments")
      .select("asset_id")
      .in("asset_id", assetIds);

    for (const c of comments ?? []) {
      const asset = (assets ?? []).find((a: any) => a.id === c.asset_id);
      if (asset) {
        commentCounts[asset.project_id] = (commentCounts[asset.project_id] ?? 0) + 1;
      }
    }
  }

  const memberMap: Record<string, { email: string; is_admin: boolean }[]> = {};
  for (const m of members ?? []) {
    const email = (m as any).profiles?.email ?? "";
    if (!memberMap[m.project_id]) memberMap[m.project_id] = [];
    memberMap[m.project_id].push({ email, is_admin: m.is_admin });
  }

  const projectData = (projects ?? []).map((p: any) => ({
    id: p.id,
    name: p.name,
    status: p.status ?? "Active",
    assetCount: assetCounts[p.id] ?? 0,
    commentCount: commentCounts[p.id] ?? 0,
    members: memberMap[p.id] ?? [],
  }));

  return (
    <div className="min-h-screen bg-slate-50">
      <header className="bg-white border-b border-slate-200">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 py-3 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 bg-indigo-600 rounded-lg flex items-center justify-center">
              <svg className="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
              </svg>
            </div>
            <span className="text-sm font-semibold text-slate-900">PaperCode</span>
          </div>
          <div className="flex items-center gap-4">
            <Link href="/dashboard" className="text-sm text-slate-500 hover:text-slate-700">
              Dashboard
            </Link>
            <SignOutButton />
          </div>
        </div>
      </header>
      <main className="max-w-6xl mx-auto px-4 sm:px-6 py-8">
        <ProjectsList initialProjects={projectData} currentUserId={user.id} />
      </main>
    </div>
  );
}
