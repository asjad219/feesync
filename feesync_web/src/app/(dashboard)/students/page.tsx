'use client'

import { useState, useEffect } from 'react'
import { useQuery } from '@tanstack/react-query'
import Link from 'next/link'
import { Plus } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { SearchInput } from '@/components/ui/search-input'
import { StudentTable } from '@/components/students/student-table'
import { ConfirmDialog } from '@/components/ui/confirm-dialog'
import { TableSkeleton } from '@/components/ui/loading-skeleton'
import { getStudents, deleteStudent } from '@/lib/supabase/repositories/students'
import { useRouter } from 'next/navigation'
import { toast } from 'sonner'
import type { Database } from '@/lib/supabase/types'

type Student = Database['public']['Tables']['students']['Row']

export default function StudentsPage() {
  const router = useRouter()
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedStudent, setSelectedStudent] = useState<Student | null>(null)
  const [showDeleteDialog, setShowDeleteDialog] = useState(false)
  const [isDeleting, setIsDeleting] = useState(false)

  const { data: students = [], isLoading, error, refetch } = useQuery({
    queryKey: ['students'],
    queryFn: () => getStudents(),
    staleTime: 5 * 60 * 1000,
    select: (res) => res.data || [],
  })

  const filteredStudents = students.filter((student) =>
    `${student.first_name} ${student.last_name} ${student.admission_number}`
      .toLowerCase()
      .includes(searchTerm.toLowerCase())
  )

  const handleDelete = async () => {
    if (!selectedStudent) return

    setIsDeleting(true)
    try {
      await deleteStudent(selectedStudent.id)
      toast.success('Student deleted successfully')
      await refetch()
      setShowDeleteDialog(false)
      setSelectedStudent(null)
    } catch (error) {
      toast.error(error instanceof Error ? error.message : 'Failed to delete student')
    } finally {
      setIsDeleting(false)
    }
  }

  const handleEdit = (student: Student) => {
    router.push(`/students/${student.id}`)
  }

  const handleDeleteClick = (student: Student) => {
    setSelectedStudent(student)
    setShowDeleteDialog(true)
  }

  if (error) {
    return (
      <div className="card-stitch text-center py-8">
        <p className="text-destructive">Error loading students</p>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <h1 className="headline-md">Students</h1>
          <p className="label-md text-muted mt-1">{students.length} total students</p>
        </div>
        <Link href="/students/new">
          <Button className="btn-primary-gradient">
            <Plus className="h-5 w-5 mr-2" />
            Add Student
          </Button>
        </Link>
      </div>

      {/* Search */}
      <SearchInput
        placeholder="Search by name or admission number..."
        value={searchTerm}
        onChange={setSearchTerm}
      />

      {/* Students Table */}
      {isLoading ? (
        <TableSkeleton />
      ) : (
        <StudentTable
          students={filteredStudents}
          onEdit={handleEdit}
          onDelete={handleDeleteClick}
        />
      )}

      {/* Delete Confirm Dialog */}
      <ConfirmDialog
        open={showDeleteDialog}
        title="Delete Student"
        description={`Are you sure you want to delete ${selectedStudent?.first_name} ${selectedStudent?.last_name}? This action cannot be undone.`}
        action="Delete"
        onConfirm={handleDelete}
        onCancel={() => {
          setShowDeleteDialog(false)
          setSelectedStudent(null)
        }}
        isLoading={isDeleting}
        destructive
      />
    </div>
  )
}
