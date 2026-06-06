# FeeSync — Complete Product Strategy & Subscription Model
### Senior SaaS Consultant Analysis | June 2026

---

## EXECUTIVE SUMMARY

FeeSync is a **cloud-native, mobile-first fee management platform** purpose-built for India's 8M+ solo coaching operators — home tutors, fitness instructors, music/dance teachers, and small-to-mid coaching centers. It digitises every financial and operational touchpoint from student enrollment through fee collection, WhatsApp receipts, attendance tracking, and real-time P&L visibility.

**Current state:** The codebase is at a mature MVP/v1 stage with 3 subscription tiers already modeled (Free, Starter ₹199/mo, Growth ₹499/mo), Supabase backend, Flutter + Next.js dual-platform architecture, and a rich feature set largely implemented. However, the **subscription enforcement is incomplete** — pricing logic exists in the model layer but there is no real billing gateway, no Google Play Billing integration, and no feature gate middleware.

---

## PHASE 1 — COMPLETE PRODUCT ANALYSIS

### 1.1 What Problem Does FeeSync Solve?

| Problem | Pain | FeeSync Solution |
|---|---|---|
| Fee register lost / not searchable | All payment history gone | Cloud-synced permanent records |
| No real-time overdue visibility | Admin discovers defaults at month-end | Live dashboard with overdue KPIs |
| Manual receipt writing | Time-consuming, disputed | Auto PDF + WhatsApp receipt in seconds |
| No bulk reminder tool | Admin calls each parent individually | One-tap bulk WhatsApp to all overdue |
| Cash/UPI confusion | Cannot reconcile at month-end | Payment mode tracking + reconciliation report |
| No monthly P&L | Owner never knows true profitability | Automated P&L: revenue minus expenses |
| Different fee arrangements per student | Impossible to track | Per-student fee assignment with discounts |
| No attendance alerts | Parents unaware of child absence | Auto WhatsApp absent alert same day |

### 1.2 User Segments

| Persona | Students | Monthly Revenue | Admin Workload | Willingness to Pay |
|---|---|---|---|---|
| **Home Tutor** | 10–40 | ₹10K–₹60K | Low | ₹0–₹199/mo |
| **Solo Coaching Owner** | 40–150 | ₹60K–₹3L | Medium | ₹199–₹499/mo |
| **Yoga/Fitness Instructor** | 20–80 | ₹30K–₹1.5L | Medium | ₹199/mo |
| **Music/Dance Teacher** | 10–50 | ₹15K–₹1L | Low | ₹0–₹199/mo |
| **Multi-Subject Coaching** | 100–300 | ₹2L–₹10L | High | ₹499–₹999/mo |
| **Small Institute** | 300–1000 | ₹10L–₹50L | Very High | ₹999–₹2,999/mo |

---

## PHASE 2 — CODEBASE AUDIT

### 2.1 Flutter Architecture

| Layer | Files | Assessment |
|---|---|---|
| **Screens** | 11 feature modules (auth, batches, dashboard, fees, notifications, onboarding, payments, reports, settings, shell, students) | ✅ Well-organized feature-based structure |
| **Models** | 15 model files (student, batch, fee, payment, subscription, notification, app_settings, attendance, etc.) | ✅ Comprehensive with proper serialization |
| **Providers** | 15 Riverpod providers | ✅ Good state management pattern |
| **Repositories** | 10 repository files | ✅ Clean data access layer separation |
| **Navigation** | GoRouter with 30+ routes | ✅ Proper auth guards + onboarding flow |

### 2.2 Backend (Supabase)

| Migration | Purpose | Status |
|---|---|---|
| 001_initial_schema | Core tables: accounts, users, students, fees, payments, notifications | ✅ Done |
| 002_rls_policies | Row-Level Security policies | ✅ Done |
| 003_phase1_onboarding | Onboarding flow tables | ✅ Done |
| 004_phase4_fees | fee_assignments, dues engine, plan types | ✅ Done |
| 005_dues_engine | Due generation logic | ✅ Done |
| 006_batches | batches, attendance tables | ✅ Done |
| 007–014 | Student enhancements, balances view, app_settings, message templates, batch schedule | ✅ Done |
| **subscriptions table** | Plan tracking | ⚠️ Modeled in code but migration not in repo |

