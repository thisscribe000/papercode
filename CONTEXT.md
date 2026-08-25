# Client Portal

A Next.js 14 (App Router) client portal with Supabase authentication and asset management.

## Tech Stack
- **Framework:** Next.js 14, App Router
- **Auth:** Supabase magic-link email auth (`@supabase/ssr` + `@supabase/supabase-js`)
- **Styling:** Tailwind CSS
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
| `/login` | Public | Email input, sends magic link, shows "check your email" state |
| `/dashboard` | Protected | Assets grouped by project, cards with title/image/date |
| `/admin` | Protected (admin) | Create projects, add clients, upload assets |
| `/auth/callback` | Public | Exchanges magic link code for session |

## Database Tables (assumed existing)
- `projects` — `id`, `name`, `status`, `created_at`
- `project_members` — `id`, `user_id`, `project_id`, `role`, `is_admin`
- `assets` — `id`, `title`, `file_url`, `project_id`, `created_at`
- `profiles` — `id`, `email` (used for email → user_id lookup in admin)

## Supabase RLS Policies (expected)
- Users can read assets for projects they belong to
- Admins can insert projects, project_members, and assets
- Storage bucket `assets` allows authenticated uploads

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
```

## Running Locally
```bash
npm install
npm run dev
```
