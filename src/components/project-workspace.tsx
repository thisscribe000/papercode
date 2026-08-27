"use client";

import { useState } from "react";
import Link from "next/link";
import ProjectUploadForm from "./project-upload-form";

interface Version {
  id: string;
  version: number;
  file_url: string;
  created_at: string;
}

interface Screen {
  id: string;
  title: string;
  file_url: string;
  latestVersion: number;
  totalVersions: number;
  versions: Version[];
}

interface ProjectInfo {
  id: string;
  name: string;
  status: string;
  created_at: string;
}

export default function ProjectWorkspace({
  project,
  clientEmail,
  screens,
  commentCounts,
  totalVersions,
  totalComments,
}: {
  project: ProjectInfo;
  clientEmail: string | null;
  screens: Screen[];
  commentCounts: Record<string, number>;
  totalVersions: number;
  totalComments: number;
}) {
  const [showUpload, setShowUpload] = useState(false);

  return (
    <div className="min-h-screen bg-slate-50">
      <header className="bg-white border-b border-slate-200">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 py-3 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 bg-indigo-600 rounded-lg flex items-center justify-center">
              <svg className="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
              </svg>
            </div>
            <span className="text-sm font-semibold text-slate-900">PaperCode</span>
          </div>
          <Link
            href="/admin"
            className="text-sm text-slate-500 hover:text-slate-700"
          >
            All Projects
          </Link>
        </div>
      </header>

      <main className="max-w-6xl mx-auto px-4 sm:px-6 py-6">
        <Link
          href="/admin"
          className="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700 mb-4 transition-colors"
        >
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
          </svg>
          Projects
        </Link>

        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-8">
          <div>
            <h1 className="text-xl font-semibold text-slate-900">
              {project.name}
            </h1>
            <div className="flex items-center gap-3 mt-1 text-sm text-slate-500">
              {clientEmail && <span>{clientEmail}</span>}
              <span className="flex items-center gap-1">
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
                {project.status}
              </span>
            </div>
          </div>
          <button
            onClick={() => setShowUpload(true)}
            className="px-4 py-2 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-700 transition-colors shrink-0"
          >
            + Upload Screen
          </button>
        </div>

        <div className="flex items-center gap-4 text-xs text-slate-400 mb-6">
          <span>{screens.length} screen{screens.length !== 1 ? "s" : ""}</span>
          <span>{totalVersions} version{totalVersions !== 1 ? "s" : ""}</span>
          {totalComments > 0 && (
            <span className="text-amber-600">{totalComments} comment{totalComments !== 1 ? "s" : ""}</span>
          )}
        </div>

        {screens.length === 0 ? (
          <div className="text-center py-16">
            <div className="w-12 h-12 bg-slate-200 rounded-full flex items-center justify-center mx-auto mb-4">
              <svg className="w-6 h-6 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
            </div>
            <p className="text-slate-500 text-sm mb-4">No screens uploaded yet</p>
            <button
              onClick={() => setShowUpload(true)}
              className="text-sm text-indigo-600 hover:text-indigo-700 font-medium"
            >
              Upload your first screen
            </button>
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {screens.map((screen) => {
              const commentCount = commentCounts[screen.id] ?? 0;
              return (
                <Link
                  key={screen.id}
                  href={`/admin/projects/${project.id}/review/${screen.id}`}
                  className="bg-white rounded-xl border border-slate-200 overflow-hidden hover:shadow-md transition-shadow block"
                >
                  {isImage(screen.file_url) ? (
                    <img
                      src={screen.file_url}
                      alt={screen.title}
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
                    <div className="flex items-center gap-2">
                      <p className="font-medium text-slate-900 text-sm truncate">
                        {screen.title}
                      </p>
                    </div>
                    <div className="flex items-center gap-2 mt-1 text-xs text-slate-400">
                      <span>v{screen.latestVersion}</span>
                      {screen.totalVersions > 1 && (
                        <span className="text-[10px] bg-indigo-50 text-indigo-600 px-1.5 py-0.5 rounded">
                          {screen.totalVersions} versions
                        </span>
                      )}
                      {commentCount > 0 && (
                        <span className="flex items-center gap-0.5 text-amber-600">
                          <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                            <path strokeLinecap="round" strokeLinejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                          </svg>
                          {commentCount}
                        </span>
                      )}
                    </div>
                  </div>
                </Link>
              );
            })}
          </div>
        )}
      </main>

      {showUpload && (
        <ProjectUploadForm
          projectId={project.id}
          projectName={project.name}
          existingScreens={screens.map((s) => ({
            id: s.id,
            title: s.title,
            latestVersion: s.latestVersion,
          }))}
          onClose={() => setShowUpload(false)}
        />
      )}
    </div>
  );
}

function isImage(url: string) {
  return /\.(jpg|jpeg|png|gif|webp|svg)$/i.test(url);
}
