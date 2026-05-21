# FeeSync - Project Instructions

## Overview
FeeSync is a multi-platform school fee management system. It consists of a Flutter mobile app, a Next.js web app, and a shared Supabase backend.

## Architecture
- **Multi-Tenant:** Isolation by `account_id` enforced via Supabase Row Level Security (RLS).
- **Dual-Platform:**
    - Mobile: Flutter with Riverpod for state management.
    - Web: Next.js 15 with Zustand and React Query.
- **Shared Backend:** Supabase (Auth, Database, Storage, Realtime).

## Engineering Standards
- **Immutability:** Prefer immutable patterns over mutations.
- **Function Size:** Keep functions under 50 lines.
- **File Size:** Keep files under 800 lines.
- **Nesting:** Maximum 4 levels of nesting.
- **Error Handling:** All errors must be handled explicitly.
- **Type Safety:** Rigorous use of TypeScript (web) and strong typing (Dart/Flutter).
- **Testing:** Minimum 80% coverage for critical paths.

## Git Workflow
- Use **Conventional Commits** (e.g., `feat:`, `fix:`, `docs:`, `chore:`).
- Create feature branches: `feat/feature-name`.

## Project Structure
- `/feesync_mobile`: Flutter mobile application. [See instructions](./feesync_mobile/GEMINI.md)
- `/feesync_web`: Next.js web application. [See instructions](./feesync_web/GEMINI.md)
- `/supabase`: Database migrations and RLS policies.
- `/docs`: Detailed architecture and planning documentation.

## Documentation Reference
- [Architecture](./docs/01-architecture.md)
- [Folder Structure](./docs/02-folder-structure.md)
- [Database Schema](./docs/03-database-schema.md)
- [RLS Policies](./docs/05-rls-policies.md)
