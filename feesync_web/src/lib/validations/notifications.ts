import { z } from 'zod'

export const notificationSettingsSchema = z.object({
  auto_reminder_days: z.coerce.number().min(1).max(30),
  reminder_frequency: z.coerce.number().min(1).max(10),
  enabled_channels: z.array(z.enum(['email', 'sms', 'both'])),
})

export type NotificationSettingsInput = z.infer<typeof notificationSettingsSchema>
