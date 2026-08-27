import { redirect, notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import ProjectWorkspace from "@/components/project-workspace";

export default async function ProjectPage({
  params,
}: {
  params: { projectId: string };
}) {
  const supabase = createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect("/login");

  const { data: membership } = await supabase
    .from("project_members")
    .select("project_id, is_admin")
    .eq("user_id", user.id)
    .eq("project_id", params.projectId)
    .limit(1);

  if (!membership || membership.length === 0) notFound();

  const { data: project } = await supabase
    .from("projects")
    .select("id, name, status, created_at")
    .eq("id", params.projectId)
    .single();

  if (!project) notFound();

  const { data: members } = await supabase
    .from("project_members")
    .select("user_id, is_admin, profiles(email)")
    .eq("project_id", params.projectId);

  const memberList = (members ?? []).map(
    (m: Record<string, unknown>) => ({
      user_id: m.user_id as string,
      is_admin: m.is_admin as boolean,
      email:
        (m.profiles as { email: string } | null)?.email ?? "Unknown",
    })
  );

  const { data: assets } = await supabase
    .from("assets")
    .select("id, title, file_url, created_at, version, parent_asset_id")
    .eq("project_id", params.projectId)
    .order("created_at", { ascending: false });

  const assetRows = (assets ?? []) as {
    id: string;
    title: string;
    file_url: string;
    created_at: string;
    version: number;
    parent_asset_id: string | null;
  }[];

  const replacedIds = new Set(
    assetRows.filter((a) => a.parent_asset_id).map((a) => a.parent_asset_id)
  );
  const heads = assetRows.filter((a) => !replacedIds.has(a.id));

  const chains: Record<string, typeof assetRows> = {};
  for (const asset of assetRows) {
    const key = asset.parent_asset_id ?? asset.id;
    if (!chains[key]) chains[key] = [];
    chains[key].push(asset);
  }
  for (const key of Object.keys(chains)) {
    chains[key].sort((a, b) => b.version - a.version);
  }

  const screenData = heads.map((head) => {
    const chainKey = head.parent_asset_id ?? head.id;
    const chain = chains[chainKey] ?? [head];
    return {
      id: head.id,
      title: head.title,
      file_url: head.file_url,
      latestVersion: chain[0].version,
      totalVersions: chain.length,
      versions: chain.map((v) => ({
        id: v.id,
        version: v.version,
        file_url: v.file_url,
        created_at: v.created_at,
      })),
    };
  });

  const assetIds = assetRows.map((a) => a.id);

  const commentCounts: Record<string, number> = {};
  if (assetIds.length > 0) {
    const { data: comments } = await supabase
      .from("comments")
      .select("asset_id")
      .in("asset_id", assetIds);

    for (const c of comments ?? []) {
      commentCounts[c.asset_id] = (commentCounts[c.asset_id] ?? 0) + 1;
    }
  }

  const totalVersions = assetRows.length;
  const totalComments = Object.values(commentCounts).reduce(
    (sum, n) => sum + n,
    0
  );

  const client = memberList.find((m) => !m.is_admin);

  return (
    <ProjectWorkspace
      project={{
        id: project.id,
        name: project.name,
        status: project.status ?? "Active",
        created_at: project.created_at,
      }}
      clientEmail={client?.email ?? null}
      screens={screenData}
      commentCounts={commentCounts}
      totalVersions={totalVersions}
      totalComments={totalComments}
    />
  );
}
