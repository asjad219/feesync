'use client'

import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { paymentSchema, type PaymentInput } from '@/lib/validations/payment'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { Checkbox } from '@/components/ui/checkbox'
import { toast } from 'sonner'
import type { Database } from '@/lib/supabase/types'

type Student = Database['public']['Tables']['students']['Row']
type FeeStructure = Database['public']['Tables']['fee_structures']['Row']

interface PaymentFormProps {
  students: Student[]
  feeStructures: FeeStructure[]
  onSubmit: (data: PaymentInput) => Promise<void>
  isLoading?: boolean
}

export function PaymentForm({
  students,
  feeStructures,
  onSubmit,
  isLoading,
}: PaymentFormProps) {
  const [selectedFees, setSelectedFees] = useState<Set<string>>(new Set())
  const {
    register,
    handleSubmit,
    watch,
    setValue,
    formState: { errors },
  } = useForm({
    resolver: zodResolver(paymentSchema),
  })

  const studentId = watch('student_id')
  const selectedStudent = students.find((s) => s.id === studentId)
  const studentFees = feeStructures.filter((f) => f.class === selectedStudent?.class)

  const onSubmitHandler = async (data: any) => {
    try {
      const feeIds = Array.from(selectedFees)
      const allocations = feeIds.map((feeId) => ({
        fee_structure_id: feeId,
        amount: 0,
      }))
      await onSubmit({
        ...data,
        fee_allocations: allocations,
      })
      toast.success('Payment recorded successfully')
    } catch (error) {
      toast.error(error instanceof Error ? error.message : 'Failed to record payment')
    }
  }

  return (
    <form onSubmit={handleSubmit(onSubmitHandler)} className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Student */}
        <div className="space-y-2">
          <Label htmlFor="student_id" className="label-md">
            Student *
          </Label>
          <Select value={studentId || ''} onValueChange={(value) => setValue('student_id', value || '')}>
            <SelectTrigger className="input-stitch">
              <SelectValue placeholder="Select student" />
            </SelectTrigger>
            <SelectContent className="bg-surface-container border-0">
              {students.map((student) => (
                <SelectItem key={student.id} value={student.id}>
                  {student.first_name} {student.last_name} ({student.admission_number})
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          {errors.student_id && (
            <p className="text-sm text-destructive">{errors.student_id.message as string}</p>
          )}
        </div>

        {/* Amount */}
        <div className="space-y-2">
          <Label htmlFor="amount" className="label-md">
            Amount *
          </Label>
          <Input
            id="amount"
            {...register('amount')}
            type="number"
            step="0.01"
            min="0.01"
            placeholder="0.00"
            className="input-stitch"
          />
          {errors.amount && (
            <p className="text-sm text-destructive">{errors.amount.message as string}</p>
          )}
        </div>

        {/* Payment Method */}
        <div className="space-y-2">
          <Label htmlFor="payment_method" className="label-md">
            Payment Method *
          </Label>
          <Select defaultValue="cash" onValueChange={(value) => setValue('payment_method', value as any)}>
            <SelectTrigger className="input-stitch">
              <SelectValue />
            </SelectTrigger>
            <SelectContent className="bg-surface-container border-0">
              <SelectItem value="cash">Cash</SelectItem>
              <SelectItem value="bank_transfer">Bank Transfer</SelectItem>
              <SelectItem value="mobile_money">Mobile Money</SelectItem>
              <SelectItem value="card">Card</SelectItem>
              <SelectItem value="other">Other</SelectItem>
            </SelectContent>
          </Select>
          {errors.payment_method && (
            <p className="text-sm text-destructive">{errors.payment_method.message as string}</p>
          )}
        </div>

        {/* Payment Date */}
        <div className="space-y-2">
          <Label htmlFor="payment_date" className="label-md">
            Payment Date *
          </Label>
          <Input
            id="payment_date"
            {...register('payment_date')}
            type="date"
            className="input-stitch"
          />
          {errors.payment_date && (
            <p className="text-sm text-destructive">{errors.payment_date.message as string}</p>
          )}
        </div>

        {/* Receipt Number */}
        <div className="space-y-2">
          <Label htmlFor="receipt_number" className="label-md">
            Receipt Number
          </Label>
          <Input
            id="receipt_number"
            {...register('receipt_number')}
            placeholder="e.g., RCP001"
            className="input-stitch"
          />
          {errors.receipt_number && (
            <p className="text-sm text-destructive">{errors.receipt_number.message as string}</p>
          )}
        </div>

        {/* Transaction ID */}
        <div className="space-y-2">
          <Label htmlFor="transaction_id" className="label-md">
            Transaction ID
          </Label>
          <Input
            id="transaction_id"
            {...register('transaction_id')}
            placeholder="Optional transaction ID"
            className="input-stitch"
          />
          {errors.transaction_id && (
            <p className="text-sm text-destructive">{errors.transaction_id.message as string}</p>
          )}
        </div>
      </div>

      {/* Fees Selection */}
      {selectedStudent && studentFees.length > 0 && (
        <div className="space-y-3">
          <Label className="label-md">Allocate to Fees</Label>
          <div className="card-stitch space-y-3">
            {studentFees.map((fee) => (
              <div key={fee.id} className="flex items-center gap-3">
                <Checkbox
                  id={fee.id}
                  checked={selectedFees.has(fee.id)}
                  onCheckedChange={(checked) => {
                    const newSet = new Set(selectedFees)
                    if (checked) {
                      newSet.add(fee.id)
                    } else {
                      newSet.delete(fee.id)
                    }
                    setSelectedFees(newSet)
                  }}
                />
                <Label htmlFor={fee.id} className="flex-1 cursor-pointer body-lg">
                  {fee.name} - {fee.amount?.toFixed(2)} USD
                </Label>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Notes */}
      <div className="space-y-2">
        <Label htmlFor="notes" className="label-md">
          Notes
        </Label>
        <Textarea
          id="notes"
          {...register('notes')}
          placeholder="Additional payment notes"
          className="input-stitch"
          rows={3}
        />
        {errors.notes && (
          <p className="text-sm text-destructive">{errors.notes.message}</p>
        )}
      </div>

      <Button
        type="submit"
        disabled={isLoading}
        className="btn-primary-gradient w-full md:w-auto"
      >
        {isLoading ? 'Recording...' : 'Record Payment'}
      </Button>
    </form>
  )
}
