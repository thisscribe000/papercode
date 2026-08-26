import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import SignOutButton from "@/components/sign-out-button";
import AssetCard from "@/components/asset-card";

interface RawAsset {
  id: string;
  title: string;
  file_url: string;
  created_at: string;
  version: number;
  parent_asset_id: string | null;
  project_name: { name: string } | null;
}

interface AssetVersion {
  id: string;
  title: string;
  file_url: string;
  created_at: string;
  version: number;
}

export default async function DashboardPage() {
  const supabase = createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect("/login");

  const { data: memberships } = await supabase
    .from("project_members")
    .select("project_id")
    .eq("user_id", user.id)
    .eq("is_admin", true)
    .limit(1);

  const isAdmin = (memberships ?? []).length > 0;

  const { data: assets } = await supabase
    .from("assets")
    .select("id, title, file_url, created_at, version, parent_asset_id, project_name:projects(name)")
    .order("created_at", { ascending: false });

  const raw: RawAsset[] = (assets ?? []).map((a: Record<string, unknown>) => ({
    id: a.id as string,
    title: a.title as string,
    file_url: a.file_url as string,
    created_at: a.created_at as string,
    version: (a.version as number) ?? 1,
    parent_asset_id: (a.parent_asset_id as string) ?? null,
    project_name: a.project_name as { name: string } | null,
  }));

  const replacedIds = new Set(raw.filter((a) => a.parent_asset_id).map((a) => a.parent_asset_id));

  const heads = raw.filter((a) => !replacedIds.has(a.id));

  const chains: Record<string, AssetVersion[]> = {};
  for (const asset of raw) {
    const key = asset.parent_asset_id ?? asset.id;
    if (!chains[key]) chains[key] = [];
    chains[key].push({
      id: asset.id,
      title: asset.title,
      file_url: asset.file_url,
      created_at: asset.created_at,
      version: asset.version,
    });
  }
  for (const key of Object.keys(chains)) {
    chains[key].sort((a, b) => b.version - a.version);
  }

  const grouped: Record<string, { latest: AssetVersion; older: AssetVersion[]; total: number }[]> = {};
  for (const head of heads) {
    const chainKey = head.parent_asset_id ?? head.id;
    const chain = chains[chainKey] ?? [head];
    const latest = chain[0];
    const older = chain.slice(1);
    const projectName = head.project_name?.name ?? "Unknown Project";
    if (!grouped[projectName]) grouped[projectName] = [];
    grouped[projectName].push({ latest, older, total: chain.length });
  }

  return (
    <div className="min-h-screen bg-slate-50">
      <header className="bg-white border-b border-slate-200">
        <div className="max-w-6xl mx-auto px-6 py-3 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 bg-indigo-600 rounded-lg flex items-center justify-center">
              <svg className="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
              </svg>
            </div>
            <span className="text-sm font-semibold text-slate-900">Client Portal</span>
          </div>
          <div className="flex items-center gap-4">
            <span className="text-sm text-slate-500">{user.email}</span>
            {isAdmin && (
              <Link
                href="/admin"
                className="text-sm font-medium text-indigo-600 hover:text-indigo-700 transition-colors"
              >
                Admin
              </Link>
            )}
            <SignOutButton />
          </div>
        </div>
      </header>

      <main className="max-w-6xl mx-auto px-6 py-8">
        {Object.keys(grouped).length === 0 ? (
          <div className="text-center py-16">
            <div className="w-12 h-12 bg-slate-200 rounded-full flex items-center justify-center mx-auto mb-4">
              <svg className="w-6 h-6 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
              </svg>
            </div>
            <p className="text-slate-500 text-sm">No assets yet.</p>
          </div>
        ) : (
          Object.entries(grouped).map(([projectName, projectAssets]) => (
            <section key={projectName} className="mb-10">
              <h2 className="text-base font-semibold text-slate-900 mb-4">{projectName}</h2>
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                {projectAssets.map((item) => (
                  <AssetCard
                    key={item.latest.id}
                    latest={item.latest}
                    olderVersions={item.older}
                    totalVersions={item.total}
                  />
                ))}
              </div>
            </section>
          ))
        )}
      </main>
    </div>
  );
}
