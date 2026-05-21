# FeeSync Lite - Implementation Roadmap (PRD v1.0)

Source: PRD & Design Idea/FeeSync_Lite_PRD_v1.0_Final.pdf
Edition: Single-Admin
Status: Production-Ready Specification
Date: April 2026

## Executive Summary (Implementation Lens)
- Market: 1.5M+ Indian private coaching centers, mostly solo operators
- Audience: 8M+ individual tutors across India
- Value: zero paper, WhatsApp-first receipts, offline-tolerant, full fee engine
- Payments: Razorpay native with UPI QR and payment links
- Usability: zero accounting skills required
- Platforms: Flutter + Web ship together
- Onboarding: < 3 minutes to first payment
- Pricing: free tier for up to 50 students, entry paid tier INR 199/month
- AI: 9 AI features built in

## Market Context and Personas
Primary personas and needs:
- Solo coaching owner (40-150 students): real-time revenue and overdue visibility
- Home tutor (15-60 students): fast cash/UPI recording and WhatsApp receipts
- Yoga/fitness instructor (20-80 students): batch-wise monthly fee tracking
- Music/dance teacher (10-50 students): per-class payment recording, absence alerts
- Spoken English/IELTS (15-40 students): course fee installment tracking
- Art/skill coach (8-30 students): one-time receipt and renewal reminders
- Single-subject coaching (50-150 students): bulk overdue reminders and monthly P and L clarity

Pain points and product solutions:
- Lost fee register -> cloud-synced searchable records
- No real-time overdue view -> live dashboard for overdue count and amount
- Manual receipt writing -> auto PDF receipts + WhatsApp delivery
- No bulk reminders -> one-tap bulk WhatsApp reminders
- Cash/UPI confusion -> payment mode tracking with reconciliation report
- No monthly P and L view -> automated P and L by month, exportable
- Student data lost on exit -> soft delete with full history preserved
- Multiple fee arrangements -> per-student fee assignment with discounts/waivers
- No attendance alerts -> same-day WhatsApp absence alerts to parents

## Stitch Design References
Use these Stitch screens as the UI baseline for the roadmap scope:
- PRD & Design Idea/stitch/splash_screen
- PRD & Design Idea/stitch/login_screen
- PRD & Design Idea/stitch/sign_up_screen
- PRD & Design Idea/stitch/onboarding_1
- PRD & Design Idea/stitch/dashboard
- PRD & Design Idea/stitch/students_list
- PRD & Design Idea/stitch/student_details
- PRD & Design Idea/stitch/add_edit_student
- PRD & Design Idea/stitch/add_new_batch
- PRD & Design Idea/stitch/batch_management_updated
- PRD & Design Idea/stitch/payments_screen
- PRD & Design Idea/stitch/record_payment
- PRD & Design Idea/stitch/reports_analytics
- PRD & Design Idea/stitch/settings
- PRD & Design Idea/stitch/midnight_obsidian

## Product Architecture (Baseline)
### Technology Stack
- Frontend (Web): React 18 + Vite + TypeScript
- Styling: Tailwind CSS + shadcn/ui
- State: Zustand + React Query
- Backend/DB: Supabase (PostgreSQL + Auth + Realtime)
- Storage: Supabase Storage (receipts, documents, expense photos, logos)
- Deployment (Web): Vercel
- Mobile App: Flutter 3 + Dart
- Payments: Razorpay
- WhatsApp: Meta Cloud API or Interakt or WATI
- SMS: Fast2SMS or MSG91
- Email: Resend
- PDF: React-PDF (client) + Puppeteer (edge)
- AI: Gemini API or OpenAI GPT-4
- Monitoring: Sentry
- Analytics: Supabase PostgREST + custom views

