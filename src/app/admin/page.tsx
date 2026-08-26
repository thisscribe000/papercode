"use client";

import Link from "next/link";
import SignOutButton from "@/components/sign-out-button";
import AdminForms from "@/components/admin-forms";

export default function AdminPage() {
  return (
    <div className="min-h-screen bg-slate-50">
      <header className="bg-white border-b border-slate-200">
        <div className="max-w-6xl mx-auto px-6 py-3 flex items-center justify-between">
          <span className="text-sm font-semibold text-slate-900">Admin</span>
          <div className="flex items-center gap-4">
            <Link href="/dashboard" className="text-sm text-slate-500 hover:text-slate-700">
              Dashboard
            </Link>
            <SignOutButton />
          </div>
        </div>
      </header>
      <main className="max-w-6xl mx-auto px-6 py-8">
        <AdminForms />
      </main>
    </div>
  );
}
