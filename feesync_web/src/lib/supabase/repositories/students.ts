'use client'

import { supabase } from '@/lib/supabase/client'
import type { Student, StudentBalance, ApiResponse } from '../types'

export async function getStudents(filters?: {
  search?: string
  class?: string
  section?: string
}): Promise<ApiResponse<Student[]>> {
  try {
    let query = supabase
      .from('students')
      .select('*')
      .order('last_name', { ascending: true })

    if (filters?.class) {
      query = query.eq('class', filters.class)
    }
    if (filters?.section) {
      query = query.eq('section', filters.section)
    }
    if (filters?.search) {
      query = query.or(
        `first_name.ilike.%${filters.search}%,last_name.ilike.%${filters.search}%,admission_number.ilike.%${filters.search}%`
      )
    }

    const { data, error } = await query

    if (error) throw error
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function getStudentById(id: string): Promise<ApiResponse<Student>> {
  try {
    const { data, error } = await supabase
      .from('students')
      .select('*')
      .eq('id', id)
      .single()

    if (error) throw error
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function getStudentBalance(id: string): Promise<ApiResponse<StudentBalance>> {
  try {
    const { data, error } = await supabase
      .from('student_balances')
      .select('*')
      .eq('id', id)
      .single()

    if (error) throw error
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function getStudentBalances(): Promise<ApiResponse<StudentBalance[]>> {
  try {
    const { data, error } = await supabase
      .from('student_balances')
      .select('*')
      .order('last_name', { ascending: true })

    if (error) throw error
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function createStudent(student: Omit<Student, 'id' | 'created_at' | 'updated_at' | 'account_id'>): Promise<ApiResponse<Student>> {
  try {
    const { data, error } = await supabase
      .from('students')
      .insert(student)
      .select()
      .single()

    if (error) throw error
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function updateStudent(id: string, updates: Partial<Student>): Promise<ApiResponse<Student>> {
  try {
    const { data, error } = await supabase
      .from('students')
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

export async function deleteStudent(id: string): Promise<ApiResponse<null>> {
  try {
    const { error } = await supabase
      .from('students')
      .delete()
      .eq('id', id)

    if (error) throw error
    return { data: null, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}
