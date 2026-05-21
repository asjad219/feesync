# FeeSync Lite - Supabase Migration Plan

## Migration Strategy

### Approach: Incremental Migrations
All schema changes go through versioned migration files in `/supabase/migrations/`. Each migration is atomic and reversible.

### File Naming Convention
```
{sequence}_{short_description}.sql
```

---

## Migration Files

### 001_initial_schema.sql
**Purpose**: Create all core tables, enums, indexes, and triggers

**Order of Operations**:
1. Create enums
2. Create tables (parent to child: accounts → users → students → fees → payments)
3. Create indexes
4. Create triggers
5. Create views

**Status**: Ready to execute

---

### 002_rls_policies.sql
**Purpose**: Enable RLS and create security policies

**Order of Operations**:
1. Enable RLS on all tables
2. Create policies for each table
3. Create helper functions

**Status**: Ready after schema

---

### 003_seed_data.sql
**Purpose**: Seed initial data (optional, for development)

**Contents**:
- Default fee categories
- Sample fee structures
- Test users

**Status**: Optional, development only

---

### 004_webhooks.sql
**Purpose**: Create webhook subscriptions for real-time sync

**Contents**:
- Supabase Realtime subscriptions setup
- Edge function triggers

**Status**: Future enhancement

---

## Migration Execution

### Local Development

```bash
# Start Supabase locally
supabase init
supabase start

# Link to remote project
supabase link --project-ref <project-ref>

# Push migrations
supabase db push

# Or run pending migrations
supabase db reset
```

### Production Deployment

```bash
# Deploy migrations
supabase db push

# Verify migration status
supabase migration list
```

---

## Rollback Strategy

Each migration includes a corresponding rollback comment at the top:

```sql
-- ROLLBACK: Run this to revert migration
-- DROP TABLE IF EXISTS payments;
-- ... etc
```

For critical changes, create a separate rollback migration:

```bash
supabase/migrations/001_rollback_initial_schema.sql
```

---

## Pre-Migration Checklist

- [ ] Back up production database
- [ ] Test migrations on staging environment
- [ ] Verify all foreign keys
- [ ] Check index performance impact
- [ ] Update documentation

---

## Post-Migration Checklist

- [ ] Verify RLS is enforced
- [ ] Test all CRUD operations
- [ ] Run query performance analysis
- [ ] Clear Supabase cache if needed
- [ ] Update environment variables

---

## Migration File Template

```sql
-- Migration: {number}_{description}.sql
-- Created: {date}
-- Description: {what this migration does}

-- ROLLBACK: {how to rollback}

BEGIN;

-- Migration SQL here

COMMIT;
```