### Core Data Model (Single-Admin, Owner Scoped)
All tables are scoped to owner_id with RLS. One center_profile row per owner.
- center_profile: owner_id, center_name, logo_url, address, gstin, receipt_prefix, default_due_day
- students: owner_id, name, parent_phone, whatsapp_no, batch_id, status, admission_no
- batches: owner_id, name, subject, teacher_name, capacity, fee_amount, schedule_json
- fee_plans: owner_id, type, amount, due_day, late_fine, grace_days, gst_percent
- fee_assignments: student_id, fee_plan_id, start_date, discount_amount, waiver_reason
- payments: student_id, amount, mode, receipt_no, utr_ref, created_at
- dues (materialized): student_id, period, assigned, paid, outstanding
- expenses: owner_id, category, amount, vendor, payment_mode, receipt_url, date
- attendance: student_id, batch_id, date, status
- notifications_log: student_id, type, channel, status, sent_at
- subscriptions: owner_id, plan_tier, valid_until, max_students, razorpay_sub_id

## Roadmap Structure
The roadmap is organized by product workstreams with milestone mapping to the Release Roadmap.

## Workstreams and Full Scope

### Phase 1) Authentication and Onboarding
Onboarding target: first payment in under 3 minutes.
- Single-admin model: exactly one owner account per center, no staff invites
- Login: email/password and Google OAuth (phone OTP in v2)
- Session: short-lived JWT + refresh token, auto-expire after 30 days inactivity
- 2FA: TOTP prompt at first login, skippable once, mandatory for security
- Password reset: email-based via Supabase Auth
- Account deletion: self-delete with data erasure within 30 days

Onboarding flow:
1) Register (email/password or Google)
2) Center setup (center name, address , phone number)
3) Optional profile (logo, address, GSTIN)
4) Dashboard empty state (add first student CTA)
5) Add first student (name, parent phone, batch, fee plan)
6) First payment guided flow and WhatsApp receipt preview

### Phase 2) Dashboard and Analytics
Primary control center: collection status, overdue visibility, and quick actions.

KPI cards (always visible):
- Total collection today
- This month revenue
- Total overdue amount
- Overdue students count
- Active students
- New admissions this month
- Attendance today percentage
- Upcoming renewals (7 days)

Charts and widgets:
- Monthly revenue bar chart (last 12 months) by payment mode
- Collection vs due line chart (daily totals, overdue gap)
- Student growth line (enrollment trend)
- Batch strength donut (capacity utilization)
- Payment mode pie (cash/UPI/cheque)
- Top defaulters widget (top 10)
- Today collection activity feed
- Upcoming due dates timeline (14-day strip)

Quick action bar:
- Record payment
- Add student
- Send bulk reminders
- Download monthly report
- Mark attendance (today)
- View overdue list

### Phase 3) Student Management
Student profile fields:
- Personal: full name, DOB, gender, photo, student phone, parent name, parent phone, WhatsApp, email, address
- Academic: class/standard, school/college, Aadhaar (masked), enrollment date, admission number
- Batch/subject (multi-batch), status (active/inactive/alumni), notes, discount/waiver flag

Student actions:
- Enroll in batch (fee assignment)
- Record payment from profile
- View fee history with receipts
- View dues breakdown
- Send WhatsApp message to parent
- Upload document (Aadhaar, birth certificate, photo ID)
- Apply discount/waiver with reason
- Deactivate/graduate (soft delete, preserve history)
- Merge duplicate students
- Print ID card PDF
- Bulk import via CSV
- Add internal note

Student list features:
- Global search by name, phone, parent phone, admission number
- Filter by batch, status, overdue flag, enrollment month
- Sort by name, dues, last payment date, overdue-first view
- Bulk select (WhatsApp, export, status change)
- Row color codes: red > 30 days overdue, orange due this week, green paid up

### Phase 4) Fee Management Core
Fee plan types:
- Monthly fixed
- Quarterly (pro-rated mid-quarter)
- Half-yearly (pro-rated mid-cycle)
- Annual or one-time
- Custom installment (any amount on any date)
- Per-class/session (linked to attendance)

