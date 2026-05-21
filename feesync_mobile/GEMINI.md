# FeeSync Mobile - Flutter Instructions

## Tech Stack
- **Framework:** Flutter (Material 3)
- **State Management:** Riverpod
- **Navigation:** GoRouter
- **Backend:** Supabase Flutter SDK
- **Design System:** Stitch (Dark theme, 16px rounded corners, Gradients)

## Conventions
- **Repository Pattern:** All data access must go through repository classes in `lib/repositories/`.
- **Providers:** Use Riverpod for all state management. Keep providers focused and granular.
- **Theme:** Adhere strictly to the Stitch design system colors and components defined in `lib/core/theme/`.
- **Widgets:** Prefer composition over deep inheritance. Keep widgets small and reusable in `lib/core/widgets/`.

## Folder Structure
- `lib/core/`: Configuration, constants, theme, and shared widgets.
- `lib/models/`: Data models with JSON serialization.
- `lib/providers/`: Riverpod providers.
- `lib/repositories/`: Data access layer.
- `lib/screens/`: Feature-specific screens.
- `lib/widgets/`: Feature-specific widgets.

## Development
- **Setup:** `flutter pub get`
- **Run:** `flutter run`
- **Test:** `flutter test`
- **Build APK:** `flutter build apk --release`

## Testing Standards
- Unit tests for models and repositories.
- Widget tests for critical UI components.
- Provider tests to verify state transitions.
