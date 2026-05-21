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

type FeeCategory = Database['public']['Tables']['fee_categories']['Row']

interface FeeCategoryTableProps {
  categories: FeeCategory[]
  onEdit: (category: FeeCategory) => void
  onDelete: (category: FeeCategory) => void
  isLoading?: boolean
}

export function FeeCategoryTable({
  categories,
  onEdit,
  onDelete,
  isLoading,
}: FeeCategoryTableProps) {
  if (isLoading) {
    return <div className="text-center py-8">Loading...</div>
  }

  if (categories.length === 0) {
    return (
      <div className="card-stitch text-center py-12">
        <p className="text-muted">No fee categories found</p>
      </div>
    )
  }

  return (
    <div className="card-stitch overflow-x-auto">
      <Table>
        <TableHeader>
          <TableRow className="border-b border-surface-high hover:bg-transparent">
            <TableHead className="text-label-md">Name</TableHead>
            <TableHead className="text-label-md">Description</TableHead>
            <TableHead className="text-label-md">Status</TableHead>
            <TableHead className="text-label-md text-right">Actions</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {categories.map((category) => (
            <TableRow key={category.id} className="border-b border-surface-low hover:bg-surface-low">
              <TableCell className="text-body-lg font-medium">{category.name}</TableCell>
              <TableCell className="text-body-lg text-muted">{category.description || '—'}</TableCell>
              <TableCell>
                <span className={`status-${category.is_active ? 'success' : 'error'}`}>
                  {category.is_active ? 'Active' : 'Inactive'}
                </span>
              </TableCell>
              <TableCell className="text-right">
                <div className="flex gap-2 justify-end">
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => onEdit(category)}
                    className="bg-surface-high border-0 hover:bg-surface-container"
                  >
                    <Edit2 className="h-4 w-4" />
                  </Button>
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => onDelete(category)}
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
