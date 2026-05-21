import { z } from 'zod'

export const paymentSchema = z.object({
  student_id: z.string().min(1, 'Student is required').uuid('Invalid student'),
  amount: z.coerce.number().min(0.01, 'Amount must be greater than 0'),
  payment_method: z.enum(['cash', 'bank_transfer', 'mobile_money', 'card', 'other']),
  payment_date: z.string().min(1, 'Payment date is required'),
  receipt_number: z
    .string()
    .max(50, 'Receipt number must be less than 50 characters')
    .optional()
    .or(z.literal('')),
  transaction_id: z
    .string()
    .max(100, 'Transaction ID must be less than 100 characters')
    .optional()
    .or(z.literal('')),
  status: z.enum(['pending', 'completed', 'failed']).default('completed'),
  notes: z
    .string()
    .max(500, 'Notes must be less than 500 characters')
    .optional()
    .or(z.literal('')),
  fee_allocations: z
    .array(z.object({
      fee_structure_id: z.string().uuid('Invalid fee structure'),
      amount: z.number().min(0, 'Amount must be non-negative'),
    }))
    .min(1, 'At least one fee must be allocated'),
})

export const updatePaymentSchema = paymentSchema.partial()

export type PaymentFormData = z.infer<typeof paymentSchema>
export type PaymentInput = z.infer<typeof paymentSchema>
export type UpdatePaymentInput = z.infer<typeof updatePaymentSchema>
