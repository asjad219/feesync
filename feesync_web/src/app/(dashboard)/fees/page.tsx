'use client'

import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Plus } from 'lucide-react'
import { Button } from '@/components/ui/button'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { FeeCategoryForm } from '@/components/fees/fee-category-form'
import { FeeStructureForm } from '@/components/fees/fee-structure-form'
import { FeeCategoryTable } from '@/components/fees/fee-category-table'
import { FeeStructureTable } from '@/components/fees/fee-structure-table'
import { ConfirmDialog } from '@/components/ui/confirm-dialog'
import { TableSkeleton } from '@/components/ui/loading-skeleton'
import {
  getFeeCategories,
  getFeeStructures,
  createFeeCategory,
  updateFeeCategory,
  deleteFeeCategory,
  createFeeStructure,
  updateFeeStructure,
  deleteFeeStructure,
} from '@/lib/supabase/repositories/fees'
import { toast } from 'sonner'
import type { Database } from '@/lib/supabase/types'
import type { FeeCategoryInput, FeeStructureInput } from '@/lib/validations/fee'

type FeeCategory = Database['public']['Tables']['fee_categories']['Row']
type FeeStructure = Database['public']['Tables']['fee_structures']['Row']

export default function FeesPage() {
  const [activeTab, setActiveTab] = useState('categories')
  const [openDialog, setOpenDialog] = useState(false)
  const [editingCategory, setEditingCategory] = useState<FeeCategory | null>(null)
  const [editingStructure, setEditingStructure] = useState<FeeStructure | null>(null)
  const [deleteDialog, setDeleteDialog] = useState(false)
  const [deletingItem, setDeletingItem] = useState<FeeCategory | FeeStructure | null>(null)
  const [isDeleting, setIsDeleting] = useState(false)
  const [isSubmitting, setIsSubmitting] = useState(false)

  const {
    data: categories = [],
    isLoading: categoriesLoading,
    refetch: refetchCategories,
  } = useQuery({
    queryKey: ['fee-categories'],
    queryFn: () => getFeeCategories(),
    select: (response) => response.data || [],
  })

  const {
    data: structures = [],
    isLoading: structuresLoading,
    refetch: refetchStructures,
  } = useQuery({
    queryKey: ['fee-structures'],
    queryFn: () => getFeeStructures(),
    select: (response) => response.data || [],
  })

  const categoryNames = Object.fromEntries(categories.map((c) => [c.id, c.name]))

  // Category handlers
  const handleCategorySubmit = async (data: FeeCategoryInput) => {
    setIsSubmitting(true)
    try {
      if (editingCategory) {
        await updateFeeCategory(editingCategory.id, data)
      } else {
        await createFeeCategory(data)
      }
      await refetchCategories()
      setOpenDialog(false)
      setEditingCategory(null)
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleCategoryDelete = async () => {
    if (!deletingItem || !('is_active' in deletingItem)) return

    setIsDeleting(true)
    try {
      await deleteFeeCategory(deletingItem.id)
      toast.success('Fee category deleted successfully')
      await refetchCategories()
      setDeleteDialog(false)
      setDeletingItem(null)
    } finally {
      setIsDeleting(false)
    }
  }

  // Structure handlers
  const handleStructureSubmit = async (data: FeeStructureInput) => {
    setIsSubmitting(true)
    try {
      if (editingStructure) {
        await updateFeeStructure(editingStructure.id, data)
      } else {
        await createFeeStructure(data)
      }
      await refetchStructures()
      setOpenDialog(false)
      setEditingStructure(null)
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleStructureDelete = async () => {
    if (!deletingItem || !('category_id' in deletingItem)) return

    setIsDeleting(true)
    try {
      await deleteFeeStructure(deletingItem.id)
      toast.success('Fee structure deleted successfully')
      await refetchStructures()
      setDeleteDialog(false)
      setDeletingItem(null)
    } finally {
      setIsDeleting(false)
    }
  }

  const openEditCategory = (category: FeeCategory) => {
    setEditingCategory(category)
    setEditingStructure(null)
    setOpenDialog(true)
  }

  const openEditStructure = (structure: FeeStructure) => {
    setEditingStructure(structure)
    setEditingCategory(null)
    setOpenDialog(true)
  }

  const openNew = (tab: string) => {
    setActiveTab(tab)
    setEditingCategory(null)
    setEditingStructure(null)
    setOpenDialog(true)
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="headline-md">Fee Management</h1>
        <p className="label-md text-muted mt-1">Manage fee categories and structures</p>
      </div>

      {/* Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-4">
        <div className="flex items-center justify-between">
          <TabsList className="bg-surface-container border-0">
            <TabsTrigger value="categories">Categories</TabsTrigger>
            <TabsTrigger value="structures">Structures</TabsTrigger>
          </TabsList>
          <Button
            onClick={() => openNew(activeTab)}
            className="btn-primary-gradient"
          >
            <Plus className="h-5 w-5 mr-2" />
            Add {activeTab === 'categories' ? 'Category' : 'Fee'}
          </Button>
        </div>

        {/* Categories Tab */}
        <TabsContent value="categories" className="space-y-4">
          {categoriesLoading ? (
            <TableSkeleton />
          ) : (
            <FeeCategoryTable
              categories={categories}
              onEdit={openEditCategory}
              onDelete={(category) => {
                setDeletingItem(category)
                setDeleteDialog(true)
              }}
            />
          )}
        </TabsContent>

        {/* Structures Tab */}
        <TabsContent value="structures" className="space-y-4">
          {structuresLoading ? (
            <TableSkeleton />
          ) : (
            <FeeStructureTable
              structures={structures}
              categoryNames={categoryNames}
              onEdit={openEditStructure}
              onDelete={(structure) => {
                setDeletingItem(structure)
                setDeleteDialog(true)
              }}
            />
          )}
        </TabsContent>
      </Tabs>

      {/* Add/Edit Dialog */}
      <Dialog open={openDialog} onOpenChange={setOpenDialog}>
        <DialogContent className="bg-surface-high border-0 max-w-2xl">
          <DialogHeader>
            <DialogTitle className="headline-md">
              {activeTab === 'categories'
                ? editingCategory
                  ? 'Edit Category'
                  : 'Add Category'
                : editingStructure
                  ? 'Edit Fee'
                  : 'Add Fee'}
            </DialogTitle>
          </DialogHeader>

          {activeTab === 'categories' ? (
            <FeeCategoryForm
              onSubmit={handleCategorySubmit}
              isLoading={isSubmitting}
              defaultValues={editingCategory || undefined}
            />
          ) : (
            <FeeStructureForm
              categories={categories}
              onSubmit={handleStructureSubmit}
              isLoading={isSubmitting}
              defaultValues={editingStructure || undefined}
            />
          )}
        </DialogContent>
      </Dialog>

      {/* Delete Confirm Dialog */}
      <ConfirmDialog
        open={deleteDialog}
        title="Delete"
        description={`Are you sure you want to delete this ${'is_active' in (deletingItem || {}) ? 'category' : 'fee'}? This action cannot be undone.`}
        action="Delete"
        onConfirm={
          'category_id' in (deletingItem || {})
            ? handleStructureDelete
            : handleCategoryDelete
        }
        onCancel={() => {
          setDeleteDialog(false)
          setDeletingItem(null)
        }}
        isLoading={isDeleting}
        destructive
      />
    </div>
  )
}
