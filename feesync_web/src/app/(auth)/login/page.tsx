import { LoginForm } from '@/components/providers'

export const dynamic = 'force-dynamic'

export default function LoginPage() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-slate-100 to-slate-200 p-4">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-slate-900">FeeSync</h1>
          <p className="text-slate-600 mt-2">School Fee Management System</p>
        </div>
        <LoginForm />
      </div>
    </div>
  )
}
