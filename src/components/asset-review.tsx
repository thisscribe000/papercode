"use client";

import { useState, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

interface AssetVersion {
  id: string;
  title: string;
  file_url: string;
  created_at: string;
  version: number;
}

interface Comment {
  id: string;
  content: string;
  created_at: string;
  user_id: string;
  user_email: string;
}

interface Props {
  assetId: string;
  title: string;
  fileUrl: string;
  createdAt: string;
  version: number;
  parentAssetId: string | null;
  projectId: string;
  projectName: string;
  currentUserId: string;
  currentUserEmail: string;
}

export default function AssetReview({
  assetId,
  title,
  parentAssetId,
  projectName,
  currentUserId,
  currentUserEmail,
}: Props) {
  const supabase = createClient();
  const router = useRouter();
  const commentInputRef = useRef<HTMLTextAreaElement>(null);

  const [versions, setVersions] = useState<AssetVersion[]>([]);
  const [selectedVersion, setSelectedVersion] = useState<AssetVersion | null>(null);
  const [comments, setComments] = useState<Comment[]>([]);
  const [loadingVersions, setLoadingVersions] = useState(true);
  const [loadingComments, setLoadingComments] = useState(true);
  const [commentText, setCommentText] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editText, setEditText] = useState("");
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [error, setError] = useState("");

  useEffect(() => {
    const chainKey = parentAssetId ?? assetId;
    supabase
      .from("assets")
      .select("id, title, file_url, created_at, version")
      .or(`id.eq.${chainKey},parent_asset_id.eq.${chainKey}`)
      .order("version", { ascending: false })
      .then(({ data }) => {
        if (data) {
          setVersions(data);
          const current = data.find((v) => v.id === assetId) ?? data[0];
          setSelectedVersion(current);
        }
        setLoadingVersions(false);
      });
  }, [assetId, parentAssetId]);

  function fetchComments(verId: string) {
    setLoadingComments(true);
    supabase
      .from("comments")
      .select("id, content, created_at, user_id, user_email:user_id(email)")
      .eq("asset_id", verId)
      .order("created_at", { ascending: true })
      .then(({ data }) => {
        if (data) {
          setComments(
            data.map((c: Record<string, unknown>) => ({
              id: c.id as string,
              content: c.content as string,
              created_at: c.created_at as string,
              user_id: c.user_id as string,
              user_email:
                (c.user_email as { email: string } | null)?.email ?? "Unknown",
            }))
          );
        }
        setLoadingComments(false);
      });
  }

  useEffect(() => {
    if (selectedVersion) fetchComments(selectedVersion.id);
  }, [selectedVersion]);

  function switchVersion(v: AssetVersion) {
    setSelectedVersion(v);
    setError("");
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!commentText.trim() || !selectedVersion) return;
    setSubmitting(true);
    setError("");

    const { error } = await supabase.from("comments").insert({
      asset_id: selectedVersion.id,
      user_id: currentUserId,
      content: commentText.trim(),
    });

    if (error) {
      setError("Failed to post comment.");
    } else {
      setComments((prev) => [
        ...prev,
        {
          id: crypto.randomUUID(),
          content: commentText.trim(),
          created_at: new Date().toISOString(),
          user_id: currentUserId,
          user_email: currentUserEmail,
        },
      ]);
      setCommentText("");
    }
    setSubmitting(false);
  }

  async function handleUpdate(id: string) {
    if (!editText.trim()) return;
    const { error } = await supabase
      .from("comments")
      .update({ content: editText.trim(), updated_at: new Date().toISOString() })
      .eq("id", id);

    if (!error) {
      setComments((prev) =>
        prev.map((c) => (c.id === id ? { ...c, content: editText.trim() } : c))
      );
      setEditingId(null);
      setEditText("");
    }
  }

  async function handleDelete(id: string) {
    setDeletingId(id);
    const { error } = await supabase.from("comments").delete().eq("id", id);
    if (!error) {
      setComments((prev) => prev.filter((c) => c.id !== id));
    }
    setDeletingId(null);
  }

  function relativeTime(dateStr: string) {
    const diff = Date.now() - new Date(dateStr).getTime();
    const mins = Math.floor(diff / 60000);
    if (mins < 1) return "just now";
    if (mins < 60) return `${mins}m ago`;
    const hrs = Math.floor(mins / 60);
    if (hrs < 24) return `${hrs}h ago`;
    const days = Math.floor(hrs / 24);
    if (days < 7) return `${days}d ago`;
    return new Date(dateStr).toLocaleDateString();
  }

  const isLatest = selectedVersion?.id === versions[0]?.id;

  return (
    <div className="min-h-screen bg-white">
      {/* Header */}
      <header className="sticky top-0 z-10 bg-white/80 backdrop-blur-md border-b border-slate-100">
        <div className="max-w-5xl mx-auto px-4 sm:px-6 py-3 flex items-center gap-3">
          <button
            onClick={() => router.push("/dashboard")}
            className="p-1.5 -ml-1.5 text-slate-400 hover:text-slate-700 transition-colors"
          >
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
            </svg>
          </button>
          <div className="flex-1 min-w-0">
            <h1 className="text-sm font-semibold text-slate-900 truncate">{title}</h1>
            {projectName && (
              <p className="text-xs text-slate-400 truncate">{projectName}</p>
            )}
          </div>
          {selectedVersion && (
            <div className="flex items-center gap-1.5 text-xs text-slate-500 shrink-0">
              <span>v{selectedVersion.version}</span>
              {isLatest && versions.length > 1 && (
                <span className="text-[10px] font-medium bg-emerald-50 text-emerald-600 px-1.5 py-0.5 rounded-full">
                  Latest
                </span>
              )}
            </div>
          )}
        </div>
      </header>

      <main className="max-w-5xl mx-auto px-4 sm:px-6 py-6">
        <div className="lg:grid lg:grid-cols-[1fr,340px] lg:gap-8">
          {/* Left: preview + versions */}
          <div>
            {/* Design preview */}
            {loadingVersions ? (
              <div className="aspect-[4/3] bg-slate-50 rounded-xl flex items-center justify-center">
                <div className="text-sm text-slate-400">Loading...</div>
              </div>
            ) : selectedVersion ? (
              <div className="bg-slate-50 rounded-xl overflow-hidden">
                {isImage(selectedVersion.file_url) ? (
                  <img
                    src={selectedVersion.file_url}
                    alt={selectedVersion.title}
                    className="w-full h-auto"
                  />
                ) : (
                  <div className="aspect-[4/3] flex flex-col items-center justify-center gap-3">
                    <svg className="w-12 h-12 text-slate-300" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                    </svg>
                    <a
                      href={selectedVersion.file_url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-sm text-indigo-600 hover:underline"
                    >
                      Open file
                    </a>
                  </div>
                )}
              </div>
            ) : null}

            {/* Version info */}
            {selectedVersion && (
              <div className="mt-4 flex items-center gap-2 text-xs text-slate-500">
                <span>Version {selectedVersion.version}</span>
                {isLatest && versions.length > 1 && <span>· Latest</span>}
                <span>· Updated {new Date(selectedVersion.created_at).toLocaleDateString()}</span>
              </div>
            )}

            {/* Version selector */}
            {!loadingVersions && versions.length > 1 && (
              <div className="mt-6">
                <h3 className="text-xs font-medium text-slate-400 uppercase tracking-wider mb-3">Versions</h3>
                <div className="flex gap-2 overflow-x-auto pb-1">
                  {versions.map((v, i) => (
                    <button
                      key={v.id}
                      onClick={() => switchVersion(v)}
                      className={`shrink-0 px-3 py-2 rounded-lg text-xs font-medium transition-colors ${
                        selectedVersion?.id === v.id
                          ? "bg-indigo-600 text-white"
                          : "bg-slate-100 text-slate-600 hover:bg-slate-200"
                      }`}
                    >
                      v{v.version}
                      {i === 0 && versions.length > 1 && " · Latest"}
                    </button>
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* Right: comments */}
          <div className="mt-8 lg:mt-0">
            <h3 className="text-xs font-medium text-slate-400 uppercase tracking-wider mb-4">Feedback</h3>

            {loadingComments ? (
              <div className="py-8 text-center text-sm text-slate-400">Loading comments...</div>
            ) : comments.length === 0 ? (
              <div className="py-8 text-center">
                <p className="text-sm text-slate-400">No feedback yet.</p>
                <p className="text-xs text-slate-300 mt-1">Leave the first comment on this version.</p>
              </div>
            ) : (
              <div className="space-y-4 mb-6">
                {comments.map((c) => {
                  const isOwn = c.user_id === currentUserId;
                  return (
                    <div key={c.id} className="group">
                      {editingId === c.id ? (
                        <div>
                          <textarea
                            value={editText}
                            onChange={(e) => setEditText(e.target.value)}
                            className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm resize-none focus:outline-none focus:ring-1 focus:ring-indigo-500"
                            rows={2}
                          />
                          <div className="flex gap-2 mt-1.5">
                            <button
                              onClick={() => handleUpdate(c.id)}
                              className="text-xs font-medium text-indigo-600 hover:text-indigo-700"
                            >
                              Save
                            </button>
                            <button
                              onClick={() => { setEditingId(null); setEditText(""); }}
                              className="text-xs text-slate-400 hover:text-slate-600"
                            >
                              Cancel
                            </button>
                          </div>
                        </div>
                      ) : (
                        <div className="flex items-start justify-between gap-2">
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center gap-2">
                              <span className="text-xs font-medium text-slate-900">
                                {isOwn ? "You" : c.user_email}
                              </span>
                              <span className="text-[10px] text-slate-300">
                                {relativeTime(c.created_at)}
                              </span>
                            </div>
                            <p className="text-sm text-slate-600 mt-0.5 whitespace-pre-wrap">{c.content}</p>
                          </div>
                          {isOwn && (
                            <div className="relative shrink-0">
                              <MenuButton
                                onEdit={() => { setEditingId(c.id); setEditText(c.content); }}
                                onDelete={() => handleDelete(c.id)}
                                deleting={deletingId === c.id}
                              />
                            </div>
                          )}
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            )}

            {/* Comment input */}
            <form onSubmit={handleSubmit} className="sticky bottom-0 bg-white pt-2 pb-4">
              {error && (
                <p className="text-xs text-red-500 mb-2">{error}</p>
              )}
              <div className="flex gap-2 items-end">
                <textarea
                  ref={commentInputRef}
                  value={commentText}
                  onChange={(e) => setCommentText(e.target.value)}
                  placeholder="Leave feedback..."
                  rows={1}
                  className="flex-1 px-3 py-2 border border-slate-200 rounded-lg text-sm resize-none focus:outline-none focus:ring-1 focus:ring-indigo-500 min-h-[40px] max-h-[120px]"
                  onKeyDown={(e) => {
                    if (e.key === "Enter" && !e.shiftKey) {
                      e.preventDefault();
                      handleSubmit(e);
                    }
                  }}
                />
                <button
                  type="submit"
                  disabled={submitting || !commentText.trim()}
                  className="px-4 py-2 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-700 disabled:opacity-50 shrink-0"
                >
                  {submitting ? "Sending..." : "Send"}
                </button>
              </div>
            </form>
          </div>
        </div>
      </main>
    </div>
  );
}

function MenuButton({
  onEdit,
  onDelete,
  deleting,
}: {
  onEdit: () => void;
  onDelete: () => void;
  deleting: boolean;
}) {
  const [open, setOpen] = useState(false);

  return (
    <div className="relative">
      <button
        onClick={() => setOpen(!open)}
        className="p-1 text-slate-300 hover:text-slate-500 opacity-0 group-hover:opacity-100 transition-opacity"
      >
        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M12 5v.01M12 12v.01M12 19v.01" />
        </svg>
      </button>
      {open && (
        <>
          <div className="fixed inset-0 z-10" onClick={() => setOpen(false)} />
          <div className="absolute right-0 top-7 z-20 bg-white border border-slate-200 rounded-lg shadow-lg py-1 min-w-[100px]">
            <button
              onClick={() => { onEdit(); setOpen(false); }}
              className="w-full text-left px-3 py-1.5 text-xs text-slate-700 hover:bg-slate-50"
            >
              Edit
            </button>
            <button
              onClick={() => { onDelete(); setOpen(false); }}
              disabled={deleting}
              className="w-full text-left px-3 py-1.5 text-xs text-red-600 hover:bg-red-50 disabled:opacity-50"
            >
              {deleting ? "Deleting..." : "Delete"}
            </button>
          </div>
        </>
      )}
    </div>
  );
}

function isImage(url: string) {
  return /\.(jpg|jpeg|png|gif|webp|svg)$/i.test(url);
}
