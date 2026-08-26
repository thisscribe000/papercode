# Client Portal

A Next.js 14 (App Router) client portal with Supabase authentication and asset management.

## Tech Stack
- **Framework:** Next.js 14, App Router
- **Auth:** Supabase email/password + magic-link (`@supabase/ssr` + `@supabase/supabase-js`)
- **Styling:** Tailwind CSS (dark gradient login, light dashboard/admin)
- **Database:** Supabase PostgreSQL (projects, project_members, assets tables with RLS)
- **Storage:** Supabase Storage bucket `assets`

## Environment Variables
| Variable | Description |
|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase project URL |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase anonymous/public API key |

## Pages
| Route | Auth | Description |
|---|---|---|
| `/login` | Public | Email + password login (default), toggleable to magic link |
| `/dashboard` | Protected | Assets grouped by project, cards with title/image/date. Admin users see an "Admin" link in the header |
| `/admin` | Protected | Create projects, upload assets. Client component — auth handled by middleware |
| `/auth/callback` | Public | Exchanges magic link code for session, sets cookies, redirects to `/dashboard` |

## Database Tables
- `projects` — `id`, `name`, `status`, `created_at`
- `project_members` — `user_id`, `project_id`, `is_admin` (composite primary key, no `id` column)
- `assets` — `id`, `title`, `file_url`, `project_id`, `version` (int, default 1), `parent_asset_id` (uuid, nullable), `created_at`
- `profiles` — `id`, `email` (used for email → user_id lookup in admin)
- `comments` — `id`, `asset_id` (references specific asset version), `user_id`, `content`, `created_at`, `updated_at`, `parent_comment_id` (nullable, for future threading)

## RLS Policies (required)
Authenticated users need read/write access to all tables and storage. Run this in Supabase SQL Editor:
```sql
CREATE POLICY "Authenticated can read projects" ON projects FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated can insert projects" ON projects FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated can read assets" ON assets FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated can insert assets" ON assets FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated can upload" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'assets');
CREATE POLICY "Authenticated can read storage" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'assets');
```

Comments RLS uses project-membership checks (see `supabase/migrations/` for full SQL):
- SELECT/INSERT: user must be a member of the project the asset belongs to
- UPDATE: user must be the comment author + project member
- DELETE: user must be the author OR an admin of the project

## Supabase Setup Notes
- Auth callback URL must be whitelisted: `http://localhost:3000/auth/callback`
- To make a user admin, insert into `project_members` with `is_admin = true`
- `project_members` has no `role` column — only `user_id`, `project_id`, `is_admin`
- Free tier has email rate limits (~3-4 magic link emails/hour) — password login is preferred

## File Structure
```
src/
├── lib/supabase/
│   ├── client.ts          # Browser client (createBrowserClient)
│   ├── server.ts          # Server client (createServerClient + cookies)
│   └── middleware.ts      # Session refresh + auth redirect logic
├── components/
│   ├── sign-out-button.tsx
│   ├── admin-forms.tsx    # Create project, upload asset (with version replacement)
│   ├── asset-card.tsx     # Asset card with version history expand/collapse
│   └── asset-comments.tsx # Comment list + input per asset card
├── app/
│   ├── layout.tsx
│   ├── page.tsx           # Redirects to /login
│   ├── login/page.tsx
│   ├── dashboard/page.tsx
│   ├── admin/page.tsx
│   └── auth/callback/route.ts
middleware.ts               # Root middleware for session handling
```

## Running Locally
```bash
npm install
npm run dev
```
