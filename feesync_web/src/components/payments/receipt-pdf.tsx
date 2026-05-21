'use client'

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
  <Document>
    <Page size="A6" style={styles.page}>
      <View style={styles.header}>
        <Text style={styles.title}>FeeSync</Text>
        <Text style={styles.subtitle}>Payment Receipt</Text>
      </View>

      <View style={styles.infoRow}>
        <View style={styles.infoCol}>
          <Text style={styles.label}>Receipt No</Text>
          <Text style={styles.value}>{receiptNumber}</Text>
        </View>
        <View style={styles.infoCol}>
          <Text style={styles.label}>Date</Text>
          <Text style={styles.value}>{date}</Text>
        </View>
      </View>

      <View style={styles.infoCol}>
        <Text style={styles.label}>Student</Text>
        <Text style={styles.value}>{studentName}</Text>
        <Text style={{ fontSize: 10, color: '#666' }}>ID: {admissionNumber}</Text>
      </View>

      <View style={styles.table}>
        <View style={[styles.tableRow, styles.tableHeader]}>
          <Text style={styles.col1}>Description</Text>
          <Text style={styles.col2}>Amount</Text>
        </View>
        {items.map((item, index) => (
          <View key={index} style={styles.tableRow}>
            <Text style={styles.col1}>{item.name}</Text>
            <Text style={styles.col2}>₹{item.amount.toFixed(2)}</Text>
          </View>
        ))}
      </View>

      <View style={styles.totalRow}>
        <Text style={[styles.col1, { fontWeight: 'bold' }]}>Total Amount Paid</Text>
        <Text style={[styles.col2, { fontWeight: 'bold' }]}>₹{amount.toFixed(2)}</Text>
      </View>

      <View style={{ marginTop: 10 }}>
        <Text style={styles.label}>Payment Method</Text>
        <Text style={[styles.value, { textTransform: 'capitalize' }]}>{method}</Text>
      </View>

      <Text style={styles.footer}>Thank you for your payment!</Text>
    </Page>
  </Document>
)

export function DownloadReceiptButton({ receipt }: { receipt: any }) {
  const [isClient, setIsClient] = React.useState(false)
  
  React.useEffect(() => {
    setIsClient(true)
  }, [])

  if (!isClient) return <Button size="sm" variant="outline" disabled><Receipt className="h-4 w-4 mr-2" />PDF</Button>

  return (
    <PDFDownloadLink
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
      {({ loading }) => (
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
    </PDFDownloadLink>
  )
}