Fee plan configuration:
- Base amount
- Late fine per day and grace period
- GST rate: 0, 5, 12, 18 percent
- Toggle auto-generation of monthly dues
- Discount categories (sibling, merit, staff-child)
- Plan name, description, applicable batches

Payment recording (7-step flow):
1) Search student (instant autocomplete)
2) Select fee period(s) from pending dues
3) Enter amount (partial payment supported)
4) Select payment mode (cash, UPI, cheque, bank transfer, card, scholarship)
5) Enter reference (UTR/cheque/txn ID required for non-cash)
6) Add discount/waiver (reason required)
7) Confirm and generate receipt (WhatsApp receipt sent)

Receipt design:
- Center logo, name, address, GSTIN
- Auto receipt number (format like FS-2024-0001)
- Student name, admission number, batch
- Fee period description
- Amount paid, mode, reference number
- Outstanding balance after payment
- Optional digital signature
- QR code for online receipt verification
- Printable A5 and WhatsApp A6 formats
- DUPLICATE watermark on reprints

Dues engine:
- Daily CRON via Supabase Edge Function at midnight IST
- Recompute pending dues, pro-rate enrollment, apply discounts and late fines
- Track partial payments and mid-cycle plan changes
- Flag newly overdue students and queue reminders

### Phase 5) Payment Integration
Supported modes:
- Cash
- UPI (manual UTR entry)
- Razorpay payment link
- Razorpay UPI QR (static per center, dynamic per invoice)
- Razorpay subscription auto-debit
- Cheque
- Bank transfer/NEFT
- Scholarship/waiver (zero amount with reason)

Razorpay online payment flow:
- Admin generates payment link from due record
- Link sent via WhatsApp/SMS/email
- Parent pays via Razorpay checkout
- Webhook to Vercel Edge Function verifies signature
- Payment recorded in Supabase
- PDF receipt sent via WhatsApp
- Dashboard KPIs update via Realtime

Cheque lifecycle:
- Received -> Deposited -> Cleared/Bounced
- Bounced: auto-reverse payment, restore dues, add bounce charge, alert admin
- Clearance reminder at 3 days if still Deposited

Reconciliation report:
- Daily and monthly totals by mode
- Razorpay settlement vs manual entries
- Pending cheque clearance
- Discrepancy flags in red
- Exportable as Excel

### Phase 6) Notifications and Communication
Triggers and channels:
- Fee receipt (immediate): WhatsApp + Email
- Due reminder 3 days before: WhatsApp
- Due reminder on due date: WhatsApp + SMS
- Overdue alert 7 days: WhatsApp
- Overdue alert 15 and 30 days: WhatsApp + SMS
- Payment link (manual): WhatsApp
- Admission confirmation: WhatsApp + Email
- Batch schedule change: WhatsApp
- Holiday/closure broadcast: WhatsApp
- Fee plan change: WhatsApp
- Attendance absent alert: WhatsApp to parent
- Exam/test reminder (manual): WhatsApp
- Center-level broadcast: WhatsApp + SMS + in-app
- Subscription renewal reminder: Email + in-app

WhatsApp template management:
- Use pre-approved Meta HSM templates
- Variables: {{student_name}}, {{amount}}, {{due_date}}, {{center_name}}, {{receipt_no}}
- Admin can customize within template constraints
- Languages: English, Hindi, Bengali, Assamese, Tamil, Telugu
- Opt-out respected automatically
- Delivery status tracked: sent, delivered, read, failed
- Failed WhatsApp falls back to SMS

### Phase 7) Reports and Exports (14 Reports)
- Daily Collection Report (PDF/Excel/CSV)
- Monthly Revenue Report (PDF/Excel)
- Overdue/Due Report (PDF/WhatsApp)
- Fee Plan Report (PDF/Excel)
- Student Ledger (PDF/WhatsApp)
- P and L Statement (PDF/Excel)
- Expense Report (PDF/Excel)
- Attendance Report (PDF/Excel)
- Defaulter List (PDF/WhatsApp)
- Collection Efficiency (PDF)
- New Admissions Report (PDF)
- Alumni/Dropout Report (PDF)
- GST Summary (PDF/Excel)
- Payment Mode Analysis (PDF)

