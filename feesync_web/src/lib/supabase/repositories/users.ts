'use client'

import { supabase } from '@/lib/supabase/client'
import type { User, ApiResponse } from '../types'

export async function getCurrentUser(): Promise<ApiResponse<User>> {
  try {
    const { data: { user: authUser }, error: authError } = await supabase.auth.getUser()

    if (authError) throw authError
    if (!authUser) throw new Error('No authenticated user')

    const { data, error } = await supabase
      .from('users')
      .select('*')
      .eq('id', authUser.id)
      .single()

    if (error) throw error
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function getAccountUsers(): Promise<ApiResponse<User[]>> {
  try {
    const { data, error } = await supabase
      .from('users')
      .select('*')
      .order('full_name', { ascending: true })

    if (error) throw error
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function getUserById(id: string): Promise<ApiResponse<User>> {
  try {
    const { data, error } = await supabase
      .from('users')
      .select('*')
      .eq('id', id)
      .single()

    if (error) throw error
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function updateUser(id: string, updates: Partial<User>): Promise<ApiResponse<User>> {
  try {
    const { data, error } = await supabase
      .from('users')
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

export async function createUser(user: Omit<User, 'id' | 'created_at' | 'updated_at'>): Promise<ApiResponse<User>> {
  try {
    const { data, error } = await supabase
      .from('users')
      .insert(user)
      .select()
      .single()

    if (error) throw error
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function deleteUser(id: string): Promise<ApiResponse<null>> {
  try {
    const { error } = await supabase
      .from('users')
      .delete()
      .eq('id', id)

    if (error) throw error
    return { data: null, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}