### 2.3 Existing Subscription System

**What exists in code:**
- `Subscription` model with fields: `plan_tier`, `valid_until`, `max_students`, `razorpay_sub_id`, `google_play_purchase_token`
- `SubscriptionPlan` static definitions with all limits
- `SubscriptionRepository` with read/upsert methods
- `SubscriptionProvider` with student/batch limit checking
- Full `SubscriptionScreen` (1,745-line UI) with plan comparison, billing toggle, upgrade sheet

**What is MISSING (critical gaps):**

> [!CAUTION]
> **No actual payment processing** — The upgrade buttons show a bottom sheet but no real billing integration exists. No `in_app_purchase` or `purchases_flutter` package in pubspec.yaml.

> [!WARNING]
> **No feature gate middleware** — Features are not actually blocked when users exceed limits. The limit-checking logic in `SubscriptionProvider` exists but is not enforced at the UI or repository layer for most features.

> [!WARNING]
> **No subscriptions table migration** — The `subscriptions` table is referenced in the repository code but no SQL migration creates it.

> [!NOTE]
> **Discrepancy in free tier limits** — `Subscription.defaultFree()` sets `maxStudents: 20` but `SubscriptionPlan.free` sets `maxStudents: 20` and PRD says 50. The model comment says free ≤50 but the default is 20.

### 2.4 Current Strengths
- ✅ Rich feature set: 6 fee plan types, dues engine, batch management, attendance, WhatsApp templates, AI settings, PDF generation
- ✅ Excellent dual-platform architecture (Flutter + Next.js sharing Supabase)
- ✅ Strong onboarding flow with multi-step wizard
- ✅ Beautiful UI with glass morphism design system
- ✅ Proper RLS security by owner_id
- ✅ Subscription model/UI fully designed

### 2.5 Weaknesses & Technical Debt
- ❌ No real billing integration (Google Play, Razorpay)
- ❌ No feature gates at the repository/API level
- ❌ No subscriptions table migration
- ❌ No usage tracking (WhatsApp count per month, AI feature uses)
- ❌ No `google_play_billing` or `in_app_purchase` package
- ❌ Category analytics in dashboard_provider is placeholder code (totalAmount not mapped to categories)
- ❌ Free tier limit inconsistency (20 vs 50 students)
- ❌ No Razorpay payment link generation implemented
- ❌ OCR, AI predictions, churn risk are UI toggles only — no actual AI backend

### 2.6 Monetization Opportunities
- WhatsApp message usage metering (currently not tracked)
- AI feature usage billing
- PDF report generation credits
- Data export gating
- Razorpay payment link generation fee/commission
- White-label/custom branding as enterprise add-on

---

## PHASE 3 — FEATURE VALUE SCORING MATRIX

