'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { useQuery, useMutation } from '@tanstack/react-query'
import { Check, ChevronsUpDown, Loader2, Receipt } from 'lucide-react'
import { cn } from '@/lib/utils'
import { Button } from '@/components/ui/button'
import {
  Command,
  CommandEmpty,
  CommandGroup,
  CommandInput,
  CommandItem,
  CommandList,
} from '@/components/ui/command'
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from '@/components/ui/popover'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { Checkbox } from '@/components/ui/checkbox'
import { toast } from 'sonner'
import { supabase } from '@/lib/supabase/client'
import { getDues } from '@/lib/supabase/repositories/fees'
import { createPayment } from '@/lib/supabase/repositories/payments'
import type { Student, Due, PaymentMethod } from '@/lib/supabase/types'

export default function NewPaymentPage() {
  const router = useRouter()
  const [open, setOpen] = useState(false)
  const [selectedStudent, setSelectedStudent] = useState<Student | null>(null)
  const [students, setStudents] = useState<Student[]>([])
  const [search, setSearch] = useState('')
  const [selectedDues, setSelectedDues] = useState<string[]>([])
  const [paymentAmount, setPaymentAmount] = useState<string>('')
  const [paymentMethod, setPaymentMethod] = useState<PaymentMethod>('cash')
  const [transactionId, setTransactionId] = useState('')
  const [notes, setNotes] = useState('')
  const [isSubmitting, setIsSubmitting] = useState(false)

  // Fetch students for search
  useEffect(() => {
    const fetchStudents = async () => {
      if (search.length < 2) return
      const { data } = await supabase
        .from('students')
        .select('*')
        .or(`first_name.ilike.%${search}%,last_name.ilike.%${search}%,admission_number.ilike.%${search}%`)
        .limit(10)
      if (data) setStudents(data)
    }
    const timer = setTimeout(fetchStudents, 300)
    return () => clearTimeout(timer)
  }, [search])

  // Fetch pending dues for selected student
  const { data: dues = [], isLoading: duesLoading } = useQuery({
    queryKey: ['student-dues', selectedStudent?.id],
    queryFn: () => getDues({ student_id: selectedStudent?.id, status: 'pending' }),
    enabled: !!selectedStudent,
    select: (res) => res.data || [],
  })

  // Calculate total selected dues
  const selectedDuesData = dues.filter(d => selectedDues.includes(d.id))
  const totalDueAmount = selectedDuesData.reduce((sum, d) => sum + Number(d.due_amount), 0)

  useEffect(() => {
    if (selectedDues.length > 0) {
      setPaymentAmount(totalDueAmount.toString())
    }
  }, [selectedDues, totalDueAmount])

  const handleDueToggle = (dueId: string) => {
    setSelectedDues(prev => 
      prev.includes(dueId) ? prev.filter(id => id !== dueId) : [...prev, dueId]
    )
  }

  const handleSubmit = async () => {
    if (!selectedStudent || selectedDues.length === 0 || !paymentAmount) {
      toast.error('Please fill all required fields')
      return
    }

    setIsSubmitting(true)
    try {
      const amount = parseFloat(paymentAmount)
      
      // Basic allocation logic: distribute amount across selected dues
      let remainingPayment = amount
      const allocations = selectedDuesData.map(due => {
        const paymentForThisDue = Math.min(remainingPayment, Number(due.due_amount))
        remainingPayment -= paymentForThisDue
        return {
          fee_structure_id: due.fee_structure_id,
          due_id: due.id,
          amount: paymentForThisDue
        }
      }).filter(a => a.amount > 0)

      const { data, error } = await createPayment({
        student_id: selectedStudent.id,
        amount,
        payment_method: paymentMethod,
        transaction_id: transactionId,
        payment_date: new Date().toISOString().split('T')[0],
        notes,
        status: 'completed'
      }, allocations)

      if (error) throw error

      toast.success('Payment recorded successfully')
      router.push('/payments')
    } catch (error) {
      toast.error(error instanceof Error ? error.message : 'Failed to record payment')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold text-white">Record New Payment</h1>
        <Button variant="outline" onClick={() => router.back()} className="border-gray-700 text-gray-300">
          Cancel
        </Button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* Step 1: Select Student */}
        <Card className="md:col-span-1 bg-surface-container border-0 shadow-xl">
          <CardHeader>
            <CardTitle className="text-xl text-primary-400">Step 1: Student</CardTitle>
            <CardDescription>Search and select a student</CardDescription>
          </CardHeader>
          <CardContent>
            <Popover open={open} onOpenChange={setOpen}>
              <PopoverTrigger>
                <Button
                  variant="outline"
                  role="combobox"
                  aria-expanded={open}
                  className="w-full justify-between bg-surface border-gray-700 text-gray-200"
                >
                  {selectedStudent
                    ? `${selectedStudent.first_name} ${selectedStudent.last_name}`
                    : "Search student..."}
                  <ChevronsUpDown className="ml-2 h-4 w-4 shrink-0 opacity-50" />
                </Button>
              </PopoverTrigger>
              <PopoverContent className="w-full p-0 bg-surface border-gray-700">
                <Command>
                  <CommandInput 
                    placeholder="Type name or ID..." 
                    value={search}
                    onValueChange={setSearch}
                  />
                  <CommandList>
                    <CommandEmpty>No student found.</CommandEmpty>
                    <CommandGroup>
                      {students.map((student) => (
                        <CommandItem
                          key={student.id}
                          onSelect={() => {
                            setSelectedStudent(student)
                            setOpen(false)
                            setSelectedDues([])
                          }}
                          className="text-gray-200 hover:bg-gray-800"
                        >
                          <Check
                            className={cn(
                              "mr-2 h-4 w-4",
                              selectedStudent?.id === student.id ? "opacity-100" : "opacity-0"
                            )}
                          />
                          <div>
                            <p>{student.first_name} {student.last_name}</p>
                            <p className="text-xs text-gray-500">{student.admission_number} • Class {student.class}</p>
                          </div>
                        </CommandItem>
                      ))}
                    </CommandGroup>
                  </CommandList>
                </Command>
              </PopoverContent>
            </Popover>

            {selectedStudent && (
              <div className="mt-6 p-4 rounded-lg bg-surface border border-gray-800">
                <p className="text-sm font-medium text-gray-400 uppercase tracking-wider">Selection</p>
                <h3 className="text-lg font-semibold text-white mt-1">
                  {selectedStudent.first_name} {selectedStudent.last_name}
                </h3>
                <p className="text-gray-400">ID: {selectedStudent.admission_number}</p>
                <p className="text-gray-400">Class: {selectedStudent.class}</p>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Step 2: Select Dues & Payment */}
        <Card className="md:col-span-2 bg-surface-container border-0 shadow-xl">
          <CardHeader>
            <CardTitle className="text-xl text-primary-400">Step 2: Payment Details</CardTitle>
            <CardDescription>Select pending dues and enter amount</CardDescription>
          </CardHeader>
          <CardContent className="space-y-6">
            {!selectedStudent ? (
              <div className="flex flex-col items-center justify-center py-12 text-gray-500">
                <Receipt className="h-12 w-12 mb-4 opacity-20" />
                <p>Select a student to see pending dues</p>
              </div>
            ) : duesLoading ? (
              <div className="flex justify-center py-12">
                <Loader2 className="h-8 w-8 animate-spin text-primary-500" />
              </div>
            ) : dues.length === 0 ? (
              <div className="p-4 rounded-lg bg-green-900/20 border border-green-900/50 text-green-400">
                No pending dues for this student.
              </div>
            ) : (
              <div className="space-y-4">
                <Label className="text-gray-400">Select Pending Dues</Label>
                <div className="space-y-2 max-h-60 overflow-y-auto pr-2">
                  {dues.map((due) => (
                    <div 
                      key={due.id} 
                      className={cn(
                        "flex items-center justify-between p-3 rounded-lg border cursor-pointer transition-colors",
                        selectedDues.includes(due.id) 
                          ? "bg-primary-900/20 border-primary-500" 
                          : "bg-surface border-gray-800 hover:border-gray-700"
                      )}
                      onClick={() => handleDueToggle(due.id)}
                    >
                      <div className="flex items-center space-x-3">
                        <Checkbox 
                          checked={selectedDues.includes(due.id)} 
                          onCheckedChange={() => handleDueToggle(due.id)}
                        />
                        <div>
                          <p className="font-medium text-white">{due.period_name} - {due.fee_structures?.name}</p>
                          <p className="text-xs text-gray-400">Due: {new Date(due.due_date).toLocaleDateString()}</p>
                        </div>
                      </div>
                      <div className="text-right">
                        <p className="font-bold text-white">₹{due.due_amount}</p>
                        {Number(due.late_fine_applied) > 0 && (
                          <p className="text-[10px] text-orange-400">Inc. ₹{due.late_fine_applied} fine</p>
                        )}
                      </div>
                    </div>
                  ))}
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-6 pt-6 border-t border-gray-800">
                  <div className="space-y-2">
                    <Label htmlFor="amount" className="text-gray-400">Payment Amount *</Label>
                    <div className="relative">
                      <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500">₹</span>
                      <Input
                        id="amount"
                        type="number"
                        value={paymentAmount}
                        onChange={(e) => setPaymentAmount(e.target.value)}
                        className="pl-7 bg-surface border-gray-700 text-white"
                        placeholder="0.00"
                      />
                    </div>
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="method" className="text-gray-400">Payment Method *</Label>
                    <Select value={paymentMethod} onValueChange={(v) => setPaymentMethod(v as PaymentMethod)}>
                      <SelectTrigger className="bg-surface border-gray-700 text-white">
                        <SelectValue placeholder="Select method" />
                      </SelectTrigger>
                      <SelectContent className="bg-surface border-gray-700">
                        <SelectItem value="cash">Cash</SelectItem>
                        <SelectItem value="bank_transfer">Bank Transfer</SelectItem>
                        <SelectItem value="mobile_money">UPI / Mobile Money</SelectItem>
                        <SelectItem value="card">Card</SelectItem>
                        <SelectItem value="other">Other</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="txnId" className="text-gray-400">Transaction/Ref ID</Label>
                    <Input
                      id="txnId"
                      value={transactionId}
                      onChange={(e) => setTransactionId(e.target.value)}
                      className="bg-surface border-gray-700 text-white"
                      placeholder="Optional"
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="notes" className="text-gray-400">Internal Notes</Label>
                    <Input
                      id="notes"
                      value={notes}
                      onChange={(e) => setNotes(e.target.value)}
                      className="bg-surface border-gray-700 text-white"
                      placeholder="Optional"
                    />
                  </div>
                </div>

                <div className="mt-8">
                  <Button 
                    onClick={handleSubmit} 
                    disabled={isSubmitting || !selectedStudent || selectedDues.length === 0}
                    className="w-full btn-primary-gradient py-6 text-lg font-bold"
                  >
                    {isSubmitting ? (
                      <>
                        <Loader2 className="mr-2 h-5 w-5 animate-spin" />
                        Processing...
                      </>
                    ) : (
                      `Record Payment ₹${paymentAmount || '0'}`
                    )}
                  </Button>
                </div>
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
