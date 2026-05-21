'use client'

import { useState } from 'react'
import Link from 'next/link'
import { ChevronLeft } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { StudentForm } from '@/components/students/student-form'
import { createStudent } from '@/lib/supabase/repositories/students'
import { useRouter } from 'next/navigation'
import type { CreateStudentInput } from '@/lib/validations/student'

export default function NewStudentPage() {
  const router = useRouter()
  const [isLoading, setIsLoading] = useState(false)

  const handleSubmit = async (data: CreateStudentInput) => {
    setIsLoading(true)
    try {
      await createStudent(data)
      router.push('/students')
    } catch (error) {
      throw error
    } finally {
      setIsLoading(false)
    }
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
          <h1 className="headline-md">Add New Student</h1>
          <p className="label-md text-muted mt-1">Enter student information</p>
        </div>
      </div>

      {/* Form Card */}
      <div className="card-stitch">
        <StudentForm onSubmit={handleSubmit} isLoading={isLoading} />
      </div>
    </div>
  )
}
