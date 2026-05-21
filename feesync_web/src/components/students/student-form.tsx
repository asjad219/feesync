'use client'

import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { createStudentSchema, type CreateStudentInput } from '@/lib/validations/student'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import { toast } from 'sonner'

interface StudentFormProps {
  onSubmit: (data: CreateStudentInput) => Promise<void>
  isLoading?: boolean
  defaultValues?: Partial<CreateStudentInput>
}

export function StudentForm({ onSubmit, isLoading, defaultValues }: StudentFormProps) {
  const {
    register,
    handleSubmit,
    watch,
    setValue,
    formState: { errors },
  } = useForm<CreateStudentInput>({
    resolver: zodResolver(createStudentSchema),
    defaultValues,
  })

  const genderValue = watch('gender')

  const onSubmitHandler = async (data: CreateStudentInput) => {
    try {
      await onSubmit(data)
      toast.success('Student saved successfully')
    } catch (error) {
      toast.error(error instanceof Error ? error.message : 'Failed to save student')
    }
  }

  return (
    <form onSubmit={handleSubmit(onSubmitHandler)} className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Admission Number */}
        <div className="space-y-2">
          <Label htmlFor="admission_number" className="label-md">
            Admission Number *
          </Label>
          <Input
            id="admission_number"
            {...register('admission_number')}
            placeholder="e.g., ADM001"
            className="input-stitch"
          />
          {errors.admission_number && (
            <p className="text-sm text-destructive">{errors.admission_number.message}</p>
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
            <p className="text-sm text-destructive">{errors.class.message}</p>
          )}
        </div>

        {/* First Name */}
        <div className="space-y-2">
          <Label htmlFor="first_name" className="label-md">
            First Name *
          </Label>
          <Input
            id="first_name"
            {...register('first_name')}
            placeholder="Enter first name"
            className="input-stitch"
          />
          {errors.first_name && (
            <p className="text-sm text-destructive">{errors.first_name.message}</p>
          )}
        </div>

        {/* Last Name */}
        <div className="space-y-2">
          <Label htmlFor="last_name" className="label-md">
            Last Name *
          </Label>
          <Input
            id="last_name"
            {...register('last_name')}
            placeholder="Enter last name"
            className="input-stitch"
          />
          {errors.last_name && (
            <p className="text-sm text-destructive">{errors.last_name.message}</p>
          )}
        </div>

        {/* Section */}
        <div className="space-y-2">
          <Label htmlFor="section" className="label-md">
            Section
          </Label>
          <Input
            id="section"
            {...register('section')}
            placeholder="e.g., A"
            className="input-stitch"
          />
          {errors.section && (
            <p className="text-sm text-destructive">{errors.section.message}</p>
          )}
        </div>

        {/* Stream */}
        <div className="space-y-2">
          <Label htmlFor="stream" className="label-md">
            Stream
          </Label>
          <Input
            id="stream"
            {...register('stream')}
            placeholder="e.g., Science"
            className="input-stitch"
          />
          {errors.stream && (
            <p className="text-sm text-destructive">{errors.stream.message}</p>
          )}
        </div>

        {/* Gender */}
        <div className="space-y-2">
          <Label htmlFor="gender" className="label-md">
            Gender
          </Label>
          <Select value={genderValue || ''} onValueChange={(value) => setValue('gender', value as any)}>
            <SelectTrigger className="input-stitch">
              <SelectValue placeholder="Select gender" />
            </SelectTrigger>
            <SelectContent className="bg-surface-container border-0">
              <SelectItem value="male">Male</SelectItem>
              <SelectItem value="female">Female</SelectItem>
              <SelectItem value="other">Other</SelectItem>
            </SelectContent>
          </Select>
          {errors.gender && (
            <p className="text-sm text-destructive">{errors.gender.message}</p>
          )}
        </div>

        {/* Date of Birth */}
        <div className="space-y-2">
          <Label htmlFor="date_of_birth" className="label-md">
            Date of Birth
          </Label>
          <Input
            id="date_of_birth"
            type="date"
            {...register('date_of_birth')}
            className="input-stitch"
          />
          {errors.date_of_birth && (
            <p className="text-sm text-destructive">{errors.date_of_birth.message}</p>
          )}
        </div>

        {/* Parent Name */}
        <div className="space-y-2">
          <Label htmlFor="parent_name" className="label-md">
            Parent/Guardian Name
          </Label>
          <Input
            id="parent_name"
            {...register('parent_name')}
            placeholder="Enter parent name"
            className="input-stitch"
          />
          {errors.parent_name && (
            <p className="text-sm text-destructive">{errors.parent_name.message}</p>
          )}
        </div>

        {/* Parent Phone */}
        <div className="space-y-2">
          <Label htmlFor="parent_phone" className="label-md">
            Parent Phone
          </Label>
          <Input
            id="parent_phone"
            type="tel"
            {...register('parent_phone')}
            placeholder="Enter phone number"
            className="input-stitch"
          />
          {errors.parent_phone && (
            <p className="text-sm text-destructive">{errors.parent_phone.message}</p>
          )}
        </div>

        {/* Parent Email */}
        <div className="space-y-2">
          <Label htmlFor="parent_email" className="label-md">
            Parent Email
          </Label>
          <Input
            id="parent_email"
            type="email"
            {...register('parent_email')}
            placeholder="Enter email"
            className="input-stitch"
          />
          {errors.parent_email && (
            <p className="text-sm text-destructive">{errors.parent_email.message}</p>
          )}
        </div>
      </div>

      {/* Address */}
      <div className="space-y-2">
        <Label htmlFor="address" className="label-md">
          Address
        </Label>
        <Textarea
          id="address"
          {...register('address')}
          placeholder="Enter student address"
          className="input-stitch"
          rows={3}
        />
        {errors.address && (
          <p className="text-sm text-destructive">{errors.address.message}</p>
        )}
      </div>

      <Button
        type="submit"
        disabled={isLoading}
        className="btn-primary-gradient w-full md:w-auto"
      >
        {isLoading ? 'Saving...' : 'Save Student'}
      </Button>
    </form>
  )
}
