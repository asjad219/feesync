'use client'

import Link from 'next/link'
import { useQuery } from '@tanstack/react-query'
import {
  Bell,
  DollarSign,
  TrendingUp,
  Users,
  Search,
  ArrowUpRight,
} from 'lucide-react'
import { getStudents } from '@/lib/supabase/repositories/students'
import { getRecentPayments, getTotalCollection } from '@/lib/supabase/repositories/payments'
import { getPendingReminders } from '@/lib/supabase/repositories/notifications'
import type { Student, Payment, PendingReminder } from '@/lib/supabase/types'

export const dynamic = 'force-dynamic'

export default function DashboardPage() {
  const { data: studentsData } = useQuery({
    queryKey: ['students', {}],
    queryFn: async () => getStudents({}),
  })

  const { data: paymentsData } = useQuery({
    queryKey: ['recentPayments', 5],
    queryFn: async () => getRecentPayments(5),
  })

  const { data: collectionData } = useQuery({
    queryKey: ['totalCollection', {}],
    queryFn: async () => getTotalCollection({}),
  })

  const { data: remindersData } = useQuery({
    queryKey: ['pendingReminders', {}],
    queryFn: async () => getPendingReminders(),
  })

  const students: Student[] = studentsData?.data || []
  const recentPayments: Payment[] = paymentsData?.data || []
  const totalCollection = collectionData?.data || { total: 0, count: 0 }
  const pendingReminders: PendingReminder[] = remindersData?.data || []

  const pendingBalance = pendingReminders.reduce((sum, r) => sum + r.balance, 0)
  const collectionRate = students.length > 0
    ? Math.round(((students.length - pendingReminders.length) / students.length) * 100)
    : 100

  const currencyFormatter = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
  })

  const revenueBars = [
    { label: 'May', value: 40, amount: '$22k' },
    { label: 'Jun', value: 55, amount: '$28k' },
    { label: 'Jul', value: 75, amount: '$42k' },
    { label: 'Aug', value: 60, amount: '$31k' },
    { label: 'Sep', value: 85, amount: '$48k' },
    { label: 'Oct', value: 65, amount: '$34k' },
  ]

  return (
    <div className="relative min-h-full px-6 pb-12 pt-8">
      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_top,_rgba(37,99,235,0.16),_transparent_60%)]" />

      <section className="relative mb-8 flex flex-col gap-5 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <p className="text-[11px] uppercase tracking-[0.4em] text-primary/80 font-bold">Administrator</p>
          <h1 className="mt-3 text-3xl font-bold text-white tracking-tight">Welcome back</h1>
          <p className="mt-2 text-sm text-muted-foreground">
            Here&apos;s the latest snapshot of collections, reminders, and growth.
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-3">
          <div className="hidden items-center gap-2 rounded-full border border-white/5 bg-surface-low px-4 py-2 text-xs text-muted md:flex">
            <Search className="h-4 w-4 text-muted" />
            Search students, fees, or payments
          </div>
          <Link href="/payments" className="btn-primary-gradient text-sm">
            Record payment
          </Link>
        </div>
      </section>

      <section className="relative mb-10 grid gap-4 lg:grid-cols-12">
        <div className="card-elevated relative overflow-hidden lg:col-span-5">
          <div className="absolute -right-12 -top-16 h-40 w-40 rounded-full bg-primary/20 blur-3xl" />
          <div className="relative flex items-start justify-between">
            <div>
              <p className="text-xs uppercase tracking-[0.25em] text-primary/80 font-bold">Total Collected</p>
              <p className="mt-3 text-4xl font-bold text-white">
                {currencyFormatter.format(totalCollection.total)}
              </p>
              <p className="mt-2 text-sm text-muted">
                {totalCollection.count} payments received this term
              </p>
            </div>
            <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-primary/20 text-primary">
              <DollarSign className="h-6 w-6" />
            </div>
          </div>
          <div className="mt-8 flex items-center gap-3 text-sm text-muted">
            <span className="rounded-full bg-primary/15 px-3 py-1 text-xs text-primary font-semibold">
              +12.5% vs last month
            </span>
            <span className="flex items-center gap-1 text-xs font-medium">
              Revenue trend
              <ArrowUpRight className="h-3 w-3 text-primary" />
            </span>
          </div>
        </div>

        <div className="card-stitch lg:col-span-3">
          <div className="flex items-center justify-between">
            <p className="text-xs uppercase tracking-[0.25em] text-muted-foreground font-bold">Active Students</p>
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-secondary/20 text-secondary">
              <Users className="h-5 w-5" />
            </div>
          </div>
          <p className="mt-5 text-3xl font-bold text-white">{students.length}</p>
          <p className="mt-2 text-sm text-muted">Across all classes</p>
        </div>

        <div className="card-stitch lg:col-span-2">
          <div className="flex items-center justify-between">
            <p className="text-xs uppercase tracking-[0.25em] text-muted-foreground font-bold">Pending</p>
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-destructive/15 text-destructive">
              <TrendingUp className="h-5 w-5" />
            </div>
          </div>
          <p className="mt-5 text-2xl font-bold text-white">
            {currencyFormatter.format(pendingBalance)}
          </p>
          <p className="mt-2 text-xs text-muted">
            From {pendingReminders.length} students
          </p>
        </div>

        <div className="card-stitch lg:col-span-2">
          <div className="flex items-center justify-between">
            <p className="text-xs uppercase tracking-[0.25em] text-muted-foreground font-bold">Rate</p>
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-emerald-500/20 text-emerald-400">
              <TrendingUp className="h-5 w-5" />
            </div>
          </div>
          <p className="mt-5 text-2xl font-bold text-white">{collectionRate}%</p>
          <p className="mt-2 text-xs text-muted">Collection Rate</p>
        </div>
      </section>

      <section className="relative mb-10">
        <div className="card-elevated border border-white/5">
          <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
            <div>
              <h2 className="text-lg font-bold text-white">Monthly Revenue Analytics</h2>
              <p className="text-xs text-muted">Performance comparison over the last 6 months</p>
            </div>
            <div className="flex items-center gap-2 text-xs">
              <span className="rounded-full bg-surface-low px-4 py-2 text-muted font-medium cursor-pointer hover:bg-surface-high transition-colors">Weekly</span>
              <span className="rounded-full bg-primary px-4 py-2 text-primary-foreground font-bold shadow-lg shadow-primary/20">Monthly</span>
            </div>
          </div>

          <div className="mt-8">
            <div className="relative h-56 w-full rounded-2xl border border-white/[0.03] bg-surface-lowest p-6">
              <div className="absolute inset-6 flex items-end justify-between">
                {revenueBars.map((bar) => (
                  <div key={bar.label} className="group relative flex h-full w-10 flex-col items-center justify-end">
                    <div className="absolute -top-7 hidden rounded-md bg-surface-high border border-white/10 px-2 py-1 text-[10px] text-white font-bold group-hover:block z-10">
                      {bar.amount}
                    </div>
                    <div
                      className="w-10 rounded-t-xl bg-gradient-to-t from-primary/40 to-primary transition-all duration-300 group-hover:brightness-125"
                      style={{ height: `${bar.value}%` }}
                    />
                  </div>
                ))}
              </div>
              <div className="absolute inset-0 flex flex-col justify-between px-6 py-6 opacity-20 pointer-events-none">
                <span className="border-t border-muted-foreground/30" />
                <span className="border-t border-muted-foreground/30" />
                <span className="border-t border-muted-foreground/30" />
                <span className="border-t border-muted-foreground/30" />
              </div>
            </div>
            <div className="mt-4 flex justify-between px-6 text-[10px] uppercase tracking-[0.2em] text-muted font-bold">
              {revenueBars.map((bar) => (
                <span key={`${bar.label}-label`}>{bar.label}</span>
              ))}
            </div>
          </div>
        </div>
      </section>

      <section className="relative grid gap-4 xl:grid-cols-2">
        <div className="card-stitch">
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-lg font-bold text-white">Recent Transactions</h3>
            <Link href="/payments" className="text-xs text-primary font-bold hover:text-primary/80 transition-colors">
              View all
            </Link>
          </div>
          <div className="space-y-3">
            {recentPayments.length === 0 ? (
              <p className="text-sm text-muted">No payments recorded yet.</p>
            ) : (
              recentPayments.map((payment) => (
                <div
                  key={payment.id}
                  className="flex items-center justify-between rounded-xl border border-white/[0.03] bg-surface-low px-4 py-3 hover:bg-surface-high transition-colors"
                >
                  <div>
                    <p className="text-sm font-bold text-white">
                      {payment.students?.first_name} {payment.students?.last_name}
                    </p>
                    <p className="text-xs text-muted">
                      {payment.students?.class} • <span className="capitalize">{payment.payment_method?.replace('_', ' ')}</span>
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="text-sm font-bold text-emerald-400">
                      {currencyFormatter.format(Number(payment.amount))}
                    </p>
                    <p className="text-[10px] text-muted-foreground font-medium">
                      {new Date(payment.payment_date).toLocaleDateString()}
                    </p>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        <div className="card-stitch">
          <div className="flex items-center justify-between mb-6">
            <div className="flex items-center gap-2">
              <Bell className="h-4 w-4 text-primary" />
              <h3 className="text-lg font-bold text-white">Pending Reminders</h3>
            </div>
            <span className="rounded-full bg-secondary/20 px-3 py-1 text-[11px] text-secondary font-bold">
              {pendingReminders.length} open
            </span>
          </div>
          <div className="space-y-3">
            {pendingReminders.length === 0 ? (
              <p className="text-sm text-muted">No pending reminders.</p>
            ) : (
              pendingReminders.slice(0, 5).map((reminder) => (
                <div
                  key={reminder.id}
                  className="flex items-center justify-between rounded-xl border border-white/[0.03] bg-surface-low px-4 py-3 hover:bg-surface-high transition-colors"
                >
                  <div>
                    <p className="text-sm font-bold text-white">
                      {reminder.student_first_name} {reminder.student_last_name}
                    </p>
                    <p className="text-xs text-muted">
                      {reminder.class} • <span className="capitalize">{reminder.type.replace('_', ' ')}</span>
                    </p>
                  </div>
                  <span className="status-warning bg-amber-500/10 text-amber-400 px-2 py-1 rounded-lg text-xs font-bold border border-amber-500/20">
                    {currencyFormatter.format(reminder.balance)}
                  </span>
                </div>
              ))
            )}
          </div>
        </div>
      </section>
    </div>
  )
}
