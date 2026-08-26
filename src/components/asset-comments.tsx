"use client";

import { useState, useEffect } from "react";
import { createClient } from "@/lib/supabase/client";

interface Comment {
  id: string;
  body: string;
  created_at: string;
  user_email: string;
}

export default function AssetComments({ assetId }: { assetId: string }) {
  const supabase = createClient();
  const [comments, setComments] = useState<Comment[]>([]);
  const [body, setBody] = useState("");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    supabase
      .from("comments")
      .select("id, body, created_at, user_email:profiles(email)")
      .eq("asset_id", assetId)
      .order("created_at", { ascending: true })
      .then(({ data }) => {
        if (!data) return;
        setComments(
          data.map((c: Record<string, unknown>) => ({
            id: c.id as string,
            body: c.body as string,
            created_at: c.created_at as string,
            user_email:
              (c.user_email as { email: string } | null)?.email ?? "Unknown",
          }))
        );
      });
  }, [assetId]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!body.trim()) return;

    setLoading(true);

    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      setLoading(false);
      return;
    }

    const { error } = await supabase.from("comments").insert({
      asset_id: assetId,
      user_id: user.id,
      body: body.trim(),
    });

    if (!error) {
      setComments((prev) => [
        ...prev,
        {
          id: crypto.randomUUID(),
          body: body.trim(),
          created_at: new Date().toISOString(),
          user_email: user.email ?? "Unknown",
        },
      ]);
      setBody("");
    }

    setLoading(false);
  }

  return (
    <div className="mt-3 border-t border-slate-100 pt-3">
      {comments.length > 0 && (
        <div className="space-y-2 mb-3">
          {comments.map((c) => (
            <div key={c.id} className="text-xs">
              <span className="font-medium text-slate-700">{c.user_email}</span>
              <span className="text-slate-400 mx-1">&middot;</span>
              <span className="text-slate-400">
                {new Date(c.created_at).toLocaleDateString()}
              </span>
              <p className="text-slate-600 mt-0.5">{c.body}</p>
            </div>
          ))}
        </div>
      )}

      <form onSubmit={handleSubmit} className="flex gap-2">
        <input
          type="text"
          value={body}
          onChange={(e) => setBody(e.target.value)}
          placeholder="Add a comment..."
          className="flex-1 px-2 py-1.5 border border-slate-200 rounded text-xs focus:outline-none focus:ring-1 focus:ring-indigo-500"
        />
        <button
          type="submit"
          disabled={loading || !body.trim()}
          className="px-2 py-1.5 bg-indigo-600 text-white text-xs rounded hover:bg-indigo-700 disabled:opacity-50"
        >
          Post
        </button>
      </form>
    </div>
  );
}
