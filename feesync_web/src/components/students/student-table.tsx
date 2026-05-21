'use client'

import { Edit2, Trash2 } from 'lucide-react'
import { Button } from '@/components/ui/button'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { type Database } from '@/lib/supabase/types'

type Student = Database['public']['Tables']['students']['Row']

interface StudentTableProps {
  students: Student[]
  onEdit: (student: Student) => void
  onDelete: (student: Student) => void
  isLoading?: boolean
}

export function StudentTable({ students, onEdit, onDelete, isLoading }: StudentTableProps) {
  if (isLoading) {
    return <div className="text-center py-8">Loading...</div>
  }

  if (students.length === 0) {
    return (
      <div className="card-stitch text-center py-12">
        <p className="text-muted">No students found</p>
      </div>
    )
  }

  return (
    <div className="card-stitch overflow-x-auto">
      <Table>
        <TableHeader>
          <TableRow className="border-b border-surface-high hover:bg-transparent">
            <TableHead className="text-label-md">Admission</TableHead>
            <TableHead className="text-label-md">Name</TableHead>
            <TableHead className="text-label-md">Class</TableHead>
            <TableHead className="text-label-md">Section</TableHead>
            <TableHead className="text-label-md">Parent Phone</TableHead>
            <TableHead className="text-label-md text-right">Actions</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {students.map((student) => (
            <TableRow key={student.id} className="border-b border-surface-low hover:bg-surface-low">
              <TableCell className="text-body-lg">{student.admission_number}</TableCell>
              <TableCell className="text-body-lg">
                {student.first_name} {student.last_name}
              </TableCell>
              <TableCell className="text-body-lg">{student.class}</TableCell>
              <TableCell className="text-body-lg">{student.section || '—'}</TableCell>
              <TableCell className="text-body-lg">{student.parent_phone || '—'}</TableCell>
              <TableCell className="text-right">
                <div className="flex gap-2 justify-end">
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => onEdit(student)}
                    className="bg-surface-high border-0 hover:bg-surface-container"
                  >
                    <Edit2 className="h-4 w-4" />
                  </Button>
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => onDelete(student)}
                    className="bg-surface-high border-0 hover:bg-red-900/20"
                  >
                    <Trash2 className="h-4 w-4 text-destructive" />
                  </Button>
                </div>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  )
}
