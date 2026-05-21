'use client'

import { Edit2, Trash2, Receipt } from 'lucide-react'
import { Button } from '@/components/ui/button'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { DownloadReceiptButton } from './receipt-pdf'
import type { Database } from '@/lib/supabase/types'

type Payment = Database['public']['Tables']['payments']['Row']
type Student = Database['public']['Tables']['students']['Row']

interface PaymentTableProps {
  payments: Payment[]
  students?: Student[]
  onEdit?: (payment: Payment) => void
  onDelete?: (payment: Payment) => void
  isLoading?: boolean
}

export function PaymentTable({
  payments,
  students = [],
  onEdit,
  onDelete,
  isLoading,
}: PaymentTableProps) {
  const studentMap = Object.fromEntries(students.map((s) => [s.id, s]))

  if (isLoading) {
    return <div className="text-center py-8">Loading...</div>
  }

  if (payments.length === 0) {
    return (
      <div className="card-stitch text-center py-12">
        <p className="text-muted">No payments found</p>
      </div>
    )
  }

  return (
    <div className="card-stitch overflow-x-auto">
      <Table>
        <TableHeader>
          <TableRow className="border-b border-surface-high hover:bg-transparent">
            <TableHead className="text-label-md">Student</TableHead>
            <TableHead className="text-label-md">Amount</TableHead>
            <TableHead className="text-label-md">Method</TableHead>
            <TableHead className="text-label-md">Date</TableHead>
            <TableHead className="text-label-md">Status</TableHead>
            <TableHead className="text-label-md">Receipt No</TableHead>
            <TableHead className="text-label-md text-right">Actions</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {payments.map((payment) => {
            const student = studentMap[payment.student_id]
            const statusColor =
              payment.status === 'completed'
                ? 'success'
                : payment.status === 'failed'
                  ? 'error'
                  : 'warning'

            return (
              <TableRow key={payment.id} className="border-b border-surface-low hover:bg-surface-low">
                <TableCell className="text-body-lg">
                  {student ? `${student.first_name} ${student.last_name}` : 'Unknown'}
                </TableCell>
                <TableCell className="text-body-lg font-semibold">
                  ₹{payment.amount?.toFixed(2)}
                </TableCell>
                <TableCell className="text-body-lg capitalize">{payment.payment_method?.replace('_', ' ')}</TableCell>
                <TableCell className="text-body-lg">
                  {new Date(payment.payment_date).toLocaleDateString()}
                </TableCell>
                <TableCell>
                  <span className={`status-${statusColor}`}>
                    {payment.status?.charAt(0).toUpperCase() + payment.status?.slice(1)}
                  </span>
                </TableCell>
                <TableCell className="text-body-lg">{payment.receipt_number || '—'}</TableCell>
                <TableCell className="text-right">
                  <div className="flex gap-2 justify-end">
                    <DownloadReceiptButton receipt={payment} />
                    {onEdit && (
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => onEdit(payment)}
                        className="bg-surface-high border-0 hover:bg-surface-container"
                      >
                        <Edit2 className="h-4 w-4" />
                      </Button>
                    )}
                    {onDelete && (
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => onDelete(payment)}
                        className="bg-surface-high border-0 hover:bg-red-900/20"
                      >
                        <Trash2 className="h-4 w-4 text-destructive" />
                      </Button>
                    )}
                  </div>
                </TableCell>
              </TableRow>
            )
          })}
        </TableBody>
      </Table>
    </div>
  )
}
