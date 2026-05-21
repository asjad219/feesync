'use client'

import { supabase } from '@/lib/supabase/client'
import type { Payment, PaymentRecord, MonthlyCollection, ApiResponse } from '../types'

export async function getPayments(filters?: {
  student_id?: string
  start_date?: string
  end_date?: string
  payment_method?: string
}): Promise<ApiResponse<Payment[]>> {
  try {
    let query = supabase
      .from('payments')
      .select('*, students(first_name, last_name, class, admission_number)')
      .order('payment_date', { ascending: false })

    if (filters?.student_id) {
      query = query.eq('student_id', filters.student_id)
    }
    if (filters?.start_date) {
      query = query.gte('payment_date', filters.start_date)
    }
    if (filters?.end_date) {
      query = query.lte('payment_date', filters.end_date)
    }
    if (filters?.payment_method) {
      query = query.eq('payment_method', filters.payment_method)
    }

    const { data, error } = await query

    if (error) throw error
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function getPaymentById(id: string): Promise<ApiResponse<Payment>> {
  try {
    const { data, error } = await supabase
      .from('payments')
      .select('*, students(first_name, last_name, class, admission_number), payment_records(*, fee_structures(name, amount))')
      .eq('id', id)
      .single()

    if (error) throw error
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function createPayment(
  payment: Omit<Payment, 'id' | 'created_at' | 'updated_at' | 'account_id' | 'receipt_number'>,
  feeAllocations: { fee_structure_id: string; due_id?: string; amount: number }[]
): Promise<ApiResponse<Payment>> {
  try {
    const receiptNumber = `RCP-${Date.now()}`

    const { data: paymentData, error: paymentError } = await supabase
      .from('payments')
      .insert({ ...payment, receipt_number: receiptNumber })
      .select()
      .single()

    if (paymentError) throw paymentError

    if (feeAllocations.length > 0) {
      const { error: recordsError } = await supabase
        .from('payment_records')
        .insert(feeAllocations.map(fa => ({
          payment_id: paymentData.id,
          fee_structure_id: fa.fee_structure_id,
          due_id: fa.due_id,
          amount: fa.amount,
        })))

      if (recordsError) throw recordsError
    }

    return { data: paymentData, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function updatePayment(id: string, updates: Partial<Payment>): Promise<ApiResponse<Payment>> {
  try {
    const { data, error } = await supabase
      .from('payments')
      .update(updates)
      .eq('id', id)
      .select()
      .single()

    if (error) throw error
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function deletePayment(id: string): Promise<ApiResponse<null>> {
  try {
    const { error } = await supabase
      .from('payments')
      .delete()
      .eq('id', id)

    if (error) throw error
    return { data: null, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function getMonthlyCollections(): Promise<ApiResponse<MonthlyCollection[]>> {
  try {
    const { data, error } = await supabase
      .from('monthly_collections')
      .select('*')
      .order('month', { ascending: false })
      .limit(12)

    if (error) throw error
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function getRecentPayments(limit = 10): Promise<ApiResponse<Payment[]>> {
  try {
    const { data, error } = await supabase
      .from('payments')
      .select('*, students(first_name, last_name, class)')
      .eq('status', 'completed')
      .order('created_at', { ascending: false })
      .limit(limit)

    if (error) throw error
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function getTotalCollection(filters?: {
  start_date?: string
  end_date?: string
}): Promise<ApiResponse<{ total: number; count: number }>> {
  try {
    let query = supabase
      .from('payments')
      .select('amount')

    if (filters?.start_date) {
      query = query.gte('payment_date', filters.start_date)
    }
    if (filters?.end_date) {
      query = query.lte('payment_date', filters.end_date)
    }

    const { data, error } = await query.eq('status', 'completed')

    if (error) throw error

    const total = data?.reduce((sum: number, p: { amount: number }) => sum + Number(p.amount), 0) || 0

    return { data: { total, count: data?.length || 0 }, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}
