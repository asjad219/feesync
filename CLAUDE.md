# FeeSync Lite

School fee management system for tracking payments, sending reminders, and managing fee categories.

## Tech Stack
- **Frontend**: Next.js 15 (App Router, TypeScript)
- **Backend**: Supabase (Auth, Database, Storage, Realtime)
- **Styling**: Tailwind CSS v4 + shadcn/ui
- **Forms**: React Hook Form + Zod
- **State**: Zustand + React Query
- **Charts**: Recharts

## Project Structure

```
feesync/
├── docs/                    # Architecture and planning documents
├── supabase/
│   └── migrations/          # Database migrations
└── src/
    ├── app/                 # Next.js App Router pages
    ├── components/          # React components
    └── lib/                 # Utilities and Supabase client
```

## Quick Start

```bash
# Install dependencies
npm install

# Copy environment variables
cp .env.example .env.local

# Run migrations (requires Supabase CLI)
supabase db push

# Start development server
npm run dev
```

## Documentation

| Document | Description |
|----------|-------------|
| [docs/01-architecture.md](docs/01-architecture.md) | System architecture and patterns |
| [docs/02-folder-structure.md](docs/02-folder-structure.md) | Project folder organization |
| [docs/03-database-schema.md](docs/03-database-schema.md) | Database schema details |
| [docs/04-supabase-migration-plan.md](docs/04-supabase-migration-plan.md) | Migration strategy |
| [docs/05-rls-policies.md](docs/05-rls-policies.md) | Row Level Security policies |
| [docs/06-implementation-roadmap.md](docs/06-implementation-roadmap.md) | Implementation phases |

## Key Features

1. **Multi-tenancy**: All data scoped by `account_id`
2. **Role-based access**: Admin, Accountant, Parent, Student roles
3. **RLS security**: All tables protected by Row Level Security
4. **Real-time**: Supabase Realtime for live updates

## Implementation Phases

| Phase | Focus | Duration |
|-------|-------|----------|
| 0 | Foundation (auth, supabase) | 1 day |
| 1 | Core CRUD (students, fees, payments) | 2 days |
| 2 | Dashboard (analytics, charts) | 1 day |
| 3 | Notifications (email, reminders) | 1 day |
| 4 | Polish (testing, deployment) | 1 day |

**Total**: ~6 days

## Development Guidelines

- Use repository pattern for all data access
- All forms use React Hook Form + Zod validation
- Follow KISS, DRY, YAGNI principles
- Prefer immutability over mutation
- Small functions (< 50 lines), small files (< 800 lines)
- 80% minimum test coverage