| Feature | User Value (1-10) | Revenue Impact (1-10) | Retention (1-10) | Competitive Advantage (1-10) | Tier |
|---|---|---|---|---|---|
| Student Management (add/edit/view) | 10 | 7 | 10 | 5 | **Must-Have (Free)** |
| Payment Recording (cash/UPI) | 10 | 8 | 10 | 5 | **Must-Have (Free)** |
| PDF Receipt Generation | 9 | 7 | 9 | 6 | **Must-Have (Free)** |
| Dashboard KPI Cards | 9 | 7 | 8 | 5 | **Must-Have (Free)** |
| Basic Reports (5 types) | 8 | 6 | 7 | 4 | **Must-Have (Free)** |
| 1 Batch Management | 7 | 5 | 8 | 5 | **Must-Have (Free)** |
| WhatsApp Receipts (limited) | 9 | 8 | 9 | 8 | **Must-Have (Free, limited)** |
| Attendance Marking | 8 | 6 | 8 | 6 | **Must-Have (Free)** |
| Dues Engine (auto-generate) | 9 | 9 | 9 | 8 | **Value (Starter)** |
| Bulk WhatsApp Reminders | 9 | 9 | 9 | 8 | **Value (Starter)** |
| All 14 Reports + CSV Export | 8 | 8 | 8 | 7 | **Value (Starter)** |
| Multiple Batches (up to 10) | 8 | 8 | 8 | 6 | **Value (Starter)** |
| Razorpay Payment Links | 8 | 9 | 7 | 7 | **Value (Starter)** |
| Fee Assignments (per-student) | 8 | 7 | 8 | 7 | **Value (Starter)** |
| GST Invoice & Tax | 7 | 7 | 6 | 6 | **Value (Starter)** |
| Data Import (CSV bulk) | 7 | 7 | 7 | 6 | **Value (Starter)** |
| AI Smart Reminders | 9 | 9 | 9 | 9 | **Premium (Growth)** |
| AI Defaulter Prediction | 9 | 9 | 9 | 9 | **Premium (Growth)** |
| AI OCR Receipt Scanner | 7 | 7 | 7 | 9 | **Premium (Growth)** |
| Razorpay Auto-Debit | 8 | 10 | 8 | 9 | **Premium (Growth)** |
| Scheduled Email Reports | 7 | 8 | 8 | 8 | **Premium (Growth)** |
| Unlimited Batches | 9 | 9 | 9 | 7 | **Premium (Growth)** |
| SMS Fallback (500/mo) | 7 | 7 | 7 | 7 | **Premium (Growth)** |
| WhatsApp Priority Support | 6 | 8 | 7 | 8 | **Premium (Growth)** |
| P&L Statement (full) | 8 | 8 | 8 | 8 | **Enterprise** |
| Multi-branch Support | 6 | 9 | 7 | 8 | **Enterprise (future)** |
| Staff Accounts / Roles | 7 | 8 | 7 | 7 | **Enterprise (future)** |
| Parent App | 8 | 7 | 9 | 8 | **Premium (Growth)** |
| White-label Receipts | 6 | 7 | 6 | 7 | **Add-on** |
| API Access / Webhooks | 5 | 7 | 6 | 8 | **Enterprise (future)** |

---

## PHASE 4 — MARKET RESEARCH

### 4.1 Competitor Analysis

| Product | Target | Pricing | Key Weakness | FeeSync Opportunity |
|---|---|---|---|---|
| **TutorKhata** | Home tutors | Free (10 students), ₹299/mo Starter, ₹599/mo Pro | No AI, basic UI, no WhatsApp integration native | FeeSync's WhatsApp-first + AI features are a major differentiator |
| **Proctur** | Large institutes | ₹2,000–₹10,000/mo | Too complex for solo operators, no mobile-first | FeeSync wins the 15–300 student segment |
| **EduGradUP** | Mid schools | ~₹12,000/year flat | No AI, no WhatsApp, school-focused not coaching | FeeSync targets coaching/tutor segment Edu ignores |
| **Igniter** | Home tutors | 5% transaction fee model | 5% cut is expensive at scale | FeeSync's flat subscription is predictable and cheaper |
| **MySchoolManager** | Schools | ₹499/mo+ | School ERP (HR, library, etc.), overkill for tutors | FeeSync is purpose-built and simpler |
| **ClassKlap** | Large schools | Custom quote | Not for solo operators, complex onboarding | FeeSync onboards in <3 min |
| **Edumarshal** | Institutions | Custom enterprise | 30+ modules, steep learning curve | FeeSync serves the underserved solo operator market |
| **CoFee (Tamil Nadu)** | Regional | Low | Regional only, no Hindi/other languages | FeeSync's multi-language WhatsApp templates |

### 4.2 Market Gaps Identified

