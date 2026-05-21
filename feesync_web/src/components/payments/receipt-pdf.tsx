'use client'
// @ts-nocheck

import React from 'react'
import {
  Document,
  Page,
  Text,
  View,
  StyleSheet,
  PDFDownloadLink,
} from '@react-pdf/renderer'
import { Button } from '@/components/ui/button'
import { Receipt } from 'lucide-react'

// Define styles for PDF
const styles = StyleSheet.create({
  page: {
    padding: 30,
    fontSize: 12,
    fontFamily: 'Helvetica',
  },
  header: {
    marginBottom: 20,
    borderBottomWidth: 1,
    borderBottomColor: '#eee',
    paddingBottom: 10,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#1a1a1a',
    marginBottom: 5,
  },
  subtitle: {
    fontSize: 14,
    color: '#666',
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 20,
  },
  infoCol: {
    flexDirection: 'column',
  },
  label: {
    fontSize: 10,
    color: '#888',
    textTransform: 'uppercase',
    marginBottom: 2,
  },
  value: {
    fontSize: 12,
    fontWeight: 'bold',
  },
  table: {
    marginTop: 30,
  },
  tableRow: {
    flexDirection: 'row',
    borderBottomWidth: 1,
    borderBottomColor: '#eee',
    paddingVertical: 10,
  },
  tableHeader: {
    backgroundColor: '#f9f9f9',
    fontWeight: 'bold',
  },
  col1: { width: '60%' },
  col2: { width: '40%', textAlign: 'right' },
  totalRow: {
    flexDirection: 'row',
    marginTop: 20,
    paddingTop: 10,
    borderTopWidth: 2,
    borderTopColor: '#333',
  },
  footer: {
    marginTop: 50,
    textAlign: 'center',
    fontSize: 10,
    color: '#aaa',
  },
})

// Cast components to any to avoid JSX type errors in React 19
const DocumentAny = Document as any
const PageAny = Page as any
const TextAny = Text as any
const ViewAny = View as any
const PDFDownloadLinkAny = PDFDownloadLink as any

interface ReceiptProps {
  receiptNumber: string
  date: string
  studentName: string
  admissionNumber: string
  amount: number
  method: string
  items: Array<{ name: string; amount: number }>
}

const ReceiptDocument = ({
  receiptNumber,
  date,
  studentName,
  admissionNumber,
  amount,
  method,
  items,
}: ReceiptProps) => (
  <DocumentAny>
    <PageAny size="A6" style={styles.page}>
      <ViewAny style={styles.header}>
        <TextAny style={styles.title}>FeeSync</TextAny>
        <TextAny style={styles.subtitle}>Payment Receipt</TextAny>
      </ViewAny>

      <ViewAny style={styles.infoRow}>
        <ViewAny style={styles.infoCol}>
          <TextAny style={styles.label}>Receipt No</TextAny>
          <TextAny style={styles.value}>{receiptNumber}</TextAny>
        </ViewAny>
        <ViewAny style={styles.infoCol}>
          <TextAny style={styles.label}>Date</TextAny>
          <TextAny style={styles.value}>{date}</TextAny>
        </ViewAny>
      </ViewAny>

      <ViewAny style={styles.infoCol}>
        <TextAny style={styles.label}>Student</TextAny>
        <TextAny style={styles.value}>{studentName}</TextAny>
        <TextAny style={{ fontSize: 10, color: '#666' }}>ID: {admissionNumber}</TextAny>
      </ViewAny>

      <ViewAny style={styles.table}>
        <ViewAny style={[styles.tableRow, styles.tableHeader]}>
          <TextAny style={styles.col1}>Description</TextAny>
          <TextAny style={styles.col2}>Amount</TextAny>
        </ViewAny>
        {items.map((item, index) => (
          <ViewAny key={index} style={styles.tableRow}>
            <TextAny style={styles.col1}>{item.name}</TextAny>
            <TextAny style={styles.col2}>₹{item.amount.toFixed(2)}</TextAny>
          </ViewAny>
        ))}
      </ViewAny>

      <ViewAny style={styles.totalRow}>
        <TextAny style={[styles.col1, { fontWeight: 'bold' }]}>Total Amount Paid</TextAny>
        <TextAny style={[styles.col2, { fontWeight: 'bold' }]}>₹{amount.toFixed(2)}</TextAny>
      </ViewAny>

      <ViewAny style={{ marginTop: 10 }}>
        <TextAny style={styles.label}>Payment Method</TextAny>
        <TextAny style={[styles.value, { textTransform: 'capitalize' }]}>{method}</TextAny>
      </ViewAny>

      <TextAny style={styles.footer}>Thank you for your payment!</TextAny>
    </PageAny>
  </DocumentAny>
)

export function DownloadReceiptButton({ receipt }: { receipt: any }) {
  const [isClient, setIsClient] = React.useState(false)
  
  React.useEffect(() => {
    setIsClient(true)
  }, [])

  if (!isClient) return <Button size="sm" variant="outline" disabled><Receipt className="h-4 w-4 mr-2" />PDF</Button>

  return (
    <PDFDownloadLinkAny
      document={
        <ReceiptDocument
          receiptNumber={receipt.receipt_number}
          date={new Date(receipt.payment_date).toLocaleDateString()}
          studentName={`${receipt.students?.first_name} ${receipt.students?.last_name}`}
          admissionNumber={receipt.students?.admission_number}
          amount={Number(receipt.amount)}
          method={receipt.payment_method}
          items={receipt.payment_records?.map((r: any) => ({
            name: r.fee_structures?.name || 'Fee Payment',
            amount: Number(r.amount)
          })) || []}
        />
      }
      fileName={`Receipt-${receipt.receipt_number}.pdf`}
    >
      {({ loading }: { loading: boolean }) => (
        <Button
          size="sm"
          variant="outline"
          className="bg-primary-900/10 border-primary-900/50 hover:bg-primary-900/20 text-primary-400"
          disabled={loading}
        >
          <Receipt className="h-4 w-4 mr-2" />
          {loading ? '...' : 'Receipt'}
        </Button>
      )}
    </PDFDownloadLinkAny>
  )
}
