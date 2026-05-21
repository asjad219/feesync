import { z } from 'zod'

export const createStudentSchema = z.object({
  admission_number: z
    .string()
    .min(1, 'Admission number is required')
    .max(50, 'Admission number must be less than 50 characters'),
  first_name: z
    .string()
    .min(2, 'First name must be at least 2 characters')
    .max(50, 'First name must be less than 50 characters'),
  last_name: z
    .string()
    .min(2, 'Last name must be at least 2 characters')
    .max(50, 'Last name must be less than 50 characters'),
  class: z
    .string()
    .min(1, 'Class is required')
    .max(20, 'Class must be less than 20 characters'),
  section: z
    .string()
    .max(10, 'Section must be less than 10 characters')
    .optional()
    .or(z.literal('')),
  stream: z
    .string()
    .max(20, 'Stream must be less than 20 characters')
    .optional()
    .or(z.literal('')),
  gender: z
    .enum(['male', 'female', 'other'])
    .optional(),
  date_of_birth: z
    .string()
    .optional()
    .or(z.literal('')),
  parent_name: z
    .string()
    .max(100, 'Parent name must be less than 100 characters')
    .optional()
    .or(z.literal('')),
  parent_phone: z
    .string()
    .max(20, 'Phone must be less than 20 characters')
    .optional()
    .or(z.literal('')),
  parent_email: z
    .string()
    .email('Invalid email')
    .optional()
    .or(z.literal('')),
  address: z
    .string()
    .max(200, 'Address must be less than 200 characters')
    .optional()
    .or(z.literal('')),
})

export const updateStudentSchema = createStudentSchema.partial()

export const studentSchema = createStudentSchema

export type StudentFormData = z.infer<typeof createStudentSchema>
export type CreateStudentInput = z.infer<typeof createStudentSchema>
export type UpdateStudentInput = z.infer<typeof updateStudentSchema>
