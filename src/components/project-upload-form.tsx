"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { useRouter } from "next/navigation";

interface ExistingScreen {
  id: string;
  title: string;
  latestVersion: number;
}

export default function ProjectUploadForm({
  projectId,
  projectName,
  existingScreens,
  onClose,
}: {
  projectId: string;
  projectName: string;
  existingScreens: ExistingScreen[];
  onClose: () => void;
}) {
  const supabase = createClient();
  const router = useRouter();

  const [title, setTitle] = useState("");
  const [file, setFile] = useState<File | null>(null);
  const [replaceAssetId, setReplaceAssetId] = useState("");
  const [loading, setLoading] = useState(false);
  const [msg, setMsg] = useState("");
  const [isError, setIsError] = useState(false);

  const selectedScreen = existingScreens.find((s) => s.id === replaceAssetId);

  async function handleUpload(e: React.FormEvent) {
    e.preventDefault();
    if (!file || !title) return;

    setLoading(true);
    setMsg("");
    setIsError(false);

    const path = `${projectId}/${Date.now()}_${file.name}`;

    const { error: uploadErr } = await supabase.storage
      .from("assets")
      .upload(path, file);

    if (uploadErr) {
      setMsg(`Upload failed: ${uploadErr.message}`);
      setIsError(true);
      setLoading(false);
      return;
    }

    const { data: urlData } = supabase.storage
      .from("assets")
      .getPublicUrl(path);

    const insertData: Record<string, unknown> = {
      title,
      file_url: urlData.publicUrl,
      project_id: projectId,
      version: 1,
    };

    if (replaceAssetId) {
      insertData.parent_asset_id = replaceAssetId;
      insertData.version = (selectedScreen?.latestVersion ?? 1) + 1;
    }

    const { error: dbErr } = await supabase.from("assets").insert(insertData);

    setLoading(false);

    if (dbErr) {
      setMsg(`DB insert failed: ${dbErr.message}`);
      setIsError(true);
    } else {
      setMsg(replaceAssetId ? "New version uploaded!" : "Screen uploaded!");
      setIsError(false);
      setTitle("");
      setFile(null);
      setReplaceAssetId("");
      router.refresh();
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/40" onClick={onClose} />
      <div className="relative bg-white rounded-2xl shadow-xl w-full max-w-md p-6">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-base font-semibold text-slate-900">
            {replaceAssetId ? "Upload New Version" : "Upload Screen"}
          </h2>
          <button
            onClick={onClose}
            className="p-1 text-slate-400 hover:text-slate-600 transition-colors"
          >
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <p className="text-xs text-slate-500 mb-4">
          Project: <span className="font-medium text-slate-700">{projectName}</span>
        </p>

        <form onSubmit={handleUpload} className="space-y-3">
          {existingScreens.length > 0 && (
            <div>
              <label className="block text-xs font-medium text-slate-500 mb-1">
                Replace existing screen
              </label>
              <select
                value={replaceAssetId}
                onChange={(e) => setReplaceAssetId(e.target.value)}
                className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
              >
                <option value="">New screen (no replacement)</option>
                {existingScreens.map((s) => (
                  <option key={s.id} value={s.id}>
                    {s.title} (v{s.latestVersion})
                  </option>
                ))}
              </select>
            </div>
          )}

          <div>
            <label className="block text-xs font-medium text-slate-500 mb-1">
              Screen title
            </label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              required
              placeholder="e.g. Login Screen"
              className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />
          </div>

          <div>
            <label className="block text-xs font-medium text-slate-500 mb-1">
              File
            </label>
            <input
              type="file"
              onChange={(e) => setFile(e.target.files?.[0] ?? null)}
              required
              className="w-full text-sm file:mr-3 file:py-1.5 file:px-3 file:rounded-lg file:border-0 file:text-sm file:font-medium file:bg-indigo-50 file:text-indigo-700 hover:file:bg-indigo-100 file:cursor-pointer"
            />
          </div>

          {replaceAssetId && selectedScreen && (
            <p className="text-xs text-slate-500 bg-slate-50 rounded-lg px-3 py-2">
              Will be uploaded as{" "}
              <span className="font-medium text-slate-700">
                v{selectedScreen.latestVersion + 1}
              </span>{" "}
              of <span className="font-medium text-slate-700">{selectedScreen.title}</span>
            </p>
          )}

          {msg && (
            <p className={`text-sm ${isError ? "text-red-600" : "text-green-600"}`}>
              {msg}
            </p>
          )}

          <div className="flex gap-2 pt-2">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 px-4 py-2 border border-slate-300 text-slate-700 text-sm font-medium rounded-lg hover:bg-slate-50 transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={loading}
              className="flex-1 px-4 py-2 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-700 disabled:opacity-50 transition-colors"
            >
              {loading
                ? "Uploading..."
                : replaceAssetId
                  ? "Upload Version"
                  : "Upload"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
