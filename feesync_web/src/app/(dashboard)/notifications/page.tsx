'use client'

import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Bell, CheckCircle2, Clock, Mail, MessageSquare, RefreshCw, Trash2 } from 'lucide-react'
import { format } from 'date-fns'
import { Button } from '@/components/ui/button'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Badge } from '@/components/ui/badge'
import { Card } from '@/components/ui/card'
import { TableSkeleton } from '@/components/ui/loading-skeleton'
import { 
  getNotifications, 
  updateNotification, 
  deleteNotification,
  getPendingReminders 
} from '@/lib/supabase/repositories/notifications'
import { toast } from 'sonner'
import type { Notification, PendingReminder } from '@/lib/supabase/types'

export default function NotificationsPage() {
  const queryClient = useQueryClient()
  const [activeTab, setActiveTab] = useState('all')

  const { data: notifications = [], isLoading: loadingNotifications, refetch: refetchNotifications } = useQuery({
    queryKey: ['notifications'],
    queryFn: () => getNotifications(),
    select: (res) => res.data || [],
  })

  const { data: pendingReminders = [], isLoading: loadingReminders, refetch: refetchReminders } = useQuery({
    queryKey: ['pending-reminders'],
    queryFn: () => getPendingReminders(),
    select: (res) => res.data || [],
  })

  const updateStatusMutation = useMutation({
    mutationFn: ({ id, updates }: { id: string; updates: Partial<Notification> }) => 
      updateNotification(id, updates),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notifications'] })
      toast.success('Notification updated')
    },
    onError: (error) => {
      toast.error(error instanceof Error ? error.message : 'Failed to update notification')
    }
  })

  const deleteMutation = useMutation({
    mutationFn: (id: string) => deleteNotification(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notifications'] })
      toast.success('Notification deleted')
    },
    onError: (error) => {
      toast.error(error instanceof Error ? error.message : 'Failed to delete notification')
    }
  })

  const handleRefresh = () => {
    refetchNotifications()
    refetchReminders()
  }

  const markAsSent = (id: string) => {
    updateStatusMutation.mutate({ id, updates: { status: 'sent', sent_at: new Date().toISOString() } })
  }

  const handleDelete = (id: string) => {
    if (confirm('Are you sure you want to delete this log entry?')) {
      deleteMutation.mutate(id)
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="headline-md">Activity Log</h1>
          <p className="label-md text-muted mt-1">
            Track communication sent to parents and upcoming reminders
          </p>
        </div>
        <Button variant="outline" size="sm" onClick={handleRefresh} className="h-9">
          <RefreshCw className="h-4 w-4 mr-2" />
          Refresh
        </Button>
      </div>

      <Tabs defaultValue="all" onValueChange={setActiveTab} className="w-full">
        <TabsList className="bg-surface-container border-none p-1">
          <TabsTrigger value="all" className="rounded-md">All Activity</TabsTrigger>
          <TabsTrigger value="pending" className="rounded-md flex items-center gap-2">
            Pending Reminders
            {pendingReminders.length > 0 && (
              <Badge variant="secondary" className="bg-primary/20 text-primary hover:bg-primary/20 border-none px-1.5 py-0">
                {pendingReminders.length}
              </Badge>
            )}
          </TabsTrigger>
          <TabsTrigger value="failed" className="rounded-md">Failed</TabsTrigger>
        </TabsList>

        <TabsContent value="all" className="mt-6 space-y-4">
          {loadingNotifications ? (
            <TableSkeleton />
          ) : notifications.length === 0 ? (
            <EmptyState message="No notification logs found" />
          ) : (
            notifications.map((notification) => (
              <NotificationCard 
                key={notification.id} 
                notification={notification} 
                onMarkAsSent={markAsSent}
                onDelete={handleDelete}
              />
            ))
          )}
        </TabsContent>

        <TabsContent value="pending" className="mt-6 space-y-4">
          {loadingReminders ? (
            <TableSkeleton />
          ) : pendingReminders.length === 0 ? (
            <EmptyState message="No pending reminders" />
          ) : (
            pendingReminders.map((reminder) => (
              <ReminderCard key={reminder.id} reminder={reminder} />
            ))
          )}
        </TabsContent>

        <TabsContent value="failed" className="mt-6 space-y-4">
          {notifications.filter(n => n.status === 'failed').length === 0 ? (
            <EmptyState message="No failed notifications" />
          ) : (
            notifications.filter(n => n.status === 'failed').map((notification) => (
              <NotificationCard 
                key={notification.id} 
                notification={notification} 
                onMarkAsSent={markAsSent}
                onDelete={handleDelete}
              />
            ))
          )}
        </TabsContent>
      </Tabs>
    </div>
  )
}

