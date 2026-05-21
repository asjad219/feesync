'use client'

import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { feeStructureSchema, type FeeStructureInput } from '@/lib/validations/fee'
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
import { toast } from 'sonner'
import type { Database } from '@/lib/supabase/types'

type FeeCategory = Database['public']['Tables']['fee_categories']['Row']

interface FeeStructureFormProps {
  categories: FeeCategory[]
  onSubmit: (data: FeeStructureInput) => Promise<void>
  isLoading?: boolean
  defaultValues?: Partial<FeeStructureInput>
}

export function FeeStructureForm({
  categories,
  onSubmit,
  isLoading,
  defaultValues,
}: FeeStructureFormProps) {
  const {
    register,
    handleSubmit,
    watch,
    setValue,
    formState: { errors },
  } = useForm({
    resolver: zodResolver(feeStructureSchema),
    defaultValues: defaultValues as any,
  })

  const categoryId = watch('category_id')
  const planType = watch('plan_type')

  const onSubmitHandler = async (data: FeeStructureInput) => {
    try {
      await onSubmit(data)
      toast.success('Fee structure saved successfully')
    } catch (error) {
      toast.error(error instanceof Error ? error.message : 'Failed to save fee structure')
    }
  }

  return (
    <form onSubmit={handleSubmit(onSubmitHandler)} className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Category */}
        <div className="space-y-2">
          <Label htmlFor="category_id" className="label-md">
            Category *
          </Label>
          <Select value={categoryId || ''} onValueChange={(value) => setValue('category_id', value)}>
            <SelectTrigger className="input-stitch">
              <SelectValue placeholder="Select category" />
            </SelectTrigger>
            <SelectContent className="bg-surface-container border-0">
              {categories.map((category) => (
                <SelectItem key={category.id} value={category.id}>
                  {category.name}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          {errors.category_id && (
            <p className="text-sm text-destructive">{errors.category_id.message as string}</p>
          )}
        </div>

        {/* Fee Name */}
        <div className="space-y-2">
          <Label htmlFor="name" className="label-md">
            Fee Name *
          </Label>
          <Input
            id="name"
            {...register('name')}
            placeholder="e.g., Monthly Tuition"
            className="input-stitch"
          />
          {errors.name && (
            <p className="text-sm text-destructive">{errors.name.message as string}</p>
          )}
        </div>

        {/* Plan Type */}
        <div className="space-y-2">
          <Label htmlFor="plan_type" className="label-md">
            Plan Type *
          </Label>
          <Select value={planType || 'monthly'} onValueChange={(value) => setValue('plan_type', value as any)}>
            <SelectTrigger className="input-stitch">
              <SelectValue placeholder="Select plan type" />
            </SelectTrigger>
            <SelectContent className="bg-surface-container border-0">
              <SelectItem value="monthly">Monthly</SelectItem>
              <SelectItem value="quarterly">Quarterly</SelectItem>
              <SelectItem value="half_yearly">Half Yearly</SelectItem>
              <SelectItem value="annual">Annual</SelectItem>
              <SelectItem value="custom">Custom/One-time</SelectItem>
              <SelectItem value="per_class">Per Class</SelectItem>
            </SelectContent>
          </Select>
          {errors.plan_type && (
            <p className="text-sm text-destructive">{errors.plan_type.message as string}</p>
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

        {/* Class */}
        <div className="space-y-2">
          <Label htmlFor="class" className="label-md">
            Class *
          </Label>
          <Input
            id="class"
            {...register('class')}
            placeholder="e.g., 10A"
            className="input-stitch"
          />
          {errors.class && (
            <p className="text-sm text-destructive">{errors.class.message as string}</p>
          )}
        </div>

        {/* Due Date */}
        <div className="space-y-2">
          <Label htmlFor="due_date" className="label-md">
            Due Date/Day
          </Label>
          <Input
            id="due_date"
            {...register('due_date')}
            type="date"
            className="input-stitch"
          />
          {errors.due_date && (
            <p className="text-sm text-destructive">{errors.due_date.message as string}</p>
          )}
        </div>

        {/* Late Fine */}
        <div className="space-y-2">
          <Label htmlFor="late_fine" className="label-md">
            Late Fine (Per Cycle)
          </Label>
          <Input
            id="late_fine"
            {...register('late_fine')}
            type="number"
            step="0.01"
            min="0"
            className="input-stitch"
          />
        </div>

        {/* Grace Days */}
        <div className="space-y-2">
          <Label htmlFor="grace_days" className="label-md">
            Grace Period (Days)
          </Label>
          <Input
            id="grace_days"
            {...register('grace_days')}
            type="number"
            min="0"
            className="input-stitch"
          />
        </div>

        {/* GST Percent */}
        <div className="space-y-2">
          <Label htmlFor="gst_percent" className="label-md">
            GST (%)
          </Label>
          <Input
            id="gst_percent"
            {...register('gst_percent')}
            type="number"
            min="0"
            max="100"
            className="input-stitch"
          />
        </div>

        {/* Auto Generate Dues */}
        <div className="flex items-center space-x-2 pt-8">
          <input
            id="auto_generate_dues"
            type="checkbox"
            {...register('auto_generate_dues')}
            className="w-4 h-4 rounded border-gray-300 text-primary-600 focus:ring-primary-500"
          />
          <Label htmlFor="auto_generate_dues" className="label-md">
            Auto-generate monthly dues
          </Label>
        </div>
      </div>

      {/* Description */}
      <div className="space-y-2">
        <Label htmlFor="description" className="label-md">
          Description
        </Label>
        <Textarea
          id="description"
          {...register('description')}
          placeholder="Enter fee description"
          className="input-stitch"
          rows={3}
        />
        {errors.description && (
          <p className="text-sm text-destructive">{errors.description.message as string}</p>
        )}
      </div>

      <Button
        type="submit"
        disabled={isLoading}
        className="btn-primary-gradient w-full md:w-auto"
      >
        {isLoading ? 'Saving...' : 'Save Fee Structure'}
      </Button>
    </form>
  )
}
