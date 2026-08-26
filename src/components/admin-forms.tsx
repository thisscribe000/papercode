"use client";

import { useState, useEffect } from "react";
import { createClient } from "@/lib/supabase/client";

interface ExistingAsset {
  id: string;
  title: string;
  version: number;
}

export default function AdminForms() {
  const supabase = createClient();

  const [projects, setProjects] = useState<{ id: string; name: string }[]>([]);
  const [projectName, setProjectName] = useState("");
  const [projectMsg, setProjectMsg] = useState("");
  const [projectLoading, setProjectLoading] = useState(false);

  const [projectId, setProjectId] = useState("");
  const [title, setTitle] = useState("");
  const [file, setFile] = useState<File | null>(null);
  const [replaceAssetId, setReplaceAssetId] = useState("");
  const [existingAssets, setExistingAssets] = useState<ExistingAsset[]>([]);
  const [msg, setMsg] = useState("");
  const [loading, setLoading] = useState(false);

  function fetchProjects() {
    supabase
      .from("projects")
      .select("id, name")
      .order("name")
      .then(({ data }) => {
        if (data) setProjects(data);
      });
  }

  useEffect(() => {
    fetchProjects();
  }, []);

  useEffect(() => {
    if (!projectId) {
      setExistingAssets([]);
      setReplaceAssetId("");
      return;
    }
    supabase
      .from("assets")
      .select("id, title, version")
      .eq("project_id", projectId)
      .order("title")
      .then(({ data }) => {
        if (data) setExistingAssets(data);
      });
  }, [projectId]);

  async function handleCreateProject(e: React.FormEvent) {
    e.preventDefault();
    setProjectLoading(true);
    setProjectMsg("");

    const { data, error } = await supabase
      .from("projects")
      .insert({ name: projectName, status: "active" })
      .select("id, name");

    setProjectLoading(false);

    if (error) {
      setProjectMsg(`Error: ${error.message}`);
    } else {
      setProjectMsg("Project created!");
      if (data && data.length > 0) {
        setProjects((prev) => [...prev, data[0]]);
      }
      setProjectName("");
    }
  }

  async function handleUpload(e: React.FormEvent) {
    e.preventDefault();
    if (!file || !projectId || !title) return;

    setLoading(true);
    setMsg("");

    const path = `${projectId}/${file.name}`;

    const { error: uploadErr } = await supabase.storage
      .from("assets")
      .upload(path, file);

    if (uploadErr) {
      setMsg(`Upload failed: ${uploadErr.message}`);
      setLoading(false);
      return;
    }

    const { data: urlData } = supabase.storage.from("assets").getPublicUrl(path);

    const insertData: Record<string, unknown> = {
      title,
      file_url: urlData.publicUrl,
      project_id: projectId,
      version: 1,
    };

    if (replaceAssetId) {
      const replaced = existingAssets.find((a) => a.id === replaceAssetId);
      insertData.parent_asset_id = replaceAssetId;
      insertData.version = (replaced?.version ?? 1) + 1;
    }

    const { error: dbErr } = await supabase.from("assets").insert(insertData);

    setLoading(false);

    if (dbErr) {
      setMsg(`DB insert failed: ${dbErr.message}`);
    } else {
      setMsg(replaceAssetId ? "New version uploaded!" : "Uploaded!");
      setTitle("");
      setFile(null);
      setReplaceAssetId("");
    }
  }

  return (
    <div className="max-w-md space-y-8">
      <div>
        <h2 className="text-lg font-semibold text-slate-900 mb-3">Create a Project</h2>
        <form onSubmit={handleCreateProject} className="flex gap-2">
          <input
            type="text"
            placeholder="Project name"
            value={projectName}
            onChange={(e) => setProjectName(e.target.value)}
            required
            className="flex-1 px-3 py-2 border border-slate-300 rounded-lg text-sm"
          />
          <button
            type="submit"
            disabled={projectLoading}
            className="px-4 py-2 bg-slate-800 text-white text-sm font-medium rounded-lg hover:bg-slate-700 disabled:opacity-50"
          >
            {projectLoading ? "..." : "Create"}
          </button>
        </form>
        {projectMsg && (
          <p className={`mt-2 text-sm ${projectMsg.startsWith("Error") ? "text-red-600" : "text-green-600"}`}>
            {projectMsg}
          </p>
        )}
      </div>

      <hr className="border-slate-200" />

      <div>
        <h2 className="text-lg font-semibold text-slate-900 mb-3">Upload an Asset</h2>
        <form onSubmit={handleUpload} className="space-y-3">
          <select
            value={projectId}
            onChange={(e) => setProjectId(e.target.value)}
            required
            className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm"
          >
            <option value="">Pick a project</option>
            {projects.map((p) => (
              <option key={p.id} value={p.id}>
                {p.name}
              </option>
            ))}
          </select>

          {existingAssets.length > 0 && (
            <select
              value={replaceAssetId}
              onChange={(e) => setReplaceAssetId(e.target.value)}
              className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm"
            >
              <option value="">New asset (no replacement)</option>
              {existingAssets.map((a) => (
                <option key={a.id} value={a.id}>
                  Replace: {a.title} (v{a.version})
                </option>
              ))}
            </select>
          )}

          <input
            type="text"
            placeholder="Title"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            required
            className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm"
          />

          <input
            type="file"
            onChange={(e) => setFile(e.target.files?.[0] ?? null)}
            required
            className="w-full text-sm"
          />

          <button
            type="submit"
            disabled={loading}
            className="px-4 py-2 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-700 disabled:opacity-50"
          >
            {loading ? "Uploading..." : replaceAssetId ? "Upload new version" : "Upload"}
          </button>
        </form>

        {msg && (
          <p className={`mt-3 text-sm ${msg.startsWith("Uploaded") ? "text-green-600" : "text-red-600"}`}>
            {msg}
          </p>
        )}
      </div>
    </div>
  );
}
