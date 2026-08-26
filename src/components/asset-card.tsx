"use client";

import { useState } from "react";
import Link from "next/link";

interface AssetVersion {
  id: string;
  title: string;
  file_url: string;
  created_at: string;
  version: number;
}

interface AssetCardProps {
  latest: AssetVersion;
  olderVersions: AssetVersion[];
  totalVersions: number;
}

export default function AssetCard({ latest, olderVersions, totalVersions }: AssetCardProps) {
  const [expanded, setExpanded] = useState(false);

  return (
    <div className="bg-white rounded-xl border border-slate-200 overflow-hidden hover:shadow-md transition-shadow">
      <Link href={`/dashboard/${latest.id}`} className="block">
        {isImage(latest.file_url) ? (
          <img src={latest.file_url} alt={latest.title} className="w-full h-36 object-cover" />
        ) : (
          <div className="w-full h-36 bg-slate-100 flex items-center justify-center">
            <svg className="w-8 h-8 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
          </div>
        )}
        <div className="p-3">
          <div className="flex items-center gap-2">
            <p className="font-medium text-slate-900 text-sm">{latest.title}</p>
            {totalVersions > 1 && (
              <span className="text-[10px] font-medium bg-indigo-50 text-indigo-600 px-1.5 py-0.5 rounded">
                v{latest.version} ({totalVersions} versions)
              </span>
            )}
          </div>
          <p className="text-xs text-slate-500 mt-1">
            {new Date(latest.created_at).toLocaleDateString()}
          </p>
        </div>
      </Link>

      {olderVersions.length > 0 && (
        <div className="px-3 pb-3">
          <button
            onClick={() => setExpanded(!expanded)}
            className="text-xs text-indigo-500 hover:text-indigo-700"
          >
            {expanded ? "Hide older versions" : `Show ${olderVersions.length} older version${olderVersions.length > 1 ? "s" : ""}`}
          </button>

          {expanded && (
            <div className="mt-2 space-y-2 border-t border-slate-100 pt-2">
              {olderVersions.map((v) => (
                <Link
                  key={v.id}
                  href={`/dashboard/${v.id}`}
                  className="flex items-start gap-2 text-xs hover:bg-slate-50 rounded p-1 -m-1 transition-colors"
                >
                  <span className="font-medium text-slate-400">v{v.version}</span>
                  <div className="flex-1">
                    {isImage(v.file_url) ? (
                      <img src={v.file_url} alt={v.title} className="w-full h-20 object-cover rounded mt-1" />
                    ) : (
                      <span className="text-indigo-500 hover:underline">{v.title}</span>
                    )}
                    <p className="text-slate-400 mt-0.5">{new Date(v.created_at).toLocaleDateString()}</p>
                  </div>
                </Link>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}

function isImage(url: string) {
  return /\.(jpg|jpeg|png|gif|webp|svg)$/i.test(url);
}
