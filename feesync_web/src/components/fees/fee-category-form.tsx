'use client'

import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { feeCategorySchema, type FeeCategoryInput } from '@/lib/validations/fee'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { toast } from 'sonner'

interface FeeCategoryFormProps {
  onSubmit: (data: FeeCategoryInput) => Promise<void>
  isLoading?: boolean
  defaultValues?: Partial<FeeCategoryInput>
}

export function FeeCategoryForm({ onSubmit, isLoading, defaultValues }: FeeCategoryFormProps) {
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FeeCategoryInput>({
    resolver: zodResolver(feeCategorySchema),
    defaultValues,
  })

  const onSubmitHandler = async (data: FeeCategoryInput) => {
    try {
      await onSubmit(data)
      toast.success('Fee category saved successfully')
    } catch (error) {
      toast.error(error instanceof Error ? error.message : 'Failed to save fee category')
    }
  }

  return (
    <form onSubmit={handleSubmit(onSubmitHandler)} className="space-y-6">
      {/* Name */}
      <div className="space-y-2">
        <Label htmlFor="name" className="label-md">
          Category Name *
        </Label>
        <Input
          id="name"
          {...register('name')}
          placeholder="e.g., Tuition Fee"
          className="input-stitch"
        />
        {errors.name && (
          <p className="text-sm text-destructive">{errors.name.message}</p>
        )}
      </div>

      {/* Description */}
      <div className="space-y-2">
        <Label htmlFor="description" className="label-md">
          Description
        </Label>
        <Textarea
          id="description"
          {...register('description')}
          placeholder="Enter category description"
          className="input-stitch"
          rows={4}
        />
        {errors.description && (
          <p className="text-sm text-destructive">{errors.description.message}</p>
        )}
      </div>

      <Button
        type="submit"
        disabled={isLoading}
        className="btn-primary-gradient w-full md:w-auto"
      >
        {isLoading ? 'Saving...' : 'Save Category'}
      </Button>
    </form>
  )
}
