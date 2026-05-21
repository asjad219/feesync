'use client'

import { supabase } from '@/lib/supabase/client'
import type { Notification, NotificationSettings, PendingReminder, ApiResponse } from '../types'

export async function getNotifications(filters?: {
  student_id?: string
  status?: string
  type?: string
}): Promise<ApiResponse<Notification[]>> {
  try {
    let query = supabase
      .from('notifications')
      .select('*, students(first_name, last_name, class)')
      .order('created_at', { ascending: false })

    if (filters?.student_id) {
      query = query.eq('student_id', filters.student_id)
    }
    if (filters?.status) {
      query = query.eq('status', filters.status)
    }
    if (filters?.type) {
      query = query.eq('type', filters.type)
    }

    const { data, error } = await query

    if (error) throw error
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function createNotification(
  notification: Omit<Notification, 'id' | 'created_at' | 'status' | 'sent_at'>
): Promise<ApiResponse<Notification>> {
  try {
    const { data, error } = await supabase
      .from('notifications')
      .insert(notification)
      .select()
      .single()

    if (error) throw error
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function updateNotification(id: string, updates: Partial<Notification>): Promise<ApiResponse<Notification>> {
  try {
    const { data, error } = await supabase
      .from('notifications')
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

export async function deleteNotification(id: string): Promise<ApiResponse<null>> {
  try {
    const { error } = await supabase
      .from('notifications')
      .delete()
      .eq('id', id)

    if (error) throw error
    return { data: null, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function getNotificationSettings(): Promise<ApiResponse<NotificationSettings>> {
  try {
    const { data, error } = await supabase
      .from('notification_settings')
      .select('*')
      .single()

    if (error) throw error
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function updateNotificationSettings(
  id: string,
  updates: Partial<NotificationSettings>
): Promise<ApiResponse<NotificationSettings>> {
  try {
    const { data, error } = await supabase
      .from('notification_settings')
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

export async function getPendingReminders(): Promise<ApiResponse<PendingReminder[]>> {
  try {
    const { data, error } = await supabase
      .from('pending_reminders')
      .select('*')
      .order('scheduled_for', { ascending: true })

    if (error) throw error
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}
