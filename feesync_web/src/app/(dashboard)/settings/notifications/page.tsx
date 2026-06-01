'use client'

import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Bell, Mail, MessageSquare, Save } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Checkbox } from '@/components/ui/checkbox'
import { Card } from '@/components/ui/card'
import { 
  getNotificationSettings, 
  updateNotificationSettings 
} from '@/lib/supabase/repositories/notifications'
import { notificationSettingsSchema, type NotificationSettingsInput } from '@/lib/validations/notifications'
import { toast } from 'sonner'
import { TableSkeleton } from '@/components/ui/loading-skeleton'

export default function NotificationSettingsPage() {
  const queryClient = useQueryClient()

  const { data: settings, isLoading } = useQuery({
    queryKey: ['notification-settings'],
    queryFn: () => getNotificationSettings(),
    select: (res) => res.data,
  })

  const {
    register,
    handleSubmit,
    watch,
    setValue,
    formState: { errors },
    reset
  } = useForm<NotificationSettingsInput>({
    resolver: zodResolver(notificationSettingsSchema),
    values: settings ? {
      auto_reminder_days: settings.auto_reminder_days,
      reminder_frequency: settings.reminder_frequency,
      enabled_channels: settings.enabled_channels as any,
    } : undefined,
  })

  const mutation = useMutation({
    mutationFn: (data: NotificationSettingsInput) => 
      updateNotificationSettings(settings!.id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notification-settings'] })
      toast.success('Notification settings saved')
    },
    onError: (error) => {
      toast.error(error instanceof Error ? error.message : 'Failed to save settings')
    }
  })

  const enabledChannels = watch('enabled_channels') || []

  const handleChannelToggle = (channel: string) => {
    const current = [...enabledChannels]
    const index = current.indexOf(channel as any)
    if (index > -1) {
      current.splice(index, 1)
    } else {
      current.push(channel as any)
    }
    setValue('enabled_channels', current)
  }

  const onSubmit = (data: NotificationSettingsInput) => {
    mutation.mutate(data)
  }

  if (isLoading) return <TableSkeleton />

  return (
    <div className="max-w-4xl space-y-6">
      <div>
        <h1 className="headline-md">Notification Settings</h1>
        <p className="label-md text-muted mt-1">
          Configure how and when fee reminders are sent to parents
        </p>
      </div>

      <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
        <Card className="card-stitch p-6 border-none">
          <div className="space-y-6">
            <div className="flex items-start gap-4">
              <div className="bg-primary/10 p-3 rounded-full">
                <Bell className="h-6 w-6 text-primary" />
              </div>
              <div className="flex-1 space-y-4">
                <h2 className="label-lg text-primary-text font-bold">Auto-Reminder Rules</h2>
                
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="space-y-2">
                    <Label htmlFor="auto_reminder_days" className="label-md">
                      First Reminder (Days before due date)
                    </Label>
                    <Input
                      id="auto_reminder_days"
                      type="number"
                      {...register('auto_reminder_days')}
                      className="input-stitch"
                    />
                    {errors.auto_reminder_days && (
                      <p className="text-sm text-destructive">{errors.auto_reminder_days.message}</p>
                    )}
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="reminder_frequency" className="label-md">
                      Reminder Frequency (Every N days)
                    </Label>
                    <Input
                      id="reminder_frequency"
                      type="number"
                      {...register('reminder_frequency')}
                      className="input-stitch"
                    />
                    {errors.reminder_frequency && (
                      <p className="text-sm text-destructive">{errors.reminder_frequency.message}</p>
                    )}
                  </div>
                </div>
              </div>
            </div>

            <div className="flex items-start gap-4 pt-6 border-t border-surface-high">
              <div className="bg-success/10 p-3 rounded-full">
                <MessageSquare className="h-6 w-6 text-success" />
              </div>
              <div className="flex-1 space-y-4">
                <h2 className="label-lg text-primary-text font-bold">Preferred Channels</h2>
                <p className="body-md text-secondary-text">
                  Choose which platforms to use for sending automated notifications.
                </p>

                <div className="space-y-4">
                  <div className="flex items-center space-x-3 p-4 rounded-xl bg-surface-container/50 border border-surface-high">
                    <Checkbox 
                      id="email" 
                      checked={enabledChannels.includes('email' as any)}
                      onCheckedChange={() => handleChannelToggle('email')}
                    />
                    <Label htmlFor="email" className="flex items-center gap-2 cursor-pointer">
                      <Mail className="h-4 w-4 text-muted" />
                      <span>Email Notifications</span>
                    </Label>
                  </div>

                  <div className="flex items-center space-x-3 p-4 rounded-xl bg-surface-container/50 border border-surface-high">
                    <Checkbox 
                      id="sms" 
                      checked={enabledChannels.includes('sms' as any)}
                      onCheckedChange={() => handleChannelToggle('sms')}
                    />
                    <Label htmlFor="sms" className="flex items-center gap-2 cursor-pointer">
                      <MessageSquare className="h-4 w-4 text-muted" />
                      <span>SMS / WhatsApp Alerts</span>
                    </Label>
                  </div>
                </div>
                {errors.enabled_channels && (
                  <p className="text-sm text-destructive">{errors.enabled_channels.message}</p>
                )}
              </div>
            </div>
          </div>
        </Card>

        <div className="flex justify-end">
          <Button 
            type="submit" 
            className="btn-primary-gradient" 
            disabled={mutation.isPending}
          >
            <Save className="h-5 w-5 mr-2" />
            {mutation.isPending ? 'Saving...' : 'Save Settings'}
          </Button>
        </div>
      </form>
    </div>
  )
}
