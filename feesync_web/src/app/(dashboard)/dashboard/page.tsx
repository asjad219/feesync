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
          <p className="text-[11px] uppercase tracking-[0.4em] text-[#c3c6d7]">Administrator</p>
          <h1 className="mt-3 text-3xl font-bold text-[#e3e0f4]">Welcome back</h1>
          <p className="mt-2 text-sm text-[#c3c6d7]">
            Here&apos;s the latest snapshot of collections, reminders, and growth.
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-3">
          <div className="hidden items-center gap-2 rounded-full border border-white/5 bg-[#1a1a28] px-4 py-2 text-xs text-[#8d90a0] md:flex">
            <Search className="h-4 w-4 text-[#c3c6d7]" />
            Search students, fees, or payments
          </div>
          <Link href="/payments" className="btn-primary-gradient text-sm">
            Record payment
          </Link>
        </div>
      </section>

      <section className="relative mb-10 grid gap-4 lg:grid-cols-12">
        <div className="card-elevated relative overflow-hidden border border-white/5 lg:col-span-5">
          <div className="absolute -right-12 -top-16 h-40 w-40 rounded-full bg-[#2563eb]/20 blur-2xl" />
          <div className="relative flex items-start justify-between">
            <div>
              <p className="text-xs uppercase tracking-[0.25em] text-[#c3c6d7]">Total Collected</p>
              <p className="mt-3 text-3xl font-bold text-[#e3e0f4]">
                {currencyFormatter.format(totalCollection.total)}
              </p>
              <p className="mt-2 text-sm text-[#c3c6d7]">
                {totalCollection.count} payments received this term
              </p>
            </div>
            <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-[#2563eb]/20 text-[#b4c5ff]">
              <DollarSign className="h-6 w-6" />
            </div>
          </div>
          <div className="mt-8 flex items-center gap-3 text-sm text-[#c3c6d7]">
            <span className="rounded-full bg-[#2563eb]/15 px-3 py-1 text-xs text-[#b4c5ff]">
              +12.5% vs last month
            </span>
            <span className="flex items-center gap-1 text-xs">
              Revenue trend
              <ArrowUpRight className="h-3 w-3 text-[#b4c5ff]" />
            </span>
          </div>
        </div>

        <div className="card-stitch border border-white/5 lg:col-span-3">
          <div className="flex items-center justify-between">
            <p className="text-xs uppercase tracking-[0.25em] text-[#c3c6d7]">Active Students</p>
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[#571bc1]/20 text-[#d0bcff]">
              <Users className="h-5 w-5" />
            </div>
          </div>
          <p className="mt-5 text-3xl font-bold text-[#e3e0f4]">{students.length}</p>
          <p className="mt-2 text-sm text-[#c3c6d7]">Across all classes</p>
        </div>

        <div className="card-stitch border border-white/5 lg:col-span-2">
          <div className="flex items-center justify-between">
            <p className="text-xs uppercase tracking-[0.25em] text-[#c3c6d7]">Pending Balance</p>
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[#ffb4ab]/15 text-[#ffb4ab]">
              <TrendingUp className="h-5 w-5" />
            </div>
          </div>
          <p className="mt-5 text-2xl font-bold text-[#e3e0f4]">
            {currencyFormatter.format(pendingBalance)}
          </p>
          <p className="mt-2 text-xs text-[#c3c6d7]">
            From {pendingReminders.length} students
          </p>
        </div>

        <div className="card-stitch border border-white/5 lg:col-span-2">
          <div className="flex items-center justify-between">
            <p className="text-xs uppercase tracking-[0.25em] text-[#c3c6d7]">Collection Rate</p>
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[#b4c5ff]/15 text-[#b4c5ff]">
              <TrendingUp className="h-5 w-5" />
            </div>
          </div>
          <p className="mt-5 text-2xl font-bold text-[#e3e0f4]">{collectionRate}%</p>
          <p className="mt-2 text-xs text-[#c3c6d7]">Of total students</p>
        </div>
      </section>

      <section className="relative mb-10">
        <div className="card-elevated border border-white/5">
          <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
            <div>
              <h2 className="text-lg font-semibold text-[#e3e0f4]">Monthly Revenue Analytics</h2>
              <p className="text-xs text-[#c3c6d7]">Performance comparison over the last 6 months</p>
            </div>
            <div className="flex items-center gap-2 text-xs">
              <span className="rounded-full bg-[#1a1a28] px-4 py-2 text-[#c3c6d7]">Weekly</span>
              <span className="rounded-full bg-[#2563eb] px-4 py-2 text-[#eeefff]">Monthly</span>
            </div>
          </div>

          <div className="mt-8">
            <div className="relative h-56 w-full rounded-2xl border border-white/5 bg-[#1a1a28]/80 p-6">
              <div className="absolute inset-6 flex items-end justify-between">
                {revenueBars.map((bar) => (
                  <div key={bar.label} className="group relative flex h-full w-10 flex-col items-center justify-end">
                    <div className="absolute -top-7 hidden rounded-md bg-[#1e1e2c] px-2 py-1 text-[10px] text-[#c3c6d7] group-hover:block">
                      {bar.amount}
                    </div>
                    <div
                      className="w-10 rounded-xl bg-[#292937]"
                      style={{ height: `${bar.value}%` }}
                    />
                  </div>
                ))}
              </div>
              <div className="absolute inset-0 flex flex-col justify-between px-6 py-6 opacity-40">
                <span className="border-t border-[#343342]" />
                <span className="border-t border-[#343342]" />
                <span className="border-t border-[#343342]" />
                <span className="border-t border-[#343342]" />
              </div>
            </div>
            <div className="mt-4 flex justify-between px-6 text-[10px] uppercase tracking-[0.3em] text-[#8d90a0]">
              {revenueBars.map((bar) => (
                <span key={`${bar.label}-label`}>{bar.label}</span>
              ))}
            </div>
          </div>
        </div>
      </section>

      <section className="relative grid gap-4 xl:grid-cols-2">
        <div className="card-stitch border border-white/5">
          <div className="flex items-center justify-between">
            <h3 className="text-lg font-semibold text-[#e3e0f4]">Recent Transactions</h3>
            <Link href="/payments" className="text-xs text-[#b4c5ff] hover:text-[#dbe1ff]">
              View all
            </Link>
          </div>
          <div className="mt-6 space-y-4">
            {recentPayments.length === 0 ? (
              <p className="text-sm text-[#c3c6d7]">No payments recorded yet.</p>
            ) : (
              recentPayments.map((payment) => (
                <div
                  key={payment.id}
                  className="flex items-center justify-between rounded-xl border border-white/5 bg-[#1a1a28] px-4 py-3"
                >
                  <div>
                    <p className="text-sm font-semibold text-[#e3e0f4]">
                      {payment.students?.first_name} {payment.students?.last_name}
                    </p>
                    <p className="text-xs text-[#c3c6d7]">
                      {payment.students?.class} • {payment.payment_method}
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="text-sm font-semibold text-[#e3e0f4]">
                      {currencyFormatter.format(Number(payment.amount))}
                    </p>
                    <p className="text-[10px] text-[#8d90a0]">
                      {new Date(payment.payment_date).toLocaleDateString()}
                    </p>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        <div className="card-stitch border border-white/5">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Bell className="h-4 w-4 text-[#b4c5ff]" />
              <h3 className="text-lg font-semibold text-[#e3e0f4]">Pending Reminders</h3>
            </div>
            <span className="rounded-full bg-[#571bc1]/20 px-3 py-1 text-[11px] text-[#d0bcff]">
              {pendingReminders.length} open
            </span>
          </div>
          <div className="mt-6 space-y-4">
            {pendingReminders.length === 0 ? (
              <p className="text-sm text-[#c3c6d7]">No pending reminders.</p>
            ) : (
              pendingReminders.slice(0, 5).map((reminder) => (
                <div
                  key={reminder.id}
                  className="flex items-center justify-between rounded-xl border border-white/5 bg-[#1a1a28] px-4 py-3"
                >
                  <div>
                    <p className="text-sm font-semibold text-[#e3e0f4]">
                      {reminder.student_first_name} {reminder.student_last_name}
                    </p>
                    <p className="text-xs text-[#c3c6d7]">
                      {reminder.class} • {reminder.type.replace('_', ' ')}
                    </p>
                  </div>
                  <span className="status-warning">
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
