# RevenueCat Migration Plan — FeeSync Mobile

> **Status: `BLOCKED — CONFIGURATION REQUIRED`**
> Last updated: 2026-07-12
> Author: Engineering (via Antigravity planning session)

---

## Table of Contents

1. [Background & Goal](#1-background--goal)
2. [Audit Findings — Current Architecture](#2-audit-findings--current-architecture)
3. [Critical Security Finding](#3-critical-security-finding)
4. [Target Architecture](#4-target-architecture)
5. [Entitlement → Plan Mapping](#5-entitlement--plan-mapping)
6. [File-by-File Decision Table](#6-file-by-file-decision-table)
7. [Migration Phases](#7-migration-phases)
   - [Phase 1: Add RC SDK, Initialize, Identity](#phase-1--add-rc-sdk-initialize-identity)
   - [Phase 2: Refactor Domain Layer](#phase-2--refactor-domain-layer)
   - [Phase 3: Refactor SubscriptionScreen](#phase-3--refactor-subscriptionscreen)
   - [Phase 4: Supabase Backend Security & Webhook](#phase-4--supabase-backend-security--webhook)
   - [Phase 5: Remove Old IAP Runtime](#phase-5--remove-old-iap-runtime)
8. [Required External Configuration](#8-required-external-configuration)
9. [Open Decisions](#9-open-decisions)
10. [IAP Removal Checklist](#10-iap-removal-checklist)
11. [Migration Rules (Non-Negotiable)](#11-migration-rules-non-negotiable)
12. [Final Verification Gates](#12-final-verification-gates)

---

## 1. Background & Goal

FeeSync is a live Google Play SaaS app for school fee management. It currently processes subscriptions via:
- `in_app_purchase` Flutter plugin → Google Play Billing
- A custom `BillingService` that listens to the purchase stream, calls `completePurchase`, and then calls the Supabase `upsert_subscription` SECURITY DEFINER RPC directly from the client

**Goal:** Migrate to RevenueCat as the subscription management layer. RevenueCat handles purchase validation, entitlement tracking, subscription lifecycle, and webhook delivery to Supabase. The old `in_app_purchase` runtime is removed **only after** RevenueCat is fully tested and verified.

**Constraints:**
- App is live on Google Play — zero tolerance for breaking existing subscribers
- No "unlimited access for everyone" stubs allowed at any point
- No fabricated expiry (no `now + 32 days`) — RevenueCat/Google is the authority
- No dual purchase processing at runtime — only one billing runtime active at a time in production
- Supabase user UUID is the stable RC App User ID

---

## 2. Audit Findings — Current Architecture

### Current data flow

```
Google Play
  └─ in_app_purchase (plugin)
       └─ BillingService  (billing_service.dart)
            ├─ listens: _iap.purchaseStream
            ├─ calls: _iap.completePurchase(purchase)
            ├─ calculates expiry: DateTime.now() + Duration(days: 32 or 366)  ← HARDCODED
            └─ calls: Supabase RPC upsert_subscription()                        ← CLIENT-INITIATED

BillingProvider (billing_provider.dart)
  ├─ billingServiceProvider
  ├─ billingInitProvider         ← called in main.dart: ref.watch(billingInitProvider)
  ├─ billingResultStreamProvider
  ├─ billingProductProvider      ← used in subscription_screen.dart for live prices
  └─ purchaseControllerProvider  ← used in subscription_screen.dart for purchase action

SubscriptionRepository (subscription_repository.dart)
  ├─ getSubscription()           → SELECT from subscriptions table
  ├─ getActiveStudentCount()     → SELECT from students table (RLS-isolated)
  ├─ getActiveBatchCount()       → SELECT from batches table (RLS-isolated)
  ├─ getActiveStaffCount()       → SELECT from users table (RLS-isolated)
  ├─ upsertSubscription()        → client calls subscriptions table directly  ← REMOVE
  └─ upsertViaRpc()              → client calls upsert_subscription RPC       ← REMOVE

UsageRepository (usage_repository.dart)
  ├─ getCurrentMonthUsage()      → Supabase RPC get_current_usage()
  ├─ recordWhatsappReceipt()     → Supabase RPC increment_usage()
  ├─ recordWhatsappReminder()    → Supabase RPC increment_usage()
  ├─ recordSms()                 → Supabase RPC increment_usage()
  └─ recordAiCall()              → Supabase RPC increment_usage()

SubscriptionProvider (subscription_provider.dart)
  ├─ subscriptionRepositoryProvider
  ├─ usageRepositoryProvider
  ├─ subscriptionProvider        → SubscriptionRepository.getSubscription()
  ├─ activeStudentCountProvider  → SubscriptionRepository.getActiveStudentCount()
  ├─ activeBatchCountProvider    → SubscriptionRepository.getActiveBatchCount()
  ├─ activeStaffCountProvider    → SubscriptionRepository.getActiveStaffCount()
  ├─ currentMonthUsageProvider   → UsageRepository.getCurrentMonthUsage()
  ├─ featureGateProvider         ← consumed by 10 screens
  ├─ subscriptionScreenDataProvider ← consumed by settings_screen + subscription_screen
  └─ SubscriptionScreenData class

Subscription model (subscription.dart)
  ├─ Maps to Supabase schema columns: user_id, plan_type, billing_cycle, expiry_date, etc.
  ├─ Payment token fields: razorpaySubId, razorpayPaymentId, googlePlayPurchaseToken, googlePlayProductId
  ├─ Computed: effectivePlan, isPaidActive, isTrialActive, planLabel, daysRemaining
  └─ Static: defaultFree(), newUserTrial()

KEPT unchanged (plan-agnostic):
  ├─ plan_config.dart     → PlanConfig (tier limits, prices, highlights)
  ├─ feature_gate.dart    → FeatureGate (pure gate logic)
  └─ quota_checker.dart   → QuotaChecker (pure math)

SubscriptionScreen (subscription_screen.dart) — 1,646 lines
  ├─ reads: subscriptionScreenDataProvider
  ├─ reads: purchaseControllerProvider (loading overlay)
  ├─ reads: billingProductProvider(productId) (live Play prices in _PlanOptionCard)
  └─ calls: purchaseControllerProvider.notifier.purchase(productId)  ← REPLACE

PaywallDialog (paywall_dialog.dart)
  └─ routes to /settings/subscription → stays unchanged

10 screens consuming featureGateProvider:
  student_list_screen, add_edit_student_screen, student_details_screen,
  staff_list_screen, invite_edit_staff_screen, batch_list_screen,
  batch_creation_screen, batch_detail_screen, dashboard_screen,
  record_payment_screen
```

### Supabase schema (final state post-migration 034)

**Table: `subscriptions`**
| Column | Type | Notes |
|---|---|---|
| id | UUID PK | auto |
| user_id | UUID FK → auth.users | UNIQUE |
| plan_type | TEXT | `'free' \| 'starter' \| 'growth' \| 'institute'` |
| billing_cycle | TEXT | `'monthly' \| 'annual'` |
| expiry_date | TIMESTAMPTZ | null for free |
| max_students | INTEGER | -1 = unlimited |
| max_batches | INTEGER | -1 = unlimited |
| whatsapp_receipts_limit | INTEGER | -1 = unlimited |
| whatsapp_reminders_limit | INTEGER | -1 = unlimited |
| sms_limit | INTEGER | -1 = unlimited |
| max_staff | INTEGER | -1 = unlimited |
| status | TEXT | `'active' \| 'inactive' \| 'past_due' \| 'paused' \| 'cancelled'` |
| start_date | TIMESTAMPTZ | |
| google_play_purchase_token | TEXT | unique constraint |
| google_play_product_id | TEXT | |
| razorpay_sub_id | TEXT | |
| razorpay_payment_id | TEXT | unique constraint |
| trial_ends_at | TIMESTAMPTZ | |
| is_trial | BOOLEAN | |
| created_at / updated_at | TIMESTAMPTZ | |

**Table: `subscription_usage`**
| Column | Type |
|---|---|
| owner_id | UUID FK → auth.users |
| period_start | DATE (first of month) |
| whatsapp_receipts_used | INTEGER |
| whatsapp_reminders_used | INTEGER |
| sms_used | INTEGER |
| ai_calls_used | INTEGER |

**RPCs:**
- `upsert_subscription(p_owner_id, p_plan_tier, p_billing_cycle, p_valid_until, ...)` — SECURITY DEFINER
- `get_plan_limits(p_tier)` — returns JSONB with limits
- `get_current_usage(p_owner_id)` — returns current month usage row
- `increment_usage(p_owner_id, p_column, p_increment)` — increments a quota column

**No RevenueCat webhook Edge Function exists yet.**

### Existing pubspec.yaml billing dependency

```yaml
# Billing — Google Play In-App Purchases
in_app_purchase: ^3.2.0    # TO BE REMOVED in Phase 5
```

---

## 3. Critical Security Finding

> ⚠️ **HIGH SEVERITY — Independent of RevenueCat migration**

The `upsert_subscription` RPC has `SECURITY DEFINER` and is currently callable by any authenticated client. The client-side `BillingService._verifyAndActivate()` calls it after a purchase, and `SubscriptionRepository.upsertViaRpc()` also exposes it. Because the RLS UPDATE policy allows any owner to update their own subscription row, **any signed-in user can grant themselves any paid plan tier today without making a real purchase.**

**Fix:** Phase 4 locks this down by:
1. Revoking EXECUTE on `upsert_subscription` from `authenticated` and `anon` roles
2. Only the Supabase Edge Function (using `service_role` key) may call it
3. Replacing the client UPDATE policy with one that permits only `plan_type = 'free'`

---

## 4. Target Architecture

```
Google Play
  └─ RevenueCat SDK (purchases_flutter)
       └─ CustomerInfo (entitlements, active subscriptions, management URL)
            └─ RevenueCatService (new)
                 ├─ initialize(userId: supabaseUUID)
                 ├─ logIn(userId) / logOut()
                 ├─ purchase(Package) → CustomerInfo
                 ├─ restorePurchases() → CustomerInfo
                 ├─ manageSubscription() → opens Play billing portal (via CustomerInfo.managementURL)
                 └─ CustomerInfo stream listener → invalidates subscriptionProvider

RevenueCatProvider (new — replaces BillingProvider)
  ├─ revenueCatServiceProvider
  ├─ revenueCatInitProvider        (replaces billingInitProvider in main.dart)
  ├─ customerInfoStreamProvider    (StreamProvider<CustomerInfo>)
  ├─ customerInfoProvider          (FutureProvider<CustomerInfo>)
  ├─ rcOfferingsProvider           (FutureProvider<Offerings>)
  └─ rcPurchaseControllerProvider  (replaces purchaseControllerProvider)

SubscriptionMapper (new)
  └─ CustomerInfo → Subscription domain model
       (precedence: institute > growth > starter > free)
       (never grants access on error/null)

SubscriptionProvider (refactored — same exported API)
  ├─ subscriptionProvider          (reads RC CustomerInfo → SubscriptionMapper)
  ├─ activeStudentCountProvider    (unchanged — reads Supabase)
  ├─ activeBatchCountProvider      (unchanged — reads Supabase)
  ├─ activeStaffCountProvider      (unchanged — reads Supabase)
  ├─ currentMonthUsageProvider     (unchanged — reads UsageRepository)
  ├─ featureGateProvider           (unchanged API — all 10 screens unaffected)
  └─ subscriptionScreenDataProvider (unchanged API)

RevenueCat Webhook
  └─ Supabase Edge Function: revenuecat_webhook
       ├─ validates Authorization: Bearer <RC_WEBHOOK_SECRET>
       ├─ handles: INITIAL_PURCHASE, RENEWAL, PRODUCT_CHANGE, CANCELLATION, EXPIRATION, BILLING_ISSUE
       └─ calls upsert_subscription with service_role key
            └─ subscriptions table (backend mirror — read-only for clients after Phase 4)

UsageRepository (unchanged)
  └─ reads subscription_usage via Supabase RPCs
```

---

## 5. Entitlement → Plan Mapping

Single source of truth. Same mapping used in `SubscriptionMapper` (client) and webhook (server).

```
RevenueCat Entitlement ID   →   FeeSync plan_type   →   PlanConfig tier
──────────────────────────────────────────────────────────────────────
feesync_institute           →   'institute'          →   PlanConfig.institute
feesync_growth              →   'growth'             →   PlanConfig.growth
feesync_starter             →   'starter'            →   PlanConfig.starter
(no active entitlement)     →   'free'               →   PlanConfig.free
```

**Precedence rule:** When multiple entitlements are active simultaneously (edge case), use the highest tier: `institute > growth > starter`.

> ⚠️ The entitlement IDs above (`feesync_institute`, `feesync_growth`, `feesync_starter`) are **placeholders** — must be replaced with actual identifiers from the RevenueCat Dashboard before Phase 2 implementation.

---

## 6. File-by-File Decision Table

### Flutter mobile (`feesync_mobile/lib/`)

| File | Action | Reason |
|---|---|---|
| `core/billing/billing_service.dart` | **REPLACE** (Phase 5 delete) | `InAppPurchase`, `purchaseStream`, `completePurchase`, client-side expiry, client RPC call |
| `core/billing/billing_provider.dart` | **REPLACE** (Phase 5 delete) | Wraps `BillingService`; providers replaced by `revenue_cat_provider.dart` |
| `core/billing/revenue_cat_service.dart` | **NEW** (Phase 1) | RC SDK wrapper |
| `core/billing/revenue_cat_provider.dart` | **NEW** (Phase 1) | Riverpod providers for RC |
| `core/billing/subscription_mapper.dart` | **NEW** (Phase 2) | `CustomerInfo` → `Subscription` domain model |
| `core/billing/plan_config.dart` | **KEEP unchanged** | Plan-agnostic limits/prices |
| `core/billing/feature_gate.dart` | **KEEP unchanged** | Pure gate logic |
| `core/billing/quota_checker.dart` | **KEEP unchanged** | Pure math |
| `models/subscription.dart` | **REFACTOR** (Phase 2) | Remove payment token fields from domain model; keep all computed getters |
| `repositories/subscription_repository.dart` | **REFACTOR** (Phase 2) | Remove `upsertSubscription()` and `upsertViaRpc()`; keep read methods |
| `repositories/usage_repository.dart` | **KEEP unchanged** | Quota tracking — unrelated to billing provider |
| `providers/subscription_provider.dart` | **REFACTOR** (Phase 2) | Wire to RC CustomerInfo instead of old billing chain; preserve exported API |
| `screens/settings/screens/subscription_screen.dart` | **REFACTOR** (Phase 3) | Replace `BillingProductIds`/`purchaseControllerProvider`/`billingProductProvider` with RC Offerings/Packages; keep all UI structure |
| `screens/settings/settings_screen.dart` | **KEEP unchanged** | Uses `subscriptionScreenDataProvider` API — unchanged |
| `core/widgets/paywall_dialog.dart` | **KEEP unchanged** | Routes to `/settings/subscription` — still correct |
| `router.dart` | **KEEP unchanged** | `/settings/subscription` route stays |
| `main.dart` | **SMALL PATCH** (Phase 1 & 5) | Phase 1: add `revenueCatInitProvider`; Phase 5: remove `billingInitProvider` |
| All 10 feature-gated screens | **KEEP unchanged** | Use `featureGateProvider` — API contract preserved |

### Supabase (`supabase/`)

| File | Action | Phase |
|---|---|---|
| `functions/revenuecat_webhook/index.ts` | **NEW** | 4 |
| `migrations/050_lock_subscription_writes.sql` | **NEW** | 4 |
| `migrations/051_add_revenuecat_fields.sql` | **NEW** (optional) | 4 |

### `pubspec.yaml`

| Dependency | Action | Phase |
|---|---|---|
| `purchases_flutter: ^x.x.x` | **ADD** | 1 |
| `in_app_purchase: ^3.2.0` | **REMOVE** | 5 (after checklist) |

---

## 7. Migration Phases

### Phase 1 — Add RC SDK, Initialize, Identity

**Goal:** RC SDK runs alongside old IAP. No purchase flows changed yet. Dual-run is safe because RC is read-only in Phase 1 (no purchase calls yet).

#### 1.1 Add dependency
```yaml
# pubspec.yaml
purchases_flutter: ^8.x.x   # verify latest stable at implementation time
```

#### 1.2 Create `lib/core/billing/revenue_cat_service.dart`

Responsibilities:
- `initialize({required String userId})` — call `Purchases.configure(...)` with Android API key + userId
- `logIn(String userId)` — call `Purchases.logIn(userId)` on Supabase auth sign-in
- `logOut()` — call `Purchases.logOut()` on Supabase auth sign-out
- `Future<CustomerInfo> currentCustomerInfo()` — `Purchases.getCustomerInfo()`
- `Stream<CustomerInfo> get customerInfoStream` — `Purchases.customerInfoStream`
- `Future<CustomerInfo> purchase(Package package)` — `Purchases.purchasePackage(package)`
- `Future<CustomerInfo> restorePurchases()` — `Purchases.restorePurchases()`
- `Future<Offerings> getOfferings()` — `Purchases.getOfferings()`

**Identity rule:** Always use `Supabase.instance.client.auth.currentUser?.id` (UUID) as the RC App User ID. Never use email.

**Error handling:** All methods must catch `PlatformException` and re-throw as typed `RevenueCatException`. Network errors must not downgrade a paid user.

**App restart recovery:** RC SDK caches `CustomerInfo` on-device. On cold start, `Purchases.getCustomerInfo()` returns the cached value immediately, then refreshes from network. No additional local cache is needed.

#### 1.3 Create `lib/core/billing/revenue_cat_provider.dart`

```dart
final revenueCatServiceProvider = Provider<RevenueCatService>(...);

/// Replaces billingInitProvider. Initializes RC at app startup.
final revenueCatInitProvider = FutureProvider<void>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return; // unauthenticated — RC init deferred to login
  final service = ref.read(revenueCatServiceProvider);
  await service.initialize(userId: userId);
});

/// Live CustomerInfo stream — invalidates subscriptionProvider on every RC update.
final customerInfoStreamProvider = StreamProvider<CustomerInfo>((ref) {
  return ref.read(revenueCatServiceProvider).customerInfoStream;
});

/// Point-in-time CustomerInfo snapshot.
final customerInfoProvider = FutureProvider<CustomerInfo>((ref) async {
  return ref.read(revenueCatServiceProvider).currentCustomerInfo();
});

/// RC Offerings (for plan selection UI with localized prices).
final rcOfferingsProvider = FutureProvider<Offerings>((ref) async {
  return ref.read(revenueCatServiceProvider).getOfferings();
});

/// Replaces PurchaseController / purchaseControllerProvider.
class RcPurchaseController extends AsyncNotifier<void> { ... }
final rcPurchaseControllerProvider = AsyncNotifierProvider<RcPurchaseController, void>(...);
```

#### 1.4 Patch `lib/main.dart`

```dart
// ADD (alongside existing billingInitProvider during dual-run):
ref.watch(revenueCatInitProvider);

// Listen to Supabase auth changes to call RC logIn/logOut:
ref.listen(supabaseAuthStateProvider, (_, state) {
  final service = ref.read(revenueCatServiceProvider);
  if (state.event == AuthChangeEvent.signedIn) {
    service.logIn(state.session!.user.id);
  } else if (state.event == AuthChangeEvent.signedOut) {
    service.logOut();
  }
});
```

---

### Phase 2 — Refactor Domain Layer (Zero Screen Impact)

**Goal:** All data flows through RC CustomerInfo. The exported `featureGateProvider` and `subscriptionScreenDataProvider` APIs are unchanged — all 10 consuming screens compile and work without modification.

#### 2.1 Refactor `lib/models/subscription.dart`

- **Remove from domain model** (keep as DB columns — webhook concern):
  - `razorpaySubId`, `razorpayPaymentId`
  - `googlePlayPurchaseToken`, `googlePlayProductId`
- **Keep all** computed getters: `effectivePlan`, `isPaidActive`, `isTrialActive`, `planLabel`, `daysRemaining`, `isExpiringSoon`, `currentMaxStudents`, `currentMaxBatches`, etc.
- **Keep**: `defaultFree()`, `newUserTrial()`, `copyWith()`
- **Keep**: `fromJson()` for Supabase mirror reads (fallback path)
- **Add**: optional `revenueCatEntitlementId` field for logging/debugging

#### 2.2 Create `lib/core/billing/subscription_mapper.dart`

```dart
class SubscriptionMapper {
  /// Maps RevenueCat CustomerInfo to FeeSync Subscription domain model.
  /// Precedence: institute > growth > starter > free.
  /// NEVER returns a paid plan on error — returns null to signal loading/error.
  static Subscription? fromCustomerInfo(CustomerInfo? info, String userId) {
    if (info == null) return null; // loading — caller uses Supabase mirror or shows loading
    
    final entitlements = info.entitlements.active;
    
    String planType = 'free';
    String? entitlementId;
    
    // Precedence check (highest first):
    if (entitlements.containsKey('feesync_institute')) {
      planType = 'institute';
      entitlementId = 'feesync_institute';
    } else if (entitlements.containsKey('feesync_growth')) {
      planType = 'growth';
      entitlementId = 'feesync_growth';
    } else if (entitlements.containsKey('feesync_starter')) {
      planType = 'starter';
      entitlementId = 'feesync_starter';
    }
    
    final config = PlanConfig.fromTier(planType);
    final activeEntitlement = entitlementId != null ? entitlements[entitlementId] : null;
    
    return Subscription(
      id: info.originalAppUserId,
      userId: userId,
      planType: planType,
      billingCycle: _extractBillingCycle(activeEntitlement),
      expiryDate: activeEntitlement?.expirationDate,  // authoritative from RC/Google
      status: planType == 'free' ? 'active' : 'active',
      startDate: activeEntitlement?.latestPurchaseDate ?? DateTime.now(),
      maxStudents: config.maxStudents,
      maxBatches: config.maxBatches,
      whatsappReceiptsLimit: config.whatsappReceiptsPerMonth,
      whatsappRemindersLimit: config.whatsappRemindersPerMonth,
      smsLimit: 0,
      maxStaff: config.maxStaff,
      revenueCatEntitlementId: entitlementId,
    );
  }
}
```

#### 2.3 Refactor `lib/providers/subscription_provider.dart`

State machine for `subscriptionProvider`:

| RC state | Supabase mirror available | Result |
|---|---|---|
| Loading | — | `AsyncLoading` |
| Error (network blip) | Yes | Emit Supabase mirror value as `AsyncData` (paid user not downgraded) |
| Error (network blip) | No | `AsyncError` |
| Success, active entitlement | — | RC-mapped `Subscription` |
| Success, no entitlement | — | `Subscription.defaultFree(userId)` |
| Unauthenticated | — | `Subscription.defaultFree('')` |

```dart
final subscriptionProvider = FutureProvider<Subscription>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return Subscription.defaultFree('');

  // Watch RC stream so provider re-evaluates on every CustomerInfo update:
  final rcStream = ref.watch(customerInfoStreamProvider);
  
  CustomerInfo? customerInfo;
  try {
    customerInfo = await ref.watch(customerInfoProvider.future);
  } catch (_) {
    // RC network error: fall back to Supabase mirror to avoid downgrading a paid user
    return ref.watch(subscriptionRepositoryProvider).getSubscription();
  }
  
  final mapped = SubscriptionMapper.fromCustomerInfo(customerInfo, userId);
  if (mapped == null) {
    // RC not initialized yet — fall back to Supabase mirror
    return ref.watch(subscriptionRepositoryProvider).getSubscription();
  }
  return mapped;
});
```

All other providers (`activeStudentCountProvider`, `activeBatchCountProvider`, `activeStaffCountProvider`, `currentMonthUsageProvider`, `featureGateProvider`, `subscriptionScreenDataProvider`, `SubscriptionScreenData`) remain **unchanged**.

#### 2.4 Refactor `lib/repositories/subscription_repository.dart`

- **REMOVE** `upsertSubscription(Map<String, dynamic> data)`
- **REMOVE** `upsertViaRpc({...})`
- **KEEP** `getSubscription()` — used as Supabase mirror fallback
- **KEEP** `_createDefaultSubscription(uid)` — creates free row for new users
- **KEEP** `getActiveStudentCount()`, `getActiveBatchCount()`, `getActiveStaffCount()`

---

### Phase 3 — Refactor SubscriptionScreen

**Goal:** Purchase flow uses RC Offerings/Packages. All existing UI structure (plan comparison cards, usage bars, billing toggle, FAQ, policies) is preserved. Only the purchase action changes.

#### 3.1 Remove old billing imports

```dart
// REMOVE from subscription_screen.dart:
import '../../../core/billing/billing_provider.dart';  // BillingProductIds, purchaseControllerProvider, billingProductProvider
import '../../../core/billing/billing_service.dart';   // BillingProductIds

// REPLACE with:
import '../../../core/billing/revenue_cat_provider.dart';
```

#### 3.2 Replace purchase state watcher

```dart
// OLD:
final purchaseState = ref.watch(purchaseControllerProvider);

// NEW:
final purchaseState = ref.watch(rcPurchaseControllerProvider);
```

#### 3.3 Replace `_PlanOptionCard` product lookup and purchase call

```dart
// OLD:
final productId = BillingProductIds.forPlan(plan.tier, annual: isAnnual);
final product = ref.watch(billingProductProvider(productId));
final displayPrice = product?.price ?? '₹${...}';
ref.read(purchaseControllerProvider.notifier).purchase(productId);

// NEW:
final offeringsAsync = ref.watch(rcOfferingsProvider);
// From offerings, find the Package for this plan tier + billing cycle
// Package exposes: package.storeProduct.priceString (localized, from Play Store)
final package = _findPackage(offeringsAsync.value, plan.tier, isAnnual);
final displayPrice = package?.storeProduct.priceString ?? '₹${...}'; // fallback to PlanConfig price
ref.read(rcPurchaseControllerProvider.notifier).purchase(package);
```

#### 3.4 Add Restore Purchases button

```dart
// In SubscriptionScreen — new action in AppBar or plan card:
ElevatedButton(
  onPressed: () => ref.read(rcPurchaseControllerProvider.notifier).restore(),
  child: const Text('Restore Purchases'),
);
```

#### 3.5 Add Manage Subscription

```dart
// Uses RevenueCat CustomerInfo.managementURL — opens Play Store subscription management
final customerInfo = ref.watch(customerInfoProvider).valueOrNull;
if (customerInfo?.managementURL != null) {
  // show "Manage Subscription" button → launchUrl(customerInfo.managementURL!)
}
```

---

### Phase 4 — Supabase Backend Security & Webhook

> ⚠️ **Apply 050 migration ONLY after the webhook is deployed and tested.** Applying it before the webhook is ready will break all subscription activations.

#### 4.1 `supabase/migrations/050_lock_subscription_writes.sql`

```sql
BEGIN;

-- Lock down: revoke direct RPC access from authenticated clients
REVOKE EXECUTE ON FUNCTION upsert_subscription FROM authenticated;
REVOKE EXECUTE ON FUNCTION upsert_subscription FROM anon;

-- Replace permissive UPDATE policy with a restricted one:
-- Clients may only update their own row when staying on free plan
DROP POLICY IF EXISTS "Owner can update own subscription" ON subscriptions;
CREATE POLICY "Owner can only maintain free subscription"
  ON subscriptions FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (plan_type = 'free');

-- Client can still INSERT their own free-tier row (new user creation)
-- The existing INSERT policy is correct, no change needed.

COMMIT;
```

#### 4.2 `supabase/migrations/051_add_revenuecat_fields.sql`

```sql
BEGIN;

ALTER TABLE subscriptions
  ADD COLUMN IF NOT EXISTS revenuecat_entitlement_id TEXT,
  ADD COLUMN IF NOT EXISTS revenuecat_customer_id     TEXT,
  ADD COLUMN IF NOT EXISTS revenuecat_event_id        TEXT; -- for webhook idempotency

CREATE INDEX IF NOT EXISTS idx_sub_rc_customer_id ON subscriptions(revenuecat_customer_id);
CREATE INDEX IF NOT EXISTS idx_sub_rc_event_id ON subscriptions(revenuecat_event_id);

COMMENT ON COLUMN subscriptions.revenuecat_entitlement_id IS 'Active RC entitlement ID at last webhook event';
COMMENT ON COLUMN subscriptions.revenuecat_customer_id    IS 'RC originalAppUserId (= Supabase user UUID)';
COMMENT ON COLUMN subscriptions.revenuecat_event_id       IS 'Last processed RC webhook event ID for idempotency';

COMMIT;
```

#### 4.3 `supabase/functions/revenuecat_webhook/index.ts`

Logic:
1. Validate `Authorization: Bearer <REVENUE_CAT_WEBHOOK_SECRET>` header — return 401 if invalid
2. Parse RevenueCat event body (JSON)
3. Extract `app_user_id` (= Supabase UUID), `event.id` (for idempotency), product info
4. Check if `event.id` already processed (via `revenuecat_event_id` column) — return 200 if duplicate
5. Map event type to plan action:

| RC Event Type | Action |
|---|---|
| `INITIAL_PURCHASE` | upsert: active, correct plan tier, expiry from RC |
| `RENEWAL` | upsert: active, update expiry |
| `PRODUCT_CHANGE` | upsert: active, new plan tier |
| `RESTORATION` | upsert: active, restore plan |
| `CANCELLATION` | update status → `cancelled`; keep expiry (access until period end) |
| `EXPIRATION` | update status → `inactive`; reset limits to free |
| `BILLING_ISSUE` | update status → `past_due` |
| `GRACE_PERIOD_STARTED` | update status → `past_due` |
| `GRACE_PERIOD_EXPIRED` | update status → `inactive` |

6. Map RC product identifier → FeeSync plan tier using same precedence rule
7. Call `upsert_subscription` using Supabase `service_role` client (bypasses RLS)
8. Return 200 OK

**Expiry:** Use `event.expiration_at_ms` (Unix ms timestamp from RC) — never calculate `now + N days`.

---

### Phase 5 — Remove Old IAP Runtime

> **Do NOT begin Phase 5 until the checklist in Section 10 is fully GREEN.**

#### 5.1 Files to delete

```
lib/core/billing/billing_service.dart
lib/core/billing/billing_provider.dart
```

#### 5.2 pubspec.yaml change

```yaml
# REMOVE:
in_app_purchase: ^3.2.0

# Keep:
purchases_flutter: ^x.x.x
```

#### 5.3 main.dart cleanup

```dart
// REMOVE:
import 'core/billing/billing_provider.dart';
ref.watch(billingInitProvider);
```

#### 5.4 All remaining import cleanup

Grep and remove all remaining references to:
- `import 'package:in_app_purchase/in_app_purchase.dart'`
- `BillingService`, `BillingProductIds`, `BillingResult`
- `billingInitProvider`, `billingServiceProvider`, `billingResultStreamProvider`
- `billingProductProvider`, `purchaseControllerProvider`, `PurchaseController`
- `purchaseStream`, `PurchaseDetails`, `completePurchase`, `pendingCompletePurchase`

#### 5.5 Run full validation

```bash
cd feesync_mobile
flutter pub get
dart format .
flutter analyze
flutter test
```

---

## 8. Required External Configuration

The following must be provided/configured before the indicated phase can be implemented.

| # | Required Item | Phase | Source |
|---|---|---|---|
| 1 | RevenueCat project created, Google Play app connected | 1 | [app.revenuecat.com](https://app.revenuecat.com) → New Project |
| 2 | **Android SDK API Key** (`goog_xxx`) | 1.2 | RC Dashboard → Your Project → Apps → Android → Public SDK Key |
| 3 | **Entitlement IDs** (exact strings for starter / growth / institute) | 2.2 | RC Dashboard → Entitlements → create if not done |
| 4 | **Offering ID** (default offering identifier) | 3.3 | RC Dashboard → Offerings |
| 5 | **Package IDs** (monthly + annual for each plan) | 3.3 | RC Dashboard → Offerings → Packages |
| 6 | **Google Play product IDs** confirmed/linked in RC | 3.3 | RC Dashboard → Products (current IDs: `feesync_starter_monthly`, `feesync_starter_yearly`, `feesync_growth_monthly`, `feesync_growth_yearly`, `feesync_institute_monthly`, `feesync_institute_yearly`) |
| 7 | **RevenueCat Webhook Secret** | 4.2 | RC Dashboard → Project → Integrations → Webhooks → Add endpoint → copy signing secret |
| 8 | **Supabase Edge Function deployed**, URL registered in RC Dashboard as webhook endpoint | 4.2 | `supabase functions deploy revenuecat_webhook`, then paste URL into RC Webhooks |
| 9 | **`REVENUE_CAT_WEBHOOK_SECRET` Supabase secret** set | 4.2 | `supabase secrets set REVENUE_CAT_WEBHOOK_SECRET=<value>` |

---

## 9. Open Decisions

### Decision 1 — Existing Paid Subscriber Migration Strategy

Users who purchased via the old Google Play IAP flow have rows in Supabase `subscriptions` with `google_play_purchase_token` and a valid `expiry_date`. RevenueCat will not automatically know about these purchases until the user opens the app with the RC-integrated build.

**Options:**

- **Option A** — Supabase mirror fallback: During Phase 2, if RC CustomerInfo has no active entitlement but Supabase shows a non-free plan with a future `expiry_date`, treat the Supabase record as authoritative. This transparently protects existing subscribers.
- **Option B** — User-prompted restore: Show a one-time banner to existing paid users: "Tap Restore Purchases to verify your subscription." RC syncs with Google Play and grants the entitlement.
- **Option C (Recommended)** — Both A + B: Use Supabase mirror as fallback (Option A) AND show a non-blocking restore prompt to users with `plan_type != 'free'` in DB but no RC entitlement (Option B).

> **Decision needed:** Which option to implement?

### Decision 2 — Trial Management Ownership

The current `Subscription` model has `isTrial` and `trialEndsAt` fields. The `newUserTrial()` factory creates a 30-day Growth trial.

**Options:**
- **RevenueCat manages trials** — configure free trial periods on Google Play base plans; RC reports trial status in `CustomerInfo`. The `isTrial`/`trialEndsAt` fields in the domain model become redundant.
- **FeeSync manages trials manually** — keep the existing trial activation logic in Supabase; RC is only used for paid purchases.

> **Decision needed:** Does RevenueCat manage your trial periods?

---

## 10. IAP Removal Checklist

All items must be manually verified on a real Android device before Phase 5 begins. Do not self-certify based on emulator or compilation alone.

- [ ] RC SDK initializes successfully on cold app start
- [ ] RC `logIn` correctly uses Supabase UUID (verified in RC Dashboard → Customer lookup)
- [ ] RC Offerings load — correct plans/packages appear in the upgrade sheet
- [ ] Test purchase completes in sandbox → RC Dashboard shows active entitlement for test user
- [ ] Correct FeeSync plan tier activates after purchase (feature gate opens, quota limits update)
- [ ] App killed and restarted after purchase → entitlement still active (RC on-device cache works)
- [ ] "Restore Purchases" button works → grants correct plan after uninstall + reinstall
- [ ] Logout (Supabase sign-out) → RC `logOut` called → plan reverts to free
- [ ] Login as different user → no entitlement leaked from previous user's session
- [ ] Login as same user again → entitlement correctly restores from RC
- [ ] RC webhook fires on test purchase → verified in RC Dashboard → Event History
- [ ] Supabase `subscriptions` row updated correctly by webhook (plan_type, expiry_date, status)
- [ ] Subscription cancellation → Supabase row updated by webhook (status → `cancelled`)
- [ ] Subscription expiry → Supabase row updated by webhook (status → `inactive`)
- [ ] `upsert_subscription` RPC returns permission error when called as authenticated client (post-migration-050)
- [ ] `flutter analyze` → **zero errors**
- [ ] `flutter test` → **all tests pass**
- [ ] Release build compiles successfully

---

## 11. Migration Rules (Non-Negotiable)

These rules were set by the product owner and govern all implementation decisions:

1. **KEEP** and reuse: `plan_config.dart`, `quota_checker.dart`, `feature_gate.dart`, `usage_repository.dart`, existing `/settings/subscription` route and UI, `featureGateProvider` API
2. **REFACTOR** instead of blindly deleting: `subscription.dart`, `subscription_provider.dart`, `subscription_screen.dart`, `subscription_repository.dart`
3. **REPLACE**: `billing_service.dart`, `billing_provider.dart`, direct `InAppPurchase` usage — but only after RC is tested
4. **NEVER** create an "unlimited access for everyone" stub. The four states are: loading | active paid | confirmed free | error. Temporary failure must not grant access or permanently demote a paid user.
5. **Supabase UUID** is the stable RC App User ID. Test account switching.
6. **Architecture flow**: `Google Play → RevenueCat → CustomerInfo → FeeSync domain model → PlanConfig → FeatureGate → QuotaChecker`
7. RevenueCat handles subscription lifecycle. FeeSync handles app-specific quotas/usage.
8. Use RC Offerings/Packages for purchase and localized prices. Do not hardcode prices as billing authority.
9. Implement: RC init, CustomerInfo listener, purchase, restore, manage subscription, login/logout identity, app restart recovery, proper error handling.
10. Use `RevenueCat webhook → Supabase Edge Function → subscription mirror`. Validate webhook auth. Idempotent processing.
11. **Never fabricate expiry** with `now + N days`. Use authoritative RC/Google lifecycle data.
12. Do not run RC and old IAP purchase processing simultaneously in the final runtime.
13. Prove all 18 checklist items pass before deleting old IAP code.
14. Remove all obsolete IAP references in Phase 5.
15. Do not invent: API key, entitlement IDs, offering/package IDs, Google Play product IDs, webhook secret, or database schema.

---

## 12. Final Verification Gates

After Phase 5, the final status is classified as one of:

| Status | Conditions |
|---|---|
| `BLOCKED — CONFIGURATION REQUIRED` | Any required external config item is missing |
| `READY FOR INTERNAL TESTING` | All 18 checklist items pass on a real device; `flutter analyze` clean; no IAP references remain |
| `READY FOR PRODUCTION RELEASE` | Internal testing passed + real Google Play test purchase (not sandbox) verified + RC webhook confirmed in production + migration-050 applied to production DB |

> ⚠️ **Never claim `READY FOR PRODUCTION RELEASE` based only on successful compilation.** Real device, real purchase, real webhook sync, real account-switching, real restore, and real IAP removal must all pass.

---

*End of REVENUECAT_MIGRATION.md*