1. **The 15–150 student solo operator is underserved** — TutorKhata stops at 10 free; Proctur starts at institution scale. FeeSync owns this critical middle ground.
2. **WhatsApp-native is rare** — Most apps treat WhatsApp as an add-on. FeeSync treats it as the primary communication channel.
3. **AI features at sub-₹500/mo doesn't exist** — No competitor at this price point offers smart defaulter prediction or AI reminders.
4. **Combined Flutter mobile + web** — Most India competitors are web-only. FeeSync's Flutter app for the owner (and parent portal) is a strong differentiator.
5. **Free tier that is genuinely useful** — Most competitors cripple their free tiers; FeeSync can use a more generous free tier as a growth funnel.

---

## PHASE 5 — RECOMMENDED SUBSCRIPTION PLAN STRUCTURE

> [!IMPORTANT]
> **Analysis-backed recommendation:** After reviewing the codebase, PRD, market data, and competitor positioning, the existing 3-tier structure (Free/Starter/Growth) is **fundamentally sound** but needs **calibration** in the following areas:
> 1. The free student limit should be **30** (not 20 or 50) — enough to be genuinely useful but low enough to create natural upgrade pressure
> 2. The Starter price at **₹199/mo is the correct sweet spot** — below TutorKhata's ₹299/mo
> 3. The Growth price at **₹499/mo is appropriate** — but needs **annual discount to ₹3,990/year** (33% saving = stronger conversion)
> 4. A **4th plan (Pro/Institute)** should be designed for 300–1000 student institutes

---

### Plan 1: Free — "Try & Grow"
**Purpose:** Maximum user acquisition, habit formation, word-of-mouth

| Attribute | Value |
|---|---|
| **Price** | ₹0 forever |
| **Student Limit** | 30 active students |
| **Batches** | 2 batches |
| **WhatsApp Receipts** | 100/month |
| **WhatsApp Reminders** | 30/month |
| **SMS** | None |
| **Reports** | 3 basic reports (Daily Collection, Monthly Summary, Student Ledger) |
| **AI Features** | None |
| **CSV Export** | No |
| **Razorpay** | No |
| **PDF Receipts** | ✅ Yes |
| **Attendance** | ✅ Yes |
| **Dues Engine** | Basic (no auto-generate) |
| **Support** | Community only |

**Rationale:** 30 students is enough for a home tutor to prove value. 2 batches lets them organize. 100 WhatsApp receipts = 100 payments/month which is realistic for 30 students at monthly billing. The free plan creates habit before the upgrade trigger.

---

### Plan 2: Starter — "Professional Solo Operator"
**Purpose:** Primary revenue driver, high conversion from free

| Attribute | Value |
|---|---|
| **Monthly Price** | **₹199/mo** |
| **Annual Price** | **₹1,790/year** (~₹149/mo, 2 months free) |
| **Student Limit** | 200 active students |
| **Batches** | 15 batches |
| **WhatsApp Receipts** | Unlimited |
| **WhatsApp Reminders** | Unlimited |
| **SMS Fallback** | 100/month |
| **Reports** | All 14 report types |
| **AI Features** | 3 features (Smart Reminders, Defaulter Prediction, Smart Summary) |
| **CSV Export** | ✅ Yes |
| **PDF Export** | ✅ Yes |
| **Razorpay Payment Links** | ✅ Yes |
| **Razorpay Auto-Debit** | No |
| **Scheduled Email Reports** | No |
| **Fee Assignments + Discounts** | ✅ Yes |
| **All 6 Fee Plan Types** | ✅ Yes |
| **GST Invoices** | ✅ Yes |
| **Bulk CSV Import** | ✅ Yes |
| **Attendance + Absent Alerts** | ✅ Yes |
| **Support** | Email support |
| **Best For** | Solo coaching owner with 40–150 students |

**Rationale:** At ₹199/mo, if the user collects ₹50,000/month in fees, the software costs 0.4% of revenue — an easy sell. Unlimited WhatsApp is the core value prop. Removing auto-debit and scheduled emails keeps upsell pressure for Growth.

---

### Plan 3: Growth — "Scale with AI"
**Purpose:** Higher LTV from serious coaching businesses

