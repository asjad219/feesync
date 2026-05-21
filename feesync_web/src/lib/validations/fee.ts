import { z } from 'zod'

export const feeCategorySchema = z.object({
  name: z
    .string()
    .min(1, 'Category name is required')
    .max(100, 'Category name must be less than 100 characters'),
  description: z
    .string()
    .max(500, 'Description must be less than 500 characters')
    .optional()
    .or(z.literal('')),
  is_active: z.boolean().optional().default(true),
})

export const feeStructureSchema = z.object({
  category_id: z.string().min(1, 'Category is required').uuid('Invalid category'),
  name: z
    .string()
    .min(1, 'Fee name is required')
    .max(100, 'Fee name must be less than 100 characters'),
  amount: z.coerce.number().min(0.01, 'Amount must be greater than 0'),
  class: z
    .string()
    .min(1, 'Class is required')
    .max(20, 'Class must be less than 20 characters'),
  due_date: z
    .string()
    .optional()
    .or(z.literal('')),
  description: z
    .string()
    .max(500, 'Description must be less than 500 characters')
    .optional()
    .or(z.literal('')),
  plan_type: z.enum(['monthly', 'quarterly', 'half_yearly', 'annual', 'custom', 'per_class']).default('monthly'),
  late_fine: z.coerce.number().min(0).default(0),
  grace_days: z.coerce.number().int().min(0).default(0),
  gst_percent: z.coerce.number().min(0).max(100).default(0),
  auto_generate_dues: z.boolean().optional().default(true),
  is_active: z.boolean().optional().default(true),
})

export const updateFeeStructureSchema = feeStructureSchema.partial()

export type FeeCategoryFormData = z.infer<typeof feeCategorySchema>
export type FeeCategoryInput = z.infer<typeof feeCategorySchema>
export type FeeStructureFormData = z.infer<typeof feeStructureSchema>
export type FeeStructureInput = z.infer<typeof feeStructureSchema>
export type UpdateFeeStructureInput = z.infer<typeof updateFeeStructureSchema>
