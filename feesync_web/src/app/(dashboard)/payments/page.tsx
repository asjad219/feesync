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
import { TableSkeleton } from '@/components/ui/loading-skeleton'
import { PaymentForm } from '@/components/payments/payment-form'
import { PaymentTable } from '@/components/payments/payment-table'
import { SearchInput } from '@/components/ui/search-input'
import { ConfirmDialog } from '@/components/ui/confirm-dialog'
import { getPayments, createPayment, deletePayment } from '@/lib/supabase/repositories/payments'
import { getStudents } from '@/lib/supabase/repositories/students'
import { getFeeStructures } from '@/lib/supabase/repositories/fees'
import { toast } from 'sonner'
import type { Database } from '@/lib/supabase/types'
import type { PaymentInput } from '@/lib/validations/payment'

type Payment = Database['public']['Tables']['payments']['Row']

export default function PaymentsPage() {
  const [searchTerm, setSearchTerm] = useState('')
  const [openDialog, setOpenDialog] = useState(false)
  const [deletingPayment, setDeletingPayment] = useState<Payment | null>(null)
  const [showDeleteDialog, setShowDeleteDialog] = useState(false)
  const [isDeleting, setIsDeleting] = useState(false)
  const [isSubmitting, setIsSubmitting] = useState(false)

  const {
    data: payments = [],
    isLoading: paymentsLoading,
    refetch: refetchPayments,
  } = useQuery({
    queryKey: ['payments'],
    queryFn: () => getPayments(),
    select: (res) => res.data || [],
  })

  const {
    data: students = [],
    isLoading: studentsLoading,
  } = useQuery({
    queryKey: ['students'],
    queryFn: () => getStudents(),
    select: (res) => res.data || [],
  })

  const {
    data: feeStructures = [],
    isLoading: feesLoading,
  } = useQuery({
    queryKey: ['fee-structures'],
    queryFn: () => getFeeStructures(),
    select: (res) => res.data || [],
  })

  const studentMap = Object.fromEntries(students.map((s) => [s.id, s]))

  const filteredPayments = payments.filter((payment) => {
    const student = studentMap[payment.student_id]
    const searchStr = `${student?.first_name || ''} ${student?.last_name || ''} ${payment.receipt_number || ''}`
    return searchStr.toLowerCase().includes(searchTerm.toLowerCase())
  })

  const handleSubmit = async (data: PaymentInput) => {
    setIsSubmitting(true)
    try {
      await createPayment({
        student_id: data.student_id,
        amount: data.amount,
        payment_method: data.payment_method,
        payment_date: data.payment_date,
        transaction_id: data.transaction_id || undefined,
        status: data.status || 'completed',
        notes: data.notes || undefined,
      }, data.fee_allocations || [])
      toast.success('Payment recorded successfully')
      await refetchPayments()
      setOpenDialog(false)
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleDelete = async () => {
    if (!deletingPayment) return

    setIsDeleting(true)
    try {
      await deletePayment(deletingPayment.id)
      toast.success('Payment deleted successfully')
      await refetchPayments()
      setShowDeleteDialog(false)
      setDeletingPayment(null)
    } finally {
      setIsDeleting(false)
    }
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <h1 className="headline-md">Payments</h1>
          <p className="label-md text-muted mt-1">{payments.length} total payments</p>
        </div>
        <Button onClick={() => setOpenDialog(true)} className="btn-primary-gradient">
          <Plus className="h-5 w-5 mr-2" />
          Record Payment
        </Button>
      </div>

      {/* Search */}
      <SearchInput
        placeholder="Search by student name or receipt..."
        value={searchTerm}
        onChange={setSearchTerm}
      />

      {/* Payments Table */}
      {paymentsLoading || studentsLoading ? (
        <TableSkeleton />
      ) : (
        <PaymentTable
          payments={filteredPayments}
          students={students}
          onDelete={(payment) => {
            setDeletingPayment(payment)
            setShowDeleteDialog(true)
          }}
        />
      )}

      {/* Add Payment Dialog */}
      <Dialog open={openDialog} onOpenChange={setOpenDialog}>
        <DialogContent className="bg-surface-high border-0 max-w-2xl">
          <DialogHeader>
            <DialogTitle className="headline-md">Record Payment</DialogTitle>
          </DialogHeader>
          {studentsLoading || feesLoading ? (
            <div className="text-center py-8">Loading...</div>
          ) : (
            <PaymentForm
              students={students}
              feeStructures={feeStructures}
              onSubmit={handleSubmit}
              isLoading={isSubmitting}
            />
          )}
        </DialogContent>
      </Dialog>

      {/* Delete Confirm Dialog */}
      <ConfirmDialog
        open={showDeleteDialog}
        title="Delete Payment"
        description="Are you sure you want to delete this payment? This action cannot be undone."
        action="Delete"
        onConfirm={handleDelete}
        onCancel={() => {
          setShowDeleteDialog(false)
          setDeletingPayment(null)
        }}
        isLoading={isDeleting}
        destructive
      />
    </div>
  )
}