| Attribute | Value |
|---|---|
| **Monthly Price** | **₹499/mo** |
| **Annual Price** | **₹3,990/year** (~₹332/mo, 33% saving) |
| **Student Limit** | Unlimited |
| **Batches** | Unlimited |
| **WhatsApp Receipts** | Unlimited |
| **WhatsApp Reminders** | Unlimited |
| **SMS Fallback** | 500/month |
| **Reports** | All 14 + Scheduled Weekly/Monthly Email Delivery |
| **AI Features** | All 9 features |
| **CSV Export** | ✅ Yes |
| **Razorpay Payment Links** | ✅ Yes |
| **Razorpay Auto-Debit** | ✅ Yes |
| **Scheduled Email Reports** | ✅ Yes (weekly + monthly) |
| **P&L Statement (Full)** | ✅ Yes |
| **Expense Tracker** | ✅ Full |
| **Parent App Access** | ✅ Yes |
| **WhatsApp Support** | ✅ Dedicated |
| **Priority Support** | ✅ Yes |
| **Analytics (Advanced)** | ✅ Cohort, LTV, churn curves |
| **Best For** | Coaching center with 150–500+ students |

**Rationale:** Auto-Debit alone justifies the upgrade — it eliminates monthly follow-up. All 9 AI features at ₹499/mo is exceptional value vs. any competitor. Growth's annual plan at ₹3,990 (saving ₹2,000) is a compelling one-time decision for serious operators.

---

### Plan 4: Institute — "Multi-Batch Enterprise" *(Future — Q4 2026)*
**Purpose:** Capture larger institutes, anchor high MRR accounts

| Attribute | Value |
|---|---|
| **Monthly Price** | **₹1,499/mo** |
| **Annual Price** | **₹11,999/year** (~₹1,000/mo) |
| **Student Limit** | Unlimited |
| **Staff Accounts** | Up to 5 staff logins |
| **Role-Based Access** | Admin, Accountant, Teacher roles |
| **Everything in Growth** | ✅ Yes |
| **Multi-Branch Reporting** | ✅ Yes |
| **API Access** | ✅ REST API + Webhooks |
| **Custom Receipt Branding** | ✅ White-label |
| **Tally Export** | ✅ Yes |
| **Dedicated Account Manager** | ✅ Yes |
| **Custom Onboarding** | ✅ Yes |
| **Best For** | Institute with 500–2000 students, multiple teachers |

---

### Side-by-Side Comparison

| Feature | Free | Starter ₹199 | Growth ₹499 | Institute ₹1,499 |
|---|---|---|---|---|
| Students | 30 | 200 | Unlimited | Unlimited |
| Batches | 2 | 15 | Unlimited | Unlimited |
| WhatsApp Receipts | 100/mo | Unlimited | Unlimited | Unlimited |
| WhatsApp Reminders | 30/mo | Unlimited | Unlimited | Unlimited |
| SMS Fallback | — | 100/mo | 500/mo | 1,000/mo |
| Reports | 3 basic | All 14 | All 14 + Scheduled | All 14 + Custom |
| AI Features | None | 3 | All 9 | All 9 + Custom |
| CSV/PDF Export | — | ✅ | ✅ | ✅ |
| Razorpay Links | — | ✅ | ✅ | ✅ |
| Auto-Debit | — | — | ✅ | ✅ |
| Parent App | — | — | ✅ | ✅ |
| Staff Accounts | 1 | 1 | 1 | 5 |
| Support | Community | Email | WhatsApp | Dedicated AM |

---

## PHASE 6 — REVENUE FORECASTS

### Assumptions
- ARPU Free = ₹0 | Starter = ₹199 | Growth = ₹499 | Institute = ₹1,499
- Blended mix: 60% Starter, 30% Growth, 10% Institute (of paid users)
- Blended ARPU paid: (199×0.6) + (499×0.3) + (1499×0.1) = ₹119.4 + ₹149.7 + ₹149.9 = **₹419/mo paid ARPU**
- Free → Paid conversion rate: 20%
- Monthly churn: 4% (very low — once routine-based, sticky)

