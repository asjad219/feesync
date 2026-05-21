# FeeSync Workspace Structure

This document explains the organization of the FeeSync project after restructuring into a clean dual-platform architecture.

## Directory Tree

```
FeeSync/
├── feesync_mobile/          # Flutter mobile app
│   ├── lib/                 # Dart source code
│   │   ├── main.dart
│   │   ├── router.dart
│   │   ├── core/            # Configuration and utilities
│   │   ├── models/          # Data models
│   │   ├── providers/       # Riverpod state management
│   │   ├── repositories/    # Data access layer
│   │   └── screens/         # UI pages
│   ├── pubspec.yaml         # Flutter dependencies
│   ├── android/             # Android native code
│   ├── ios/                 # iOS native code
│   └── web/                 # Flutter web build
│
├── feesync_web/             # React/Next.js web app
│   ├── src/
│   │   ├── app/             # Next.js App Router pages
│   │   │   ├── (auth)/      # Authentication pages
│   │   │   ├── (dashboard)/ # Dashboard pages
│   │   │   └── layout.tsx
│   │   ├── components/      # React components
│   │   │   ├── ui/          # shadcn/ui base components
│   │   │   ├── fees/        # Fee-related components
│   │   │   ├── payments/    # Payment-related components
│   │   │   ├── students/    # Student-related components
│   │   │   └── (others)
│   │   └── lib/             # Utilities and configuration
│   │       ├── supabase/    # Supabase clients and repos
│   │       ├── validations/ # Zod schemas
│   │       └── utils.ts
│   ├── public/              # Static assets
│   ├── package.json         # NPM dependencies
│   ├── next.config.ts       # Next.js configuration
│   ├── tsconfig.json        # TypeScript configuration
│   ├── postcss.config.mjs   # PostCSS/Tailwind config
│   ├── components.json      # shadcn/ui config
│   ├── eslint.config.mjs    # ESLint rules
│   ├── .env.local           # Environment variables
│   └── .env.example         # Example env template
│
├── supabase/                # Shared backend
│   └── migrations/          # Database schema and RLS policies
│       ├── 001_initial_schema.sql
│       └── 002_rls_policies.sql
│
├── docs/                    # Shared documentation
│   ├── 01-architecture.md
│   ├── 02-folder-structure.md
│   ├── 03-database-schema.md
│   ├── 04-supabase-migration-plan.md
│   ├── 05-rls-policies.md
│   └── 06-implementation-roadmap.md
│
├── .git/                    # Git version control
├── .env.example             # Root-level env template (shared)
├── .gitignore               # Git ignore rules
├── README.md                # Main project overview
├── SETUP.md                 # Setup and installation guide
└── WORKSPACE_STRUCTURE.md   # This file
```

## Application Isolation

### feesync_web/ - Completely Independent

- **No imports from:** feesync_mobile/ or root src/
- **Dependencies:** React, Next.js, TypeScript, Supabase JS SDK
- **Build output:** `.next/` and `out/`
- **Configuration:** All config files in feesync_web/
- **Environment:** Uses `feesync_web/.env.local`

### feesync_mobile/ - Completely Independent

- **No imports from:** feesync_web/ or root src/
- **Dependencies:** Flutter, Dart packages, Supabase Flutter SDK
- **Build output:** `build/`
- **Configuration:** All config in pubspec.yaml and Dart files
- **Environment:** Uses `feesync_mobile/lib/core/config/supabase_config.dart`

### Shared Resources (Root Level)

