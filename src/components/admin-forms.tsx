"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";

export default function AdminForms() {
  const supabase = createClient();

  // Create project
  const [projectName, setProjectName] = useState("");
  const [projectStatus, setProjectStatus] = useState("active");
  const [projectMsg, setProjectMsg] = useState("");
  const [projectLoading, setProjectLoading] = useState(false);

  // Add client to project
  const [clientId, setClientId] = useState("");
  const [clientEmail, setClientEmail] = useState("");
  const [clientRole, setClientRole] = useState("client");
  const [clientMsg, setClientMsg] = useState("");
  const [clientLoading, setClientLoading] = useState(false);

  // Upload asset
  const [assetTitle, setAssetTitle] = useState("");
  const [assetProjectId, setAssetProjectId] = useState("");
  const [assetFile, setAssetFile] = useState<File | null>(null);
  const [assetMsg, setAssetMsg] = useState("");
  const [assetLoading, setAssetLoading] = useState(false);

  async function handleCreateProject(e: React.FormEvent) {
    e.preventDefault();
    setProjectLoading(true);
    setProjectMsg("");

    const { error } = await supabase
      .from("projects")
      .insert({ name: projectName, status: projectStatus });

    setProjectLoading(false);
    if (error) {
      setProjectMsg(`Error: ${error.message}`);
    } else {
      setProjectMsg("Project created.");
      setProjectName("");
      setProjectStatus("active");
    }
  }

  async function handleAddClient(e: React.FormEvent) {
    e.preventDefault();
    setClientLoading(true);
    setClientMsg("");

    let userId = clientId;

    if (!userId && clientEmail) {
      const { data: profiles } = await supabase
        .from("profiles")
        .select("id")
        .eq("email", clientEmail)
        .single();

      if (profiles) {
        userId = profiles.id;
      } else {
        setClientLoading(false);
        setClientMsg("No user found with that email.");
        return;
      }
    }

    if (!userId) {
      setClientLoading(false);
      setClientMsg("Provide a user_id or email.");
      return;
    }

    const { error } = await supabase
      .from("project_members")
      .insert({
        user_id: userId,
        role: clientRole,
        is_admin: clientRole === "admin",
      });

    setClientLoading(false);
    if (error) {
      setClientMsg(`Error: ${error.message}`);
    } else {
      setClientMsg("Client added to project.");
      setClientId("");
      setClientEmail("");
    }
  }

  async function handleUploadAsset(e: React.FormEvent) {
    e.preventDefault();
    if (!assetFile || !assetProjectId || !assetTitle) return;

    setAssetLoading(true);
    setAssetMsg("");

    const filePath = `${assetProjectId}/${Date.now()}_${assetFile.name}`;
    const { error: uploadError } = await supabase.storage
      .from("assets")
      .upload(filePath, assetFile);

    if (uploadError) {
      setAssetLoading(false);
      setAssetMsg(`Upload error: ${uploadError.message}`);
      return;
    }

    const { data: urlData } = supabase.storage
      .from("assets")
      .getPublicUrl(filePath);

    const { error: insertError } = await supabase.from("assets").insert({
      title: assetTitle,
      file_url: urlData.publicUrl,
      project_id: assetProjectId,
    });

    setAssetLoading(false);
    if (insertError) {
      setAssetMsg(`DB error: ${insertError.message}`);
    } else {
      setAssetMsg("Asset uploaded.");
      setAssetTitle("");
      setAssetFile(null);
      setAssetProjectId("");
    }
  }

  return (
    <div className="space-y-10">
      {/* Create Project */}
      <section className="bg-white rounded-lg border border-gray-200 p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Create Project</h2>
        <form onSubmit={handleCreateProject} className="space-y-3 max-w-md">
          <input
            type="text"
            placeholder="Project name"
            value={projectName}
            onChange={(e) => setProjectName(e.target.value)}
            required
            className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
          />
          <select
            value={projectStatus}
            onChange={(e) => setProjectStatus(e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
          >
            <option value="active">Active</option>
            <option value="archived">Archived</option>
          </select>
          <button
            type="submit"
            disabled={projectLoading}
            className="px-4 py-2 bg-indigo-600 text-white text-sm rounded-md hover:bg-indigo-700 disabled:opacity-50"
          >
            {projectLoading ? "Creating..." : "Create project"}
          </button>
          {projectMsg && <p className="text-sm text-gray-600">{projectMsg}</p>}
        </form>
      </section>

      {/* Add Client to Project */}
      <section className="bg-white rounded-lg border border-gray-200 p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Add Client to Project</h2>
        <form onSubmit={handleAddClient} className="space-y-3 max-w-md">
          <input
            type="text"
            placeholder="User ID (uuid)"
            value={clientId}
            onChange={(e) => setClientId(e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
          />
          <p className="text-xs text-gray-400">— or look up by email —</p>
          <input
            type="email"
            placeholder="client@example.com"
            value={clientEmail}
            onChange={(e) => setClientEmail(e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
          />
          <select
            value={clientRole}
            onChange={(e) => setClientRole(e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
          >
            <option value="client">Client</option>
            <option value="admin">Admin</option>
          </select>
          <button
            type="submit"
            disabled={clientLoading}
            className="px-4 py-2 bg-indigo-600 text-white text-sm rounded-md hover:bg-indigo-700 disabled:opacity-50"
          >
            {clientLoading ? "Adding..." : "Add client"}
          </button>
          {clientMsg && <p className="text-sm text-gray-600">{clientMsg}</p>}
        </form>
      </section>

      {/* Upload Asset */}
      <section className="bg-white rounded-lg border border-gray-200 p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Upload Asset</h2>
        <form onSubmit={handleUploadAsset} className="space-y-3 max-w-md">
          <input
            type="text"
            placeholder="Asset title"
            value={assetTitle}
            onChange={(e) => setAssetTitle(e.target.value)}
            required
            className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
          />
          <input
            type="text"
            placeholder="Project ID (uuid)"
            value={assetProjectId}
            onChange={(e) => setAssetProjectId(e.target.value)}
            required
            className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
          />
          <input
            type="file"
            onChange={(e) => setAssetFile(e.target.files?.[0] ?? null)}
            required
            className="w-full text-sm text-gray-600"
          />
          <button
            type="submit"
            disabled={assetLoading}
            className="px-4 py-2 bg-indigo-600 text-white text-sm rounded-md hover:bg-indigo-700 disabled:opacity-50"
          >
            {assetLoading ? "Uploading..." : "Upload asset"}
          </button>
          {assetMsg && <p className="text-sm text-gray-600">{assetMsg}</p>}
        </form>
      </section>
    </div>
  );
}