### Conservative Scenario — 100 Paid Users
| Metric | Value |
|---|---|
| Free users | 500 |
| Paid users | 100 |
| Starter (60) | ₹11,940/mo |
| Growth (30) | ₹14,970/mo |
| Institute (10) | ₹14,990/mo |
| **Total MRR** | **₹41,900/mo** |
| **ARR** | **₹5,02,800/year** |
| Annual plan bonus (+15% from annual) | ₹75,420 |
| **Effective ARR** | **~₹5.8L/year** |

### Growth Scenario — 1,000 Paid Users
| Metric | Value |
|---|---|
| Free users | 5,000 |
| Paid users | 1,000 |
| Starter (600) | ₹1,19,400/mo |
| Growth (300) | ₹1,49,700/mo |
| Institute (100) | ₹1,49,900/mo |
| **Total MRR** | **₹4,19,000/mo** |
| **ARR** | **₹50,28,000/year (~₹50L)** |
| **Effective ARR with annual** | **~₹57.8L/year** |

### Scale Scenario — 10,000 Paid Users
| Metric | Value |
|---|---|
| Free users | 50,000 |
| Paid users | 10,000 |
| Starter (6,000) | ₹11,94,000/mo |
| Growth (3,000) | ₹14,97,000/mo |
| Institute (1,000) | ₹14,99,000/mo |
| **Total MRR** | **₹41,90,000/mo** |
| **ARR** | **₹5,02,80,000/year (~₹5 Crore)** |
| **Effective ARR with annual** | **~₹5.8 Crore/year** |

### Most Profitable Strategies:
1. **Annual plan push** → Convert 40% of users to annual = +₹X × 2 months = 16.7% revenue boost, guaranteed 12-month retention
2. **Institute plan acquisition** → 1 Institute = 7.5× a Starter. Acquiring 10 large institutes = 75 Starter equivalents
3. **WhatsApp as growth engine** → Every receipt sent is a brand impression. Parents asking "what app is this?" drives referrals

---

## PHASE 7 — IMPLEMENTATION PLAN

### 7.1 Database Changes Required

```sql
-- Migration: 015_subscriptions.sql (MISSING — must create)
CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  plan_tier TEXT NOT NULL DEFAULT 'free' 
    CHECK (plan_tier IN ('free', 'starter', 'growth', 'institute')),
  billing_cycle TEXT DEFAULT 'monthly' 
    CHECK (billing_cycle IN ('monthly', 'annual')),
  valid_until TIMESTAMPTZ,
  max_students INTEGER NOT NULL DEFAULT 30,
  max_batches INTEGER NOT NULL DEFAULT 2,
  whatsapp_receipts_limit INTEGER DEFAULT 100,
  whatsapp_reminders_limit INTEGER DEFAULT 30,
  sms_limit INTEGER DEFAULT 0,
  razorpay_sub_id TEXT,
  razorpay_payment_id TEXT,
  google_play_purchase_token TEXT,
  google_play_product_id TEXT,
  trial_ends_at TIMESTAMPTZ,
  is_trial BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Migration: 016_usage_tracking.sql (NEW)
CREATE TABLE IF NOT EXISTS subscription_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES auth.users(id),
  period_start DATE NOT NULL,
  whatsapp_receipts_used INTEGER DEFAULT 0,
  whatsapp_reminders_used INTEGER DEFAULT 0,
  sms_used INTEGER DEFAULT 0,
  ai_calls_used INTEGER DEFAULT 0,
  UNIQUE(owner_id, period_start)
);

-- Update free tier limit in RPC
CREATE OR REPLACE FUNCTION get_plan_limits(p_tier TEXT)
RETURNS JSONB AS $$
  SELECT CASE p_tier
    WHEN 'free'      THEN '{"students":30,"batches":2,"wa_receipts":100,"wa_reminders":30}'::jsonb
    WHEN 'starter'   THEN '{"students":200,"batches":15,"wa_receipts":-1,"wa_reminders":-1}'::jsonb
    WHEN 'growth'    THEN '{"students":-1,"batches":-1,"wa_receipts":-1,"wa_reminders":-1}'::jsonb
    WHEN 'institute' THEN '{"students":-1,"batches":-1,"wa_receipts":-1,"wa_reminders":-1}'::jsonb
    ELSE '{"students":30,"batches":2,"wa_receipts":100,"wa_reminders":30}'::jsonb
  END;
$$ LANGUAGE sql;
```

