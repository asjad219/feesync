# FeeSync Lite - Architecture Document

## Overview

FeeSync Lite is a lightweight school fee management system enabling schools to track payments, send reminders, and manage fee categories. Built with Next.js 15 + Supabase (BaaS-only, no custom backend).

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Next.js 15 (App Router, TypeScript) |
| Backend | Supabase (Auth, Database, Storage, Realtime) |
| Styling | Tailwind CSS v4 + shadcn/ui |
| Forms | React Hook Form + Zod |
| State | Zustand (global) + React Query (server state) |
| Charts | Recharts |
| Icons | Lucide React |
| Notifications | Sonner (toast library) |
| Email | Supabase Edge Functions + Resend API |
| Deployment | Vercel (frontend) + Supabase Cloud |

---

## Architecture Patterns

### Repository Pattern
All data access goes through typed repository functions in `/lib/supabase/`.

```
/lib/supabase/
├── client.ts          # Browser client
├── server.ts          # Server client (RLS bypass)
├── repositories/
│   ├── students.ts    # Student CRUD
│   ├── fees.ts        # Fee categories & structures
│   ├── payments.ts    # Payment recording
│   ├── users.ts       # User/account management
│   └── notifications.ts # Notification management
└── types.ts           # Shared TypeScript types
```

### API Response Format
All repository functions return:
```typescript
{ data: T | null; error: Error | null }
```

### Component Architecture
```
/components/
├── ui/                    # shadcn/ui base components
├── layout/               # App shell, sidebar, header
├── students/             # Student management components
├── fees/                 # Fee management components
├── payments/             # Payment recording components
├── dashboard/            # Dashboard widgets
├── notifications/        # Notification components
└── settings/            # Settings components
```

### Feature-Based Organization
```
/app/
├── (auth)/
│   ├── login/
│   └── signup/
├── (dashboard)/
│   ├── dashboard/
│   ├── students/
│   ├── fees/
│   ├── payments/
│   ├── notifications/
│   └── settings/
├── api/
│   └── webhooks/        # External integrations
└── layout.tsx
```

---

## Authentication Flow

1. **Signup**: Email/password via Supabase Auth
2. **Login**: Email/password or magic link
3. **Session**: Supabase handles JWT tokens
4. **Middleware**: Redirect unauthenticated users to `/login`
5. **Role-based access**: `admin` vs `accountant` roles

### User Flow
```
User signs up → Creates account → Invites users → Assigns roles
Admin creates fee structures → Accountants record payments
Parents receive notifications → Students view balance
```

---

## Data Flow

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   Browser   │────▶│  Next.js API │────▶│  Supabase   │
│   Client    │◀────│  (RLS rules) │◀────│  PostgreSQL │
└─────────────┘     └──────────────┘     └─────────────┘
                                                 │
                     ┌──────────────┐             │
                     │ Edge Function│◀────────────┘
                     │ (Email Send) │
                     └──────────────┘
```

---

## Environment Variables

```env
# Supabase
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=

# Resend (Email)
RESEND_API_KEY=
EMAIL_FROM="FeeSync <noreply@feesync.app>"

# App
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

---

## Security Considerations

1. **Row Level Security (RLS)**: All tables protected by RLS policies
2. **Service Role Key**: Only used in server-side Edge Functions, never exposed to client
3. **Input Validation**: Zod schemas validate all user inputs
4. **SQL Injection**: Parameterized queries via Supabase client
5. **CORS**: Configured in Edge Functions for webhook endpoints