- **supabase/migrations/**: Database schema - used by BOTH apps
- **docs/**: Architecture and planning - used by BOTH apps
- **.env.example**: Template for environment setup

## Key Files and Their Purpose

### Web App (`feesync_web/`)

| File | Purpose |
|------|---------|
| `src/app/page.tsx` | Landing/home page |
| `src/app/(auth)/login/page.tsx` | Login page |
| `src/app/(dashboard)/...` | Protected dashboard pages |
| `src/lib/supabase/client.ts` | Supabase client initialization |
| `src/lib/supabase/repositories/` | Data access layer |
| `src/components/` | Reusable React components |
| `package.json` | NPM dependencies |
| `next.config.ts` | Next.js build configuration |

### Mobile App (`feesync_mobile/`)

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry point |
| `lib/router.dart` | Navigation configuration |
| `lib/core/config/supabase_config.dart` | Supabase setup |
| `lib/models/` | Data models |
| `lib/providers/` | Riverpod state management |
| `lib/repositories/` | Data access layer |
| `lib/screens/` | UI pages |
| `pubspec.yaml` | Flutter dependencies |

### Backend (`supabase/`)

| File | Purpose |
|------|---------|
| `001_initial_schema.sql` | Database tables creation |
| `002_rls_policies.sql` | Row Level Security policies |

## Development Workflow

### For Web App Only
```bash
cd feesync_web
npm install
npm run dev
# Test changes only in feesync_web
```

### For Mobile App Only
```bash
cd feesync_mobile
flutter clean
flutter pub get
flutter run
# Test changes only in feesync_mobile
```

### For Both Apps (Full Stack Testing)
```bash
# Terminal 1: Start web app
cd feesync_web
npm run dev

# Terminal 2: Start mobile app
cd feesync_mobile
flutter run

# Terminal 3: Monitor shared backend
cd supabase
supabase functions serve
```

## No Cross-Dependencies

**Important:** Zero imports should exist between:
- ❌ `feesync_web/` ← → `feesync_mobile/`
- ❌ `feesync_web/` ← → `src/` (root)
- ❌ `feesync_mobile/` ← → `src/` (root)

Both apps independently connect to **the same Supabase instance** for data sync.

## Git Structure

```
FeeSync (Git Repository Root)
├── All apps and shared resources
├── Single .git/ folder
├── One commit history
├── Can branch/tag entire project
└── Each change tracked across all affected areas
```

**To clone:**
```bash
git clone <repository-url>
cd FeeSync
# Both apps and backends are available
```

## Build & Deployment

### Web App Build
```bash
cd feesync_web
npm run build
# Outputs: feesync_web/.next/
```

### Mobile App Build
```bash
cd feesync_mobile
flutter build apk --release
flutter build ios --release
# Outputs: feesync_mobile/build/
```

### Backend Deploy
```bash
supabase db push
supabase functions deploy
```

## Environment Configuration

### Web App Environment
- Config file: `feesync_web/.env.local`
- Template: `feesync_web/.env.example`
- Required: SUPABASE_URL, SUPABASE_ANON_KEY

### Mobile App Environment
- Config file: `feesync_mobile/lib/core/config/supabase_config.dart`
- Must match web app's Supabase project
- Use same credentials for both

### Shared Credentials
Both apps connect to **same Supabase project**:
```
Web:    NEXT_PUBLIC_SUPABASE_URL
Mobile: supabaseUrl (in supabase_config.dart)
        ↓
    Same value!
```

## Development Standards

### Code Organization
- **Web:** TypeScript + React patterns
- **Mobile:** Dart + Flutter patterns
- **Every file:** Under 800 lines
- **Every function:** Under 50 lines
- **Nesting:** Maximum 4 levels

### Type Safety
- **Web:** TypeScript strict mode
- **Mobile:** Strong Dart typing
- **Database:** Types generated from schema

### Testing
- **Web:** Jest + React Testing Library
- **Mobile:** Flutter test framework
- **Coverage:** Minimum 80% for critical paths

### Documentation
- **Code:** Inline comments for complex logic
- **Functions:** JSDoc/dartdoc comments
- **Modules:** README in each folder explaining purpose

## Troubleshooting Structure Issues

**If you see imports between apps:**
```
❌ WRONG: feesync_web/ imports from feesync_mobile/
```
Solution: Move shared code to `supabase/` or duplicate it.

**If root-level `src/` is being used:**
```
❌ WRONG: Root src/ folder exists
```
Solution: All code should be in `feesync_web/src/` or `feesync_mobile/lib/`

**If environment variables are incorrect:**
```
❌ WRONG: feesync_web uses different Supabase than feesync_mobile
```
Solution: Both must use exact same SUPABASE_URL and ANON_KEY

## Summary

| Aspect | feesync_web | feesync_mobile | Shared |
|--------|-------------|----------------|--------|
| **Location** | `feesync_web/` | `feesync_mobile/` | `supabase/`, `docs/` |
| **Language** | TypeScript/React | Dart/Flutter | SQL |
| **Package Manager** | npm | pub | — |
| **Config Files** | In feesync_web/ | In feesync_mobile/ | — |
| **Build Output** | `.next/` | `build/` | — |
| **Backend** | Supabase | Supabase | ✓ Shared |
| **Cross-imports** | ❌ None | ❌ None | ✓ Both use |

Both apps are **completely independent** but share the **same database backend**.