### 7.2 Flutter Package Changes

Add to `pubspec.yaml`:
```yaml
# Billing
in_app_purchase: ^3.2.0          # Google Play + App Store billing
in_app_purchase_android: ^0.3.5  # Android-specific
in_app_purchase_storekit: ^0.3.17 # iOS-specific

# Usage tracking  
shared_preferences: ^2.3.2       # Local usage cache
```

### 7.3 Google Play Billing Product IDs

| Product ID | Type | Price |
|---|---|---|
| `feesync_starter_monthly` | Subscription | ₹199/month |
| `feesync_starter_annual` | Subscription | ₹1,790/year |
| `feesync_growth_monthly` | Subscription | ₹499/month |
| `feesync_growth_annual` | Subscription | ₹3,990/year |
| `feesync_institute_monthly` | Subscription | ₹1,499/month |
| `feesync_institute_annual` | Subscription | ₹11,999/year |

### 7.4 Feature Gate System

Create `lib/core/gates/feature_gate.dart`:

```dart
// Feature gate checker — inject via Provider
class FeatureGate {
  final Subscription subscription;
  final SubscriptionUsage usage;

  bool get canAddStudent => 
    subscription.maxStudents < 0 || 
    usage.activeStudents < subscription.maxStudents;

  bool get canAddBatch => 
    subscription.maxBatches < 0 || 
    usage.activeBatches < subscription.maxBatches;

  bool get canSendWhatsappReceipt =>
    subscription.whatsappReceiptsLimit < 0 ||
    usage.whatsappReceiptsThisMonth < subscription.whatsappReceiptsLimit;

  bool get hasAiFeatures => 
    subscription.effectivePlan != 'free';

  bool get hasAdvancedAi => 
    subscription.effectivePlan == 'growth' || 
    subscription.effectivePlan == 'institute';

  bool get hasRazorpay =>
    subscription.effectivePlan != 'free';

  bool get hasAutoDebit =>
    subscription.effectivePlan == 'growth' || 
    subscription.effectivePlan == 'institute';

  bool get hasScheduledReports =>
    subscription.effectivePlan == 'growth' || 
    subscription.effectivePlan == 'institute';

  bool get hasCsvExport =>
    subscription.effectivePlan != 'free';
    
  int get reportAccessCount {
    switch (subscription.effectivePlan) {
      case 'free': return 3;
      default: return 14;
    }
  }
}
```

### 7.5 Upgrade Flow

```
User hits limit (e.g., tries to add 31st student)
    ↓
Show non-blocking upgrade card (NOT a modal blocker)
    ↓
User taps "Upgrade to Starter"
    ↓
SubscriptionScreen opens with Starter pre-selected
    ↓
User selects Monthly or Annual
    ↓
Tap "Subscribe" → triggers in_app_purchase.buyNonConsumable()
    ↓
Google Play shows payment sheet
    ↓
On purchase complete → send token to Supabase Edge Function
    ↓
Edge Function verifies with Google Play API → upserts subscription record
    ↓
App refreshes subscriptionProvider → new limits active instantly
    ↓
User sees success animation + "You're now on Starter!" confirmation
```

### 7.6 Downgrade Flow

```
User subscription expires (valid_until < now)
    ↓
effectivePlan falls back to 'free' automatically (already in model)
    ↓
Read-only mode for 7 days (can view data, cannot add)
    ↓
Banner shown persistently: "Your plan expired. Renew to continue."
    ↓
After 7 days: enforce free tier limits (30 students, 2 batches)
    ↓
Students beyond limit = inactive status (not deleted)
    ↓
Admin can renew anytime to restore full access
```

