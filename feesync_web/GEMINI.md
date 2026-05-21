# FeeSync Web - Next.js Instructions

## Tech Stack
- **Framework:** Next.js 15 (App Router)
- **Language:** TypeScript
- **Styling:** Tailwind CSS v4 + shadcn/ui
- **State Management:** Zustand (Global) + React Query (Server State)
- **Forms:** React Hook Form + Zod
- **Backend:** Supabase (Client and Server components)

## Conventions
- **Repository Pattern:** All data access should go through repository functions in `lib/supabase/repositories/`.
- **Typed Responses:** Repositories must return `{ data: T | null; error: Error | null }`.
- **Form Validation:** Use Zod schemas for all form validations.
- **UI Components:** Use and extend shadcn/ui components in `components/ui/`.
- **Server Components:** Use React Server Components (RSC) by default; use `'use client'` only when necessary.

## Folder Structure
- `src/app/`: Next.js App Router pages and layouts.
- `src/components/`: Reusable React components organized by feature.
- `src/lib/`: Utilities, Supabase client, repositories, and hooks.
- `src/lib/validations/`: Zod validation schemas.
- `src/types/`: Shared TypeScript types.

## Development
- **Setup:** `npm install`
- **Dev:** `npm run dev`
- **Test:** `npm test`
- **Build:** `npm run build`

## Testing Standards
- Unit tests for utility functions and repositories.
- Integration tests for complex components using React Testing Library.
- Playwright for E2E tests in critical flows.