function NotificationCard({ 
  notification, 
  onMarkAsSent,
  onDelete 
}: { 
  notification: any, 
  onMarkAsSent: (id: string) => void,
  onDelete: (id: string) => void
}) {
  const getIcon = () => {
    switch (notification.type) {
      case 'payment_reminder': return <Clock className="h-5 w-5 text-pending" />
      case 'payment_confirmation': return <CheckCircle2 className="h-5 w-5 text-success" />
      case 'welcome': return <MessageSquare className="h-5 w-5 text-primary" />
      default: return <Bell className="h-5 w-5 text-muted" />
    }
  }

  const getChannelIcon = () => {
    switch (notification.channel) {
      case 'email': return <Mail className="h-3 w-3 mr-1" />
      case 'sms': return <MessageSquare className="h-3 w-3 mr-1" />
      default: return <MessageSquare className="h-3 w-3 mr-1" />
    }
  }

  return (
    <Card className="card-stitch p-4 flex gap-4 items-start border-none">
      <div className="bg-surface-container-high p-3 rounded-full">
        {getIcon()}
      </div>
      <div className="flex-1 space-y-1">
        <div className="flex items-center justify-between">
          <h3 className="label-lg text-primary-text font-bold">
            {notification.subject || notification.type.replace('_', ' ').toUpperCase()}
          </h3>
          <span className="text-[10px] text-muted uppercase tracking-wider">
            {format(new Date(notification.created_at), 'MMM d, h:mm a')}
          </span>
        </div>
        <p className="body-md text-secondary-text leading-relaxed">
          {notification.message}
        </p>
        <div className="flex items-center gap-3 pt-2">
          {notification.students && (
            <Badge variant="outline" className="bg-surface-container border-none text-[10px] text-muted">
              Student: {notification.students.first_name} {notification.students.last_name}
            </Badge>
          )}
          <Badge variant="outline" className="bg-surface-container border-none text-[10px] text-muted flex items-center">
            {getChannelIcon()}
            {notification.channel.toUpperCase()}
          </Badge>
          <Badge 
            variant="outline" 
            className={`border-none text-[10px] ${
              notification.status === 'sent' ? 'bg-success/10 text-success' : 
              notification.status === 'pending' ? 'bg-pending/10 text-pending' : 
              'bg-destructive/10 text-destructive'
            }`}
          >
            {notification.status.toUpperCase()}
          </Badge>
        </div>
      </div>
      <div className="flex flex-col gap-2">
        {notification.status === 'pending' && (
          <Button size="icon" variant="ghost" onClick={() => onMarkAsSent(notification.id)} className="h-8 w-8 text-success hover:bg-success/10">
            <CheckCircle2 className="h-4 w-4" />
          </Button>
        )}
        <Button size="icon" variant="ghost" onClick={() => onDelete(notification.id)} className="h-8 w-8 text-destructive hover:bg-destructive/10">
          <Trash2 className="h-4 w-4" />
        </Button>
      </div>
    </Card>
  )
}

function ReminderCard({ reminder }: { reminder: PendingReminder }) {
  return (
    <Card className="card-stitch p-4 flex gap-4 items-start border-none bg-surface-container/40">
      <div className="bg-surface-container-high p-3 rounded-full">
        <Clock className="h-5 w-5 text-pending" />
      </div>
      <div className="flex-1 space-y-1">
        <div className="flex items-center justify-between">
          <h3 className="label-lg text-primary-text font-bold">
            Upcoming: {reminder.type.replace('_', ' ').toUpperCase()}
          </h3>
          <span className="text-[10px] text-muted uppercase tracking-wider">
            {reminder.scheduled_for ? format(new Date(reminder.scheduled_for), 'MMM d, h:mm a') : 'Not scheduled'}
          </span>
        </div>
        <p className="body-md text-secondary-text italic">
          "{reminder.message}"
        </p>
        <div className="flex items-center gap-3 pt-2">
          <Badge variant="outline" className="bg-surface-container border-none text-[10px] text-muted">
            Student: {reminder.student_first_name} {reminder.student_last_name} ({reminder.class})
          </Badge>
          <Badge variant="outline" className="bg-destructive/10 border-none text-[10px] text-destructive">
            Balance: ₹{reminder.balance.toLocaleString()}
          </Badge>
        </div>
      </div>
    </Card>
  )
}

function EmptyState({ message }: { message: string }) {
  return (
    <div className="text-center py-12 bg-surface-container/20 rounded-xl border border-dashed border-border">
      <Bell className="h-10 w-10 text-muted mx-auto mb-4 opacity-20" />
      <p className="text-muted italic">{message}</p>
    </div>
  )
}
