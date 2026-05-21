'use client'

import { useState, useEffect } from 'react'
import { useQuery } from '@tanstack/react-query'
import Link from 'next/link'
import { ChevronLeft } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { StudentForm } from '@/components/students/student-form'
import { getStudentById, updateStudent } from '@/lib/supabase/repositories/students'
import { useRouter, useParams } from 'next/navigation'
import { FormSkeleton } from '@/components/ui/loading-skeleton'
import { toast } from 'sonner'
import type { CreateStudentInput } from '@/lib/validations/student'

export default function EditStudentPage() {
  const router = useRouter()
  const params = useParams()
  const studentId = params.id as string
  const [isLoading, setIsLoading] = useState(false)

  const { data: student, isLoading: isFetching, error } = useQuery({
    queryKey: ['student', studentId],
    queryFn: () => getStudentById(studentId),
  })

  const handleSubmit = async (data: CreateStudentInput) => {
    setIsLoading(true)
    try {
      await updateStudent(studentId, data)
      toast.success('Student updated successfully')
      router.push('/students')
    } catch (error) {
      throw error
    } finally {
      setIsLoading(false)
    }
  }

  if (error) {
    return (
      <div className="card-stitch text-center py-8">
        <p className="text-destructive">Error loading student</p>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Link href="/students">
          <Button variant="outline" size="icon" className="bg-surface-high border-0 hover:bg-surface-container">
            <ChevronLeft className="h-5 w-5" />
          </Button>
        </Link>
        <div>
          <h1 className="headline-md">Edit Student</h1>
          <p className="label-md text-muted mt-1">Update student information</p>
        </div>
      </div>

      {/* Form Card */}
      <div className="card-stitch">
        {isFetching ? (
          <FormSkeleton />
        ) : student ? (
          <StudentForm onSubmit={handleSubmit} isLoading={isLoading} defaultValues={student} />
        ) : (
          <p className="text-center text-muted">Student not found</p>
        )}
      </div>
    </div>
  )
}
