import { redirect, notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import AssetReview from "@/components/asset-review";

export default async function AdminAssetPage({
  params,
}: {
  params: { projectId: string; assetId: string };
}) {
  const supabase = createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect("/login");

  const { data: membership } = await supabase
    .from("project_members")
    .select("project_id")
    .eq("user_id", user.id)
    .eq("project_id", params.projectId)
    .limit(1);

  if (!membership || membership.length === 0) notFound();

  const { data: asset } = await supabase
    .from("assets")
    .select("id, title, file_url, created_at, version, parent_asset_id, project_id, projects(name)")
    .eq("id", params.assetId)
    .eq("project_id", params.projectId)
    .single();

  if (!asset) notFound();

  return (
    <AssetReview
      assetId={asset.id}
      title={asset.title}
      fileUrl={asset.file_url}
      createdAt={asset.created_at}
      version={asset.version ?? 1}
      parentAssetId={asset.parent_asset_id}
      projectId={asset.project_id}
      projectName={
        Array.isArray(asset.projects)
          ? asset.projects[0]?.name ?? ""
          : (asset.projects as { name: string } | null)?.name ?? ""
      }
      currentUserId={user.id}
      currentUserEmail={user.email ?? ""}
      backHref={`/admin/projects/${params.projectId}`}
    />
  );
}
