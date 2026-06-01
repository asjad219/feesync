import Link from 'next/link'
import { Bell, CreditCard, Shield, User } from 'lucide-react'
import { Card } from '@/components/ui/card'

const settingsSections = [
  {
    title: 'Profile',
    description: 'Update your personal information and profile picture',
    icon: User,
    href: '/settings/profile',
    color: 'text-primary'
  },
  {
    title: 'Notifications',
    description: 'Configure automated fee reminders and alert channels',
    icon: Bell,
    href: '/settings/notifications',
    color: 'text-pending'
  },
  {
    title: 'Security',
    description: 'Manage your password and two-factor authentication',
    icon: Shield,
    href: '/settings/security',
    color: 'text-success'
  },
  {
    title: 'Billing',
    description: 'Manage your subscription plan and payment methods',
    icon: CreditCard,
    href: '/settings/billing',
    color: 'text-muted'
  }
]

export default function SettingsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="headline-md">Settings</h1>
        <p className="label-md text-muted mt-1">
          Manage your account preferences and system configuration
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {settingsSections.map((section) => (
          <Link key={section.title} href={section.href}>
            <Card className="card-stitch p-6 border-none hover:bg-surface-container transition-colors cursor-pointer group">
              <div className="flex items-start gap-4">
                <div className={`${section.color} bg-surface-container-high p-3 rounded-full group-hover:bg-surface-container-highest transition-colors`}>
                  <section.icon className="h-6 w-6" />
                </div>
                <div className="flex-1 space-y-1">
                  <h2 className="label-lg text-primary-text font-bold">
                    {section.title}
                  </h2>
                  <p className="body-md text-secondary-text">
                    {section.description}
                  </p>
                </div>
              </div>
            </Card>
          </Link>
        ))}
      </div>
    </div>
  )
}
