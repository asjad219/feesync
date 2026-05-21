'use client'

import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog'

interface ConfirmDialogProps {
  open: boolean
  title: string
  description: string
  action: string
  onConfirm: () => void
  onCancel: () => void
  isLoading?: boolean
  destructive?: boolean
}

export function ConfirmDialog({
  open,
  title,
  description,
  action,
  onConfirm,
  onCancel,
  isLoading,
  destructive,
}: ConfirmDialogProps) {
  return (
    <AlertDialog open={open} onOpenChange={(isOpen) => !isOpen && onCancel()}>
      <AlertDialogContent className="bg-surface-high border-0">
        <AlertDialogHeader>
          <AlertDialogTitle className="text-headline-md">{title}</AlertDialogTitle>
          <AlertDialogDescription className="text-body-lg text-muted">
            {description}
          </AlertDialogDescription>
        </AlertDialogHeader>
        <div className="flex gap-3 justify-end">
          <AlertDialogCancel className="bg-surface-container hover:bg-surface-low border-0">
            Cancel
          </AlertDialogCancel>
          <AlertDialogAction
            onClick={onConfirm}
            disabled={isLoading}
            className={`${
              destructive
                ? 'bg-red-600 hover:bg-red-700'
                : 'btn-primary-gradient'
            }`}
          >
            {isLoading ? 'Processing...' : action}
          </AlertDialogAction>
        </div>
      </AlertDialogContent>
    </AlertDialog>
  )
}
