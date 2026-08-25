import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import SignOutButton from "@/components/sign-out-button";

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
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white border-b border-gray-200 px-6 py-4">
        <div className="max-w-6xl mx-auto flex justify-between items-center">
          <h1 className="text-xl font-bold text-gray-900">Dashboard</h1>
          <div className="flex items-center gap-4">
            <span className="text-sm text-gray-600">{user.email}</span>
            {isAdmin && (
              <Link
                href="/admin"
                className="text-sm bg-indigo-600 text-white px-3 py-1.5 rounded-md hover:bg-indigo-700 transition-colors"
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
          <p className="text-gray-500">No assets yet.</p>
        ) : (
          Object.entries(grouped).map(([projectName, projectAssets]) => (
            <section key={projectName} className="mb-10">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">{projectName}</h2>
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                {projectAssets.map((asset) => (
                  <div key={asset.id} className="bg-white rounded-lg border border-gray-200 overflow-hidden shadow-sm">
                    {isImage(asset.file_url) ? (
                      <img
                        src={asset.file_url}
                        alt={asset.title}
                        className="w-full h-40 object-cover"
                      />
                    ) : (
                      <div className="w-full h-40 bg-gray-100 flex items-center justify-center">
                        <span className="text-3xl">📄</span>
                      </div>
                    )}
                    <div className="p-3">
                      <p className="font-medium text-gray-900 text-sm">{asset.title}</p>
                      <p className="text-xs text-gray-500 mt-1">
                        {new Date(asset.created_at).toLocaleDateString()}
                      </p>
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