### 7.7 Migration Plan for Existing Users

```
Phase 1 (Launch): All existing users → Free plan, 30-day Growth trial
Phase 2 (Day 31): Soft reminder to upgrade
Phase 3 (Day 38): Hard enforcement of free limits
Phase 4 (ongoing): Monthly usage reports emailed to admin
```

### 7.8 Analytics Dashboard (Admin)
Track per user:
- Plan tier + billing cycle
- Student count vs limit
- WhatsApp usage/month
- Last login date
- Payment history
- Churn risk score (students added trend)

### 7.9 Priority Implementation Order

| Priority | Task | Estimated Effort |
|---|---|---|
| 🔴 P0 | Create `subscriptions` table migration (015) | 0.5 days |
| 🔴 P0 | Fix free tier limit to 30 (consistent across model + plan) | 0.5 days |
| 🔴 P0 | Add `in_app_purchase` package + Google Play products setup | 2 days |
| 🔴 P0 | Implement actual Google Play purchase flow in SubscriptionScreen | 3 days |
| 🔴 P0 | Create Supabase Edge Function for purchase verification | 2 days |
| 🟡 P1 | Create `subscription_usage` table migration (016) | 0.5 days |
| 🟡 P1 | Implement FeatureGate class + inject into providers | 2 days |
| 🟡 P1 | Add feature gate checks at student add/batch add touchpoints | 1 day |
| 🟡 P1 | Add WhatsApp usage tracking per account per month | 1 day |
| 🟢 P2 | Subscription renewal reminders (7 days before expiry) | 1 day |
| 🟢 P2 | Annual plan discount screen + toggle | 1 day |
| 🟢 P2 | Upgrade CTAs at natural limit moments (contextual, not modal) | 2 days |
| 🟢 P2 | Institute plan design + 4th tier UI | 3 days |
| ⚪ P3 | Razorpay web payment alternative for non-Play users | 2 days |
| ⚪ P3 | Referral program (₹100 credit on referral) | 2 days |
| ⚪ P3 | Admin analytics dashboard for subscription metrics | 3 days |

---

## KEY STRATEGIC RECOMMENDATIONS

### 1. Fix the Free Tier Number — Today
The inconsistency (20 in `defaultFree()` vs. 50 in PRD vs. plan definition) must be resolved. **Use 30 students** as the free limit. It's enough to be useful, creates upgrade pressure at growth, and is above TutorKhata's 10-student free tier.

### 2. Launch with "30-Day Growth Trial"
All new signups get 30 days of Growth features free, no card required. This is in the PRD. Implement it. It dramatically increases onboarding completion and creates habit before billing kicks in.

### 3. Annual Plan = Top Priority
Annual plan conversion is the most powerful lever for reducing churn and improving LTV. Highlight the annual saving prominently (₹2,000 savings on Growth = 4 months free). Push annual at every upgrade touchpoint.

### 4. WhatsApp is the Moat
The entire value of FeeSync is delivered through WhatsApp. Every receipt = brand touch. Protect this feature — keep WhatsApp receipts generous even in the free tier (100/mo is reasonable for 30 students at monthly billing). This drives word-of-mouth.

### 5. AI is the Growth Upsell, Not the Starter Upsell
The most powerful conversion driver from Starter → Growth will be "you're about to miss a payment from a student who always pays late — our AI predicted it." Position AI as the premium intelligence layer, not a checkbox feature.

### 6. Never Block — Always Nudge
The PRD got this right: "a friendly upgrade card appears on the dashboard — not a blocking modal." Enforce this religiously. Blocking modals destroy user experience and cause churn. Show upgrade opportunities contextually and gracefully.

---

*Analysis completed: June 6, 2026 | FeeSync v1.0 PRD April 2026 | Codebase audit depth: All 14 migrations, 15 models, 15 providers, 10 repositories, 30+ screens*
