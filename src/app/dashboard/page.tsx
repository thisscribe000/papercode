import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import SignOutButton from "@/components/sign-out-button";
import AssetComments from "@/components/asset-comments";

interface Asset {
  id: string;
  title: string;
  file_url: string;
  created_at: string;
  project_name: string;
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
    .select("id, title, file_url, created_at, project_name:projects(name)")
    .order("created_at", { ascending: false });

  const grouped: Record<string, Asset[]> = {};
  (assets ?? []).forEach((asset: Record<string, unknown>) => {
    const project = asset.project_name as { name: string } | null;
    const projectName = project?.name ?? "Unknown Project";
    if (!grouped[projectName]) grouped[projectName] = [];
    grouped[projectName].push({
      id: asset.id as string,
      title: asset.title as string,
      file_url: asset.file_url as string,
      created_at: asset.created_at as string,
      project_name: projectName,
    });
  });

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
                {projectAssets.map((asset) => (
                  <div key={asset.id} className="bg-white rounded-xl border border-slate-200 overflow-hidden hover:shadow-md transition-shadow">
                    {isImage(asset.file_url) ? (
                      <img
                        src={asset.file_url}
                        alt={asset.title}
                        className="w-full h-36 object-cover"
                      />
                    ) : (
                      <div className="w-full h-36 bg-slate-100 flex items-center justify-center">
                        <svg className="w-8 h-8 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                        </svg>
                      </div>
                    )}
                    <div className="p-3">
                      <p className="font-medium text-slate-900 text-sm">{asset.title}</p>
                      <p className="text-xs text-slate-500 mt-1">
                        {new Date(asset.created_at).toLocaleDateString()}
                      </p>
                      <AssetComments assetId={asset.id} />
                    </div>
                  </div>
                ))}
              </div>
            </section>
          ))
        )}
      </main>
    </div>
  );
}

function isImage(url: string) {
  return /\.(jpg|jpeg|png|gif|webp|svg)$/i.test(url);
}