Export formats:
- PDF (branded, print-ready)
- Excel (calculated columns preserved)
- CSV (raw data)
- WhatsApp (shareable PDF link)

### Phase 8) Attendance Module
- Batch-wise daily attendance with Present/Absent/Late
- Bulk present default (then mark absentees)
- Backdating up to 7 days with reason and audit
- Absent parent alert (configurable)
- Attendance percentage on student profile with 75 percent alert
- Monthly attendance register PDF (A4 landscape)
- Holiday management (exclude from attendance)
- Per-session fee billing link
- Leave request (v2): parent portal submission, admin approval

### Phase 9) Batch and Schedule Management
Batch configuration:
- Batch name, subject/course name
- Teacher name (free text)
- Room/location (optional)
- Capacity with 80 percent and 100 percent alerts
- Schedule (days + time slots, multiple slots per day)
- Fee amount linked to fee plan
- Start and end dates
- Status: active, completed, upcoming

Batch operations:
- Transfer students between batches with or without fee plan change
- Clone batch for new session
- Capacity alerts and enrollment block at 100 percent
- Batch-wise WhatsApp broadcast
- Weekly timetable grid with clash detection
- Printable timetable PDF
- Archive completed batch (students to alumni or transfer)

### Phase 10) Expense Tracker and P and L
Expense categories:
- Rent
- Salaries and freelance fees
- Electricity and utilities
- Internet and phone
- Stationery and printing
- Marketing and advertising
- Teaching material
- Equipment purchase
- Cleaning and maintenance
- Software and subscriptions
- Transport
- Miscellaneous

Expense entry fields:
- Date, category, amount
- Vendor/payee name
- Payment mode (cash, UPI, bank transfer)
- Reference number (digital payments)
- Receipt photo upload
- Notes
- Recurring flag for monthly expenses

P and L statement:
- Revenue = fee payments received
- Expenses from expense entries
- Net profit = revenue - expenses
- Monthly bar chart + detailed table
- Accrual and cash basis views
- Annual view
- Exportable PDF for CA/accountant

### Phase 11) Parent Portal (Flutter App)
Package: com.feesync.lite
The parent app ships alongside the web app (not a future milestone).
The web admin is a responsive PWA, installable on Android via Add to Home Screen.

Parent app screens:
- Login (phone OTP)
- Home (fee status, next due date)
- Fee history (receipt view/download)
- Current dues with Pay Now
- Attendance with calendar
- Timetable
- Notifications feed
- Contact center (phone/WhatsApp/email)
- Multiple children switch
- Dark mode
- Offline support (cached data)

Flutter technical requirements:
- Flutter 3.x with null safety
- Supabase Flutter SDK
- State: Riverpod
- Local cache: Hive
- Payments: Razorpay Flutter plugin
- Push: firebase_messaging
- Local notifications: flutter_local_notifications
- Receipt viewer: PDF + printing packages
- Android: min SDK 21, target SDK 34
- Security: ProGuard/R8 enabled
- Distribution: signed APK + App Bundle

### Phase 12) AI-Powered Features (9)
- Smart overdue predictor
- Natural language fee query
- AI receipt OCR
- Auto-categorize expenses from receipt photo
- WhatsApp tone optimizer
- Enrollment growth forecast
- Payment anomaly detection
- Smart daily summary report
- Student churn risk score

### Phase 13) Settings and Configuration
Settings sections:
- Center profile: name, logo, tagline, address, contact, GSTIN, PAN, session dates, UPI ID
- Fee settings: receipt format, default due day, late fine, GST rate, online payments, discount categories
- Notifications: per-type toggle, provider selection, reminder timing, absent alert timing
- Integrations: Razorpay keys, WhatsApp credentials, Google Calendar sync, webhook URL (v2)
- Appearance: brand color, dark/light default, receipt logo layout, dashboard layout preference
- Security: TOTP 2FA, session timeout, data export, delete center account

