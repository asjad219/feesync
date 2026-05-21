import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { Sidebar } from '@/components/layout/sidebar'

export const dynamic = 'force-dynamic'

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    redirect('/login')
  }

  // Get user profile from server
  const { data: profile } = await supabase
    .from('users')
    .select('full_name, email')
    .eq('id', user.id)
    .single()

  return (
    <div className="flex h-screen">
      <Sidebar
        userName={profile?.full_name}
        userEmail={profile?.email || user.email}
      />
      <main className="flex-1 overflow-y-auto surface-lowest">
        {children}
      </main>
    </div>
  )
}
