# FeeSync Lite - Folder Structure

```
feesync/
├── .env.local                    # Environment variables
├── .env.example                  # Example environment file
├── .gitignore
├── .editorconfig
├── .prettierrc
├── eslint.config.mjs
├── next.config.ts                # Next.js configuration
├── package.json
├── tailwind.config.ts            # Tailwind CSS configuration
├── tsconfig.json
├── vite.config.ts                # Vite configuration (for tests)
├── components.json               # shadcn/ui configuration
│
├── public/                       # Static assets
│   ├── favicon.ico
│   └── og-image.png
│
├── supabase/                    # Supabase local development
│   ├── config.toml
│   └── migrations/              # Database migrations
│       └── 001_initial_schema.sql
│
├── docs/                        # Documentation
│   ├── 01-architecture.md
│   ├── 02-folder-structure.md
│   ├── 03-database-schema.md
│   ├── 04-supabase-migration-plan.md
│   ├── 05-rls-policies.md
│   └── 06-implementation-roadmap.md
│
├── src/
│   ├── app/                     # Next.js App Router
│   │   ├── globals.css
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   │
│   │   ├── (auth)/              # Auth group - public routes
│   │   │   ├── login/
│   │   │   │   └── page.tsx
│   │   │   ├── signup/
│   │   │   │   └── page.tsx
│   │   │   └── layout.tsx
│   │   │
│   │   ├── (dashboard)/         # Dashboard group - protected routes
│   │   │   ├── dashboard/
│   │   │   │   └── page.tsx
│   │   │   ├── students/
│   │   │   │   ├── page.tsx
│   │   │   │   ├── [id]/
│   │   │   │   │   └── page.tsx
│   │   │   │   └── new/
│   │   │   │       └── page.tsx
│   │   │   ├── fees/
│   │   │   │   ├── page.tsx
│   │   │   │   ├── [id]/
│   │   │   │   │   └── page.tsx
│   │   │   │   └── new/
│   │   │   │       └── page.tsx
│   │   │   ├── payments/
│   │   │   │   ├── page.tsx
│   │   │   │   └── new/
│   │   │   │       └── page.tsx
│   │   │   ├── notifications/
│   │   │   │   └── page.tsx
│   │   │   ├── settings/
│   │   │   │   └── page.tsx
│   │   │   └── layout.tsx       # Dashboard layout with sidebar
│   │   │
│   │   └── api/                 # API routes (if needed)
│   │       └── webhooks/
│   │           └── route.ts
│   │
│   │
│   ├── components/              # React components
│   │   ├── ui/                  # shadcn/ui base components
│   │   │   ├── button.tsx
│   │   │   ├── card.tsx
│   │   │   ├── dialog.tsx
│   │   │   ├── dropdown-menu.tsx
│   │   │   ├── form.tsx
│   │   │   ├── input.tsx
│   │   │   ├── label.tsx
│   │   │   ├── select.tsx
│   │   │   ├── sonner.tsx
│   │   │   ├── table.tsx
│   │   │   ├── tabs.tsx
│   │   │   └── toast.tsx
│   │   │
│   │   ├── layout/              # Layout components
│   │   │   ├── sidebar.tsx
│   │   │   ├── header.tsx
│   │   │   └── app-shell.tsx
│   │   │
│   │   ├── students/            # Student components
│   │   │   ├── student-form.tsx
│   │   │   ├── student-list.tsx
│   │   │   ├── student-card.tsx
│   │   │   └── student-filters.tsx
│   │   │
│   │   ├── fees/                # Fee components
│   │   │   ├── fee-form.tsx
│   │   │   ├── fee-structure-form.tsx
│   │   │   ├── fee-list.tsx
│   │   │   └── fee-category-card.tsx
│   │   │
│   │   ├── payments/            # Payment components
│   │   │   ├── payment-form.tsx
│   │   │   ├── payment-list.tsx
│   │   │   ├── payment-filters.tsx
│   │   │   └── payment-receipt.tsx
│   │   │
│   │   ├── dashboard/           # Dashboard widgets
│   │   │   ├── stats-card.tsx
│   │   │   ├── collection-chart.tsx
│   │   │   ├── recent-payments.tsx
│   │   │   ├── pending-reminders.tsx
│   │   │   └── quick-actions.tsx
│   │   │
│   │   ├── notifications/       # Notification components
│   │   │   ├── notification-form.tsx
│   │   │   ├── notification-list.tsx
│   │   │   └── notification-templates.tsx
│   │   │
│   │   └── settings/            # Settings components
│   │       ├── profile-form.tsx
│   │       ├── school-settings.tsx
│   │       └── user-management.tsx
│   │
│   │
│   ├── lib/                     # Utilities and libraries
│   │   ├── utils.ts             # Utility functions
│   │   │
│   │   ├── supabase/            # Supabase client & repositories
│   │   │   ├── client.ts        # Browser client
│   │   │   ├── server.ts        # Server client (bypass RLS)
│   │   │   ├── middleware.ts    # Auth middleware
│   │   │   │
│   │   │   ├── repositories/    # Data access layer
│   │   │   │   ├── students.ts
│   │   │   │   ├── fees.ts
│   │   │   │   ├── fee-structures.ts
│   │   │   │   ├── payments.ts
│   │   │   │   ├── notifications.ts
│   │   │   │   └── users.ts
│   │   │   │
│   │   │   └── types.ts         # TypeScript types
│   │   │
│   │   ├── validations/         # Zod schemas
│   │   │   ├── student.ts
│   │   │   ├── fee.ts
│   │   │   ├── payment.ts
│   │   │   └── auth.ts
│   │   │
│   │   ├── constants/           # App constants
│   │   │   ├── fee-categories.ts
│   │   │   └── notification-types.ts
│   │   │
│   │   └── hooks/               # Custom React hooks
│   │       ├── use-students.ts
│   │       ├── use-fees.ts
│   │       ├── use-payments.ts
│   │       └── use-realtime.ts
│   │
│   │
│   └── types/                   # Global TypeScript types
│       └── index.ts
│
│
└── tests/                        # Test files
    ├── unit/                     # Unit tests
    ├── integration/              # Integration tests
    └── e2e/                     # E2E tests (Playwright)
```

## Key Directories

| Directory | Purpose |
|-----------|---------|
| `/src/app/(auth)/` | Public authentication pages |
| `/src/app/(dashboard)/` | Protected dashboard pages |
| `/src/components/ui/` | Base UI components from shadcn/ui |
| `/src/components/[feature]/` | Feature-specific components |
| `/src/lib/supabase/` | Supabase client and repository pattern |
| `/src/lib/validations/` | Zod validation schemas |
| `/supabase/migrations/` | Database schema migrations |
| `/docs/` | Architecture and planning documents |
