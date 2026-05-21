'use client'

import { supabase } from '@/lib/supabase/client'
import type { 
  FeeCategory, 
  FeeStructure, 
  FeeAssignment, 
  Due, 
  ApiResponse 
} from '../types'

// Fee Assignments
export async function getFeeAssignments(filters?: {
  student_id?: string
  fee_structure_id?: string
}): Promise<ApiResponse<FeeAssignment[]>> {
  try {
    let query = supabase
      .from('fee_assignments')
      .select('*, fee_structures(*)')
      .order('created_at', { ascending: false })

    if (filters?.student_id) {
      query = query.eq('student_id', filters.student_id)
    }
    if (filters?.fee_structure_id) {
      query = query.eq('fee_structure_id', filters.fee_structure_id)
    }

    const { data, error } = await query

    if (error) throw error
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function createFeeAssignment(assignment: Omit<FeeAssignment, 'id' | 'created_at' | 'updated_at' | 'account_id'>): Promise<ApiResponse<FeeAssignment>> {
  try {
    const { data, error } = await supabase
      .from('fee_assignments')
      .insert(assignment)
      .select()
      .single()

    if (error) throw error
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function updateFeeAssignment(id: string, updates: Partial<FeeAssignment>): Promise<ApiResponse<FeeAssignment>> {
  try {
    const { data, error } = await supabase
      .from('fee_assignments')
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

export async function deleteFeeAssignment(id: string): Promise<ApiResponse<null>> {
  try {
    const { error } = await supabase
      .from('fee_assignments')
      .delete()
      .eq('id', id)

    if (error) throw error
    return { data: null, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

// Dues
export async function getDues(filters?: {
  student_id?: string
  status?: string
  fee_structure_id?: string
}): Promise<ApiResponse<Due[]>> {
  try {
    let query = supabase
      .from('dues')
      .select('*, fee_structures(*)')
      .order('due_date', { ascending: true })

    if (filters?.student_id) {
      query = query.eq('student_id', filters.student_id)
    }
    if (filters?.status) {
      query = query.eq('status', filters.status)
    }
    if (filters?.fee_structure_id) {
      query = query.eq('fee_structure_id', filters.fee_structure_id)
    }

    const { data, error } = await query

    if (error) throw error
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function getDueById(id: string): Promise<ApiResponse<Due>> {
  try {
    const { data, error } = await supabase
      .from('dues')
      .select('*, fee_structures(*)')
      .eq('id', id)
      .single()

    if (error) throw error
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function getFeeCategories(): Promise<ApiResponse<FeeCategory[]>> {
  try {
    const { data, error } = await supabase
      .from('fee_categories')
      .select('*')
      .order('name', { ascending: true })

    if (error) throw error
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function getFeeCategoryById(id: string): Promise<ApiResponse<FeeCategory>> {
  try {
    const { data, error } = await supabase
      .from('fee_categories')
      .select('*')
      .eq('id', id)
      .single()

    if (error) throw error
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function createFeeCategory(category: Omit<FeeCategory, 'id' | 'created_at' | 'updated_at' | 'account_id'>): Promise<ApiResponse<FeeCategory>> {
  try {
    const { data, error } = await supabase
      .from('fee_categories')
      .insert(category)
      .select()
      .single()

    if (error) throw error
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function updateFeeCategory(id: string, updates: Partial<FeeCategory>): Promise<ApiResponse<FeeCategory>> {
  try {
    const { data, error } = await supabase
      .from('fee_categories')
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

export async function deleteFeeCategory(id: string): Promise<ApiResponse<null>> {
  try {
    const { error } = await supabase
      .from('fee_categories')
      .delete()
      .eq('id', id)

    if (error) throw error
    return { data: null, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

// Fee Structures
export async function getFeeStructures(filters?: {
  category_id?: string
  class?: string
}): Promise<ApiResponse<FeeStructure[]>> {
  try {
    let query = supabase
      .from('fee_structures')
      .select('*, fee_categories(name)')
      .order('name', { ascending: true })

    if (filters?.category_id) {
      query = query.eq('category_id', filters.category_id)
    }
    if (filters?.class) {
      query = query.eq('class', filters.class)
    }

    const { data, error } = await query

    if (error) throw error
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function getFeeStructureById(id: string): Promise<ApiResponse<FeeStructure>> {
  try {
    const { data, error } = await supabase
      .from('fee_structures')
      .select('*, fee_categories(name)')
      .eq('id', id)
      .single()

    if (error) throw error
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function createFeeStructure(structure: Omit<FeeStructure, 'id' | 'created_at' | 'updated_at' | 'account_id'>): Promise<ApiResponse<FeeStructure>> {
  try {
    const { data, error } = await supabase
      .from('fee_structures')
      .insert(structure)
      .select()
      .single()

    if (error) throw error
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function updateFeeStructure(id: string, updates: Partial<FeeStructure>): Promise<ApiResponse<FeeStructure>> {
  try {
    const { data, error } = await supabase
      .from('fee_structures')
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

export async function deleteFeeStructure(id: string): Promise<ApiResponse<null>> {
  try {
    const { error } = await supabase
      .from('fee_structures')
      .delete()
      .eq('id', id)

    if (error) throw error
    return { data: null, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}

export async function getFeeStructuresByClass(studentClass: string): Promise<ApiResponse<FeeStructure[]>> {
  try {
    const { data, error } = await supabase
      .from('fee_structures')
      .select('*, fee_categories(name)')
      .eq('class', studentClass)
      .eq('is_active', true)
      .order('name', { ascending: true })

    if (error) throw error
    return { data, error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}
