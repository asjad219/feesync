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
import type { Database } from '@/lib/supabase/types'

type FeeStructure = Database['public']['Tables']['fee_structures']['Row']

interface FeeStructureTableProps {
  structures: FeeStructure[]
  categoryNames?: Record<string, string>
  onEdit: (structure: FeeStructure) => void
  onDelete: (structure: FeeStructure) => void
  isLoading?: boolean
}

export function FeeStructureTable({
  structures,
  categoryNames = {},
  onEdit,
  onDelete,
  isLoading,
}: FeeStructureTableProps) {
  if (isLoading) {
    return <div className="text-center py-8">Loading...</div>
  }

  if (structures.length === 0) {
    return (
      <div className="card-stitch text-center py-12">
        <p className="text-muted">No fee structures found</p>
      </div>
    )
  }

  return (
    <div className="card-stitch overflow-x-auto">
      <Table>
        <TableHeader>
          <TableRow className="border-b border-surface-high hover:bg-transparent">
            <TableHead className="text-label-md">Name</TableHead>
            <TableHead className="text-label-md">Category</TableHead>
            <TableHead className="text-label-md">Plan Type</TableHead>
            <TableHead className="text-label-md">Class</TableHead>
            <TableHead className="text-label-md">Amount</TableHead>
            <TableHead className="text-label-md">Due Date/Day</TableHead>
            <TableHead className="text-label-md text-right">Actions</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {structures.map((structure) => (
            <TableRow key={structure.id} className="border-b border-surface-low hover:bg-surface-low">
              <TableCell className="text-body-lg font-medium">{structure.name}</TableCell>
              <TableCell className="text-body-lg">
                {categoryNames[structure.category_id] || '—'}
              </TableCell>
              <TableCell className="text-body-lg">
                <span className="px-2 py-1 rounded-full text-xs font-semibold bg-primary-900/20 text-primary-400 capitalize">
                  {structure.plan_type || 'monthly'}
                </span>
              </TableCell>
              <TableCell className="text-body-lg">{structure.class}</TableCell>
              <TableCell className="text-body-lg font-semibold">
                ₹{structure.amount?.toFixed(2)}
              </TableCell>
              <TableCell className="text-body-lg">
                {structure.due_date ? new Date(structure.due_date).toLocaleDateString() : '—'}
              </TableCell>
              <TableCell className="text-right">
                <div className="flex gap-2 justify-end">
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => onEdit(structure)}
                    className="bg-surface-high border-0 hover:bg-surface-container"
                  >
                    <Edit2 className="h-4 w-4" />
                  </Button>
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => onDelete(structure)}
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
