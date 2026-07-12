// QuotaChecker — single source of truth for all quota/entitlement logic.
//
// Sentinel convention (must be used consistently throughout the app):
//   -1  →  unlimited (always allowed)
//    0  →  feature unavailable / not included in plan
//   > 0 →  finite cap; compare currentUsage against it
//
// All feature-gate and UI code MUST route through these helpers instead of
// performing raw integer comparisons.

class QuotaChecker {
  // Prevent instantiation — this is a pure-static utility class.
  QuotaChecker._();

  // ── Core predicates ────────────────────────────────────────────────────────

  /// Returns `true` when the user has reached or exceeded the quota [limit].
  ///
  /// -  limit == -1  →  unlimited, never reached
  /// -  limit ==  0  →  feature unavailable, always "reached"
  /// -  limit >   0  →  reached when [currentUsage] >= [limit]
  static bool hasReachedLimit(int currentUsage, int limit) {
    if (limit < 0) return false; // -1 = unlimited
    if (limit == 0) return true; // 0 = unavailable
    return currentUsage >= limit;
  }

  /// Returns `true` when the user is allowed to create/add one more item.
  ///
  /// -  limit == -1  →  unlimited, always allowed
  /// -  limit <=  0  →  not available
  /// -  limit >   0  →  allowed while [currentUsage] < [limit]
  static bool canCreate(int currentUsage, int limit) {
    if (limit < 0) return true;  // -1 = unlimited
    if (limit == 0) return false; // 0 = unavailable
    return currentUsage < limit;
  }

  // ── Derived helpers ────────────────────────────────────────────────────────

  /// Returns `true` when [limit] represents unlimited access.
  static bool isUnlimited(int limit) => limit < 0;

  /// Returns `true` when a feature is completely unavailable at this plan tier.
  static bool isUnavailable(int limit) => limit == 0;

  /// Usage ratio as a fraction [0.0, 1.0] suitable for progress indicators.
  ///
  /// -  limit == -1  →  0.0  (progress bar is empty — user can always add more)
  /// -  limit ==  0  →  1.0  (progress bar is full — feature unavailable)
  /// -  limit >   0  →  [currentUsage] / [limit], clamped to [0.0, 1.0]
  static double usageRatio(int currentUsage, int limit) {
    if (limit < 0) return 0.0; // unlimited → show empty bar
    if (limit == 0) return 1.0; // unavailable → show full bar
    return (currentUsage / limit).clamp(0.0, 1.0);
  }

  /// Returns how many more items the user can create before hitting the cap.
  ///
  /// Returns -1 for unlimited.
  /// Returns 0 when the limit is reached or the feature is unavailable.
  static int remainingSlots(int currentUsage, int limit) {
    if (limit < 0) return -1; // unlimited
    if (limit == 0) return 0; // unavailable
    final remaining = limit - currentUsage;
    return remaining < 0 ? 0 : remaining;
  }

  // ── UI helpers ─────────────────────────────────────────────────────────────

  /// Formats a [limit] value for display in the UI.
  ///
  /// -  -1  →  '∞'
  /// -   0  →  'N/A'
  /// -  >0  →  the number as a string (e.g. '500')
  static String formatLimit(int limit) {
    if (limit < 0) return '∞';
    if (limit == 0) return 'N/A';
    return limit.toString();
  }

  /// Formats a usage/limit pair as 'X / Y' where Y is either the number or '∞'.
  ///
  /// Example output:
  ///   - used=0, limit=-1   →  '0 / ∞'
  ///   - used=3, limit=50   →  '3 / 50'
  ///   - used=0, limit=0    →  'N/A'
  static String formatUsageDisplay(int used, int limit) {
    if (limit == 0) return 'N/A';
    return '$used / ${formatLimit(limit)}';
  }
}
