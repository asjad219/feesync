export type UserRole = 'admin' | 'accountant' | 'parent' | 'student'
export type PaymentMethod = 'cash' | 'bank_transfer' | 'mobile_money' | 'card' | 'other'
export type Gender = 'male' | 'female' | 'other'
export type NotificationType = 'payment_reminder' | 'payment_confirmation' | 'welcome' | 'fee_update'
export type NotificationChannel = 'email' | 'sms' | 'both'
export type NotificationStatus = 'pending' | 'sent' | 'failed'
export type PaymentStatus = 'pending' | 'completed' | 'refunded' | 'cancelled'
export type FeePlanType = 'monthly' | 'quarterly' | 'half_yearly' | 'annual' | 'custom' | 'per_class'
export type DueStatus = 'pending' | 'partial' | 'paid' | 'overdue' | 'cancelled'

export interface Account {
  id: string
  name: string
  school_name?: string
  email: string
  phone?: string
  address?: string
  logo_url?: string
  created_at: string
  updated_at: string
}

export interface User {
  id: string
  account_id: string
  email: string
  full_name: string
  role: UserRole
  phone?: string
  avatar_url?: string
  created_at: string
  updated_at: string
}

export interface Student {
  id: string
  account_id: string
  admission_number: string
  first_name: string
  last_name: string
  class: string
  section?: string
  stream?: string
  gender?: Gender
  date_of_birth?: string
  parent_name?: string
  parent_phone?: string
  parent_email?: string
  address?: string
  created_at: string
  updated_at: string
}

export interface StudentBalance {
  id: string
  account_id: string
  admission_number: string
  first_name: string
  last_name: string
  class: string
  section?: string
  parent_name?: string
  parent_phone?: string
  parent_email?: string
  total_fee_amount: number
  total_paid_amount: number
  balance: number
}

export interface FeeCategory {
  id: string
  account_id: string
  name: string
  description?: string
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface FeeStructure {
  id: string
  account_id: string
  category_id: string
  name: string
  amount: number
  class: string
  due_date?: string
  description?: string
  is_active: boolean
  plan_type: FeePlanType
  late_fine: number
  grace_days: number
  gst_percent: number
  auto_generate_dues: boolean
  created_at: string
  updated_at: string
}

export interface FeeAssignment {
  id: string
  account_id: string
  student_id: string
  fee_structure_id: string
  start_date: string
  discount_amount: number
  waiver_reason?: string
  is_active: boolean
  created_at: string
  updated_at: string
  fee_structures?: FeeStructure
}

export interface Due {
  id: string
  account_id: string
  student_id: string
  fee_structure_id: string
  period_name: string
  due_date: string
  amount_assigned: number
  amount_paid: number
  amount_outstanding: number
  late_fine_applied: number
  status: DueStatus
  notes?: string
  created_at: string
  updated_at: string
  fee_structures?: FeeStructure
}

export interface Payment {
  id: string
  account_id: string
  student_id: string
  amount: number
  payment_method: PaymentMethod
  transaction_id?: string
  payment_date: string
  recorded_by?: string
  notes?: string
  receipt_number?: string
  status: PaymentStatus
  created_at: string
  updated_at: string
  students?: {
    first_name: string
    last_name: string
    class: string
    admission_number: string
  }
}

export interface PaymentRecord {
  id: string
  payment_id: string
  fee_structure_id: string
  due_id?: string
  amount: number
  created_at: string
}

export interface Notification {
  id: string
  account_id: string
  student_id?: string
  type: NotificationType
  channel: NotificationChannel
  subject?: string
  message: string
  scheduled_for?: string
  sent_at?: string
  status: NotificationStatus
  created_by?: string
  created_at: string
}

export interface NotificationSettings {
  id: string
  account_id: string
  auto_reminder_days: number
  reminder_frequency: number
  enabled_channels: NotificationChannel[]
  created_at: string
  updated_at: string
}

export interface MonthlyCollection {
  account_id: string
  month: string
  payment_count: number
  total_collected: number
}

export interface PendingReminder {
  id: string
  account_id: string
  student_id: string
  type: NotificationType
  message: string
  scheduled_for?: string
  status: NotificationStatus
  student_first_name: string
  student_last_name: string
  class: string
  parent_email?: string
  parent_phone?: string
  balance: number
}

// API Response type
export interface ApiResponse<T> {
  data: T | null
  error: Error | null
}

// Supabase Database type for TypeScript support
export interface Database {
  public: {
    Tables: {
      accounts: {
        Row: Account
        Insert: Omit<Account, 'id' | 'created_at' | 'updated_at'>
        Update: Partial<Omit<Account, 'id' | 'created_at' | 'updated_at'>>
      }
      users: {
        Row: User
        Insert: Omit<User, 'id' | 'created_at' | 'updated_at'>
        Update: Partial<Omit<User, 'id' | 'created_at' | 'updated_at'>>
      }
      students: {
        Row: Student
        Insert: Omit<Student, 'id' | 'created_at' | 'updated_at'>
        Update: Partial<Omit<Student, 'id' | 'created_at' | 'updated_at'>>
      }
      fee_categories: {
        Row: FeeCategory
        Insert: Omit<FeeCategory, 'id' | 'created_at' | 'updated_at'>
        Update: Partial<Omit<FeeCategory, 'id' | 'created_at' | 'updated_at'>>
      }
      fee_structures: {
        Row: FeeStructure
        Insert: Omit<FeeStructure, 'id' | 'created_at' | 'updated_at'>
        Update: Partial<Omit<FeeStructure, 'id' | 'created_at' | 'updated_at'>>
      }
      payments: {
        Row: Payment
        Insert: Omit<Payment, 'id' | 'created_at' | 'updated_at'>
        Update: Partial<Omit<Payment, 'id' | 'created_at' | 'updated_at'>>
      }
      payment_records: {
        Row: PaymentRecord
        Insert: Omit<PaymentRecord, 'id' | 'created_at'>
        Update: Partial<Omit<PaymentRecord, 'id' | 'created_at'>>
      }
      notifications: {
        Row: Notification
        Insert: Omit<Notification, 'id' | 'created_at'>
        Update: Partial<Omit<Notification, 'id' | 'created_at'>>
      }
      notification_settings: {
        Row: NotificationSettings
        Insert: Omit<NotificationSettings, 'id' | 'created_at' | 'updated_at'>
        Update: Partial<Omit<NotificationSettings, 'id' | 'created_at' | 'updated_at'>>
      }
    }
  }
}
