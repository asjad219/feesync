# FeeSync - Complete Setup Guide

FeeSync is a dual-platform application with a React/Next.js web app and a Flutter mobile app, both connected to a shared Supabase backend.

## Prerequisites

### For Web App (React/Next.js)
- Node.js 18+
- npm or yarn

### For Mobile App (Flutter)
- Flutter SDK (latest stable)
- Android SDK (for Android development)
- Xcode (for iOS development on macOS)

### For Backend (Supabase)
- Supabase account
- Supabase CLI

## Phase 1: Backend Setup (Shared)

### 1.1 Create Supabase Project

1. Go to [supabase.com](https://supabase.com) and create a new project
2. Note down the **Project URL** and **anon/public API key** from Settings > API
3. Also save the **service_role** key (keep this secret!)

### 1.2 Install and Configure Supabase CLI

```bash
# Install Supabase CLI
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref <your-project-ref>

# Push database migrations
supabase db push
```

**Alternative:** Run migrations manually in Supabase Dashboard SQL Editor:
1. Go to SQL Editor in Supabase Dashboard
2. Open and execute `supabase/migrations/001_initial_schema.sql`
3. Open and execute `supabase/migrations/002_rls_policies.sql`

### 1.3 Verify Migrations

Check that these tables exist in your Supabase database:
- `accounts`
- `users`
- `students`
- `fee_categories`
- `fee_structures`
- `payments`
- `payment_records`
- `notifications`
- `notification_settings`

## Phase 2: Web App Setup (React/Next.js)

### 2.1 Configure Environment Variables

```bash
cd feesync_web
cp .env.example .env.local
```

Edit `feesync_web/.env.local`:
```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project-ref.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
NEXT_PUBLIC_APP_URL=http://localhost:3000
RESEND_API_KEY=re_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx (optional)
EMAIL_FROM="FeeSync <noreply@feesync.app>" (optional)
```

### 2.2 Install Dependencies

```bash
cd feesync_web
npm install
```

### 2.3 Start Development Server

```bash
cd feesync_web
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

### 2.4 Create First Account

1. Go to `/signup`
2. Create account with email and password
3. Verify email (check inbox)
4. Log in with credentials

### 2.5 Build for Production

```bash
cd feesync_web
npm run build
npm start
```

## Phase 3: Mobile App Setup (Flutter)

### 3.1 Configure Supabase Connection

Edit `feesync_mobile/lib/core/config/supabase_config.dart`:

```dart
const String supabaseUrl = 'https://your-project-ref.supabase.co';
const String supabaseAnonKey = 'your-anon-key';
```

### 3.2 Get Flutter Dependencies

```bash
cd feesync_mobile
flutter clean
flutter pub get
```

### 3.3 Run on Emulator/Device

**Android:**
```bash
flutter emulators --launch Pixel_5_API_31
flutter run
```

**iOS (macOS only):**
```bash
open -a Simulator
flutter run
```

**Web:**
```bash
flutter run -d chrome
```

### 3.4 Build for Production

**Android APK:**
```bash
flutter build apk --release
# Output: build/app/outputs/apk/release/app-release.apk
```

**iOS:**
```bash
flutter build ios --release
# Output: build/ios/iphoneos/Runner.app
```

**Web:**
```bash
flutter build web --release
# Output: build/web/
```

## Phase 4: Demo Data Setup

After setting up both the web and mobile apps:

### Create via Web App
1. **Add Fee Categories**: Web App > Fees > Add Category
   - Examples: Tuition, Library, Sports, Exam
2. **Add Fee Structures**: Web App > Fees > Add Fee Structure
   - Set amount, class level, and due dates
3. **Add Students**: Web App > Students > Add Student
4. **Record Payment**: Web App > Payments > New Payment

### Verify Sync
1. Record a payment in the web app
2. Open the mobile app
3. Check that the payment appears in the mobile app's dashboard

## Troubleshooting

### Web App Issues

**"Cannot connect to Supabase"**
- Verify `.env.local` has correct Supabase URL and keys
- Check your Supabase project is active: `supabase projects list`
- Test connection: `curl https://your-project-ref.supabase.co/rest/v1/`

**"Authentication not working"**
- Enable Email provider in Supabase Dashboard > Authentication > Providers
- Check Supabase email settings (may require Resend or SendGrid config)

**"RLS policy errors"**
- Ensure both migrations have run successfully
- Check that `account_id` exists in your JWT claims
- Verify user profile is linked to an account

**"Port 3000 already in use"**
```bash
npm run dev -- -p 3001
```

### Mobile App Issues

**"Flutter SDK not found"**
```bash
flutter doctor
flutter upgrade
```

**"Supabase connection fails"**
- Verify `supabase_config.dart` has correct credentials
- Check device has internet connection
- Try running `flutter clean && flutter pub get`

**"iOS build fails"**
```bash
cd feesync_mobile/ios
rm -rf Pods Podfile.lock
cd ..
flutter clean
flutter pub get
flutter run
```

**"Android build fails"**
```bash
flutter clean
flutter pub get
flutter build apk --release
```

### Backend Issues

**"Migration fails with 'already exists' error"**
- The migration has already been applied
- Check `supabase_migrations` table
- If needed, start fresh with a new Supabase project

**"RLS policies not working"**
- Ensure you're authenticated and have JWT token
- Check `get_user_org_id()` and `get_user_role()` functions exist
- View RLS policies: Supabase Dashboard > SQL Editor > Run `SELECT * FROM auth.users;`

## Architecture Verification

After setup, verify both apps are working:

```bash
# In one terminal - Web app should start on :3000
cd feesync_web
npm run dev

# In another terminal - Mobile app
cd feesync_mobile
flutter run

# Both should connect to the same Supabase project
# Try creating data in web app and seeing it in mobile app
```

## Next Steps

1. ✅ Backend configured and migrations applied
2. ✅ Web app running on http://localhost:3000
3. ✅ Mobile app running on emulator or device
4. ✅ Demo data created
5. 🚀 Ready for development or deployment!

## Additional Resources

- [README.md](README.md) - Project overview
- [docs/01-architecture.md](docs/01-architecture.md) - System design
- [docs/03-database-schema.md](docs/03-database-schema.md) - Database structure
- [docs/05-rls-policies.md](docs/05-rls-policies.md) - Security policies
- [Supabase Documentation](https://supabase.com/docs)
- [Flutter Documentation](https://flutter.dev/docs)
- [Next.js Documentation](https://nextjs.org/docs)