### Phase 14) Subscription and Billing
Pricing tiers:
- Free: max 50 active students
- Starter: max 200 active students, INR 199/month
- Growth: unlimited students, INR 499/month

Plan features and limits:
- All 6 fee plan types: Free/Starter/Growth
- WhatsApp receipts: Free 200/month, Starter unlimited, Growth unlimited
- WhatsApp auto-reminders: Free 50/month, Starter unlimited, Growth unlimited
- SMS fallback: Starter 100/month, Growth 500/month
- Razorpay online payments: Starter/Growth
- Razorpay auto-debit: Growth only
- Reports: Free 5 basic, Starter all 14, Growth all 14 + scheduled email
- AI features: Free none, Starter 3, Growth all 9
- Flutter parent app: all tiers
- Expense tracker and P and L: Free basic, Starter full, Growth full
- Attendance module: all tiers
- CSV export: Starter/Growth
- WhatsApp support: Growth only

Paywall and business rules:
- Plan limits enforced at API level via Supabase RPC
- Student limit reached: friendly upgrade card on dashboard
- Expired subscription: read-only 7 days, then dashboard-only
- Annual plan: 2 months free, shown as INR savings
- New signups: 30 days full Growth features, no card required
- Referral program: INR 100 off first month for referrer and new signup

### Phase 15) Security and Compliance
- RLS on all tables (owner_id scoped)
- HTTPS/TLS 1.3 enforced
- Supabase Auth JWT sessions, revoke on deletion
- Input sanitization and parameterized queries
- File upload validation (JPEG/PDF only), private bucket
- TOTP 2FA mandatory prompt
- Rate limiting on auth endpoints
- PII masking (Aadhaar hashed, display masked)
- Data residency: ap-south-1 (Mumbai)
- Soft deletes with deleted_at
- DPDP Act 2023 compliance (consent, data export, erasure within 30 days)

###  16) Non-Functional Requirements
- Web LCP < 1.5s on 4G
- API p95 < 300ms
- Mobile cold start < 2s
- Flutter offline: full read + partial write (sync queue)
- Web offline: full read + draft payment (Service Worker + IndexedDB)
- Uptime 99.9 percent
- PDF receipt generation < 3s
- WhatsApp delivery < 10s from payment record
- Database scale 1M+ rows per table
- Mobile screen support 360px to 480px
- File upload limit 10 MB
- Daily backups with PITR
- Browser support: Chrome 90+, Firefox 88+, Safari 14+
- Accessibility: WCAG 2.1 AA, 4.5:1 contrast
- Internationalization: English now, Hindi in v2, Bengali/Assamese in v3

## Success Metrics and KPIs

Product health metrics:
- Daily active operators: 70 percent of paid users (north star)
- Payments recorded per day: >= 8 per paid operator
- WhatsApp receipt delivery rate: > 95 percent within 30 seconds
- Overdue detection time: within 24 hours of due date
- PDF receipt generation time: < 3s p95
- Parent app DAU/MAU: > 40 percent
- AI feature adoption: > 30 percent of Growth users use smart summary weekly
- Onboarding completion: > 75 percent add first student and first payment
- Support ticket rate: < 2 per 100 active users per month

Business metrics:
- MRR growth: 20 percent month-over-month for first 12 months
- Free to paid conversion: > 20 percent within 30 days
- Monthly paid churn: < 4 percent
- ARPU: INR 350 per month by month 6
- NPS: > 50 by 6 months post-launch
- CAC: < INR 500 per paid operator (organic referral + Play Store SEO)
- LTV:CAC: > 7x by end of year 1
- Referral rate: > 25 percent of new signups

Full power. Single admin. Zero compromise.