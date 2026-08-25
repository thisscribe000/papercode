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
| `/admin` | Protected (admin) | Create projects, add clients, upload assets. Only visible if user has `is_admin = true` in `project_members` |
| `/auth/callback` | Public | Exchanges magic link code for session, sets cookies, redirects to `/dashboard` |

## Database Tables (actual schema)
- `projects` — `id`, `name`, `status`, `created_at`
- `project_members` — `user_id`, `project_id`, `is_admin` (composite primary key, no `id` column)
- `assets` — `id`, `title`, `file_url`, `project_id`, `created_at`
- `profiles` — `id`, `email` (used for email → user_id lookup in admin)

## Supabase RLS Policies (expected)
- Users can read assets for projects they belong to
- Admins can insert projects, project_members, and assets
- Storage bucket `assets` allows authenticated uploads

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
│   └── admin-forms.tsx    # Create project, add client, upload asset
├── app/
│   ├── layout.tsx
│   ├── page.tsx           # Redirects to /login
│   ├── login/page.tsx
│   ├── dashboard/page.tsx
│   ├── admin/page.tsx
│   └── auth/callback/route.ts
middleware.ts               # Root middleware for session handling
CONTEXT.md
```

## Running Locally
```bash
npm install
npm run dev
```
