import { LoginForm } from '@/components/providers'

export const dynamic = 'force-dynamic'

export default function LoginPage() {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-background p-4 relative overflow-hidden">
      {/* Background Decorative Elements */}
      <div className="absolute -top-[10%] -left-[10%] w-[40%] h-[40%] rounded-full bg-primary/10 blur-[120px] pointer-events-none" />
      <div className="absolute -bottom-[10%] -right-[10%] w-[40%] h-[40%] rounded-full bg-secondary/10 blur-[120px] pointer-events-none" />
      
      <div className="w-full max-w-md relative z-10">
        <div className="text-center mb-10">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-gradient-to-br from-primary to-secondary p-0.5 mb-6 shadow-xl shadow-primary/20">
            <div className="w-full h-full rounded-[14px] bg-background flex items-center justify-center">
              <span className="text-2xl font-black text-white">FS</span>
            </div>
          </div>
          <h1 className="text-4xl font-extrabold text-white tracking-tight">FeeSync</h1>
          <p className="text-muted mt-3 text-sm font-medium uppercase tracking-[0.2em]">Management Portal</p>
        </div>
        
        <div className="card-elevated border border-white/[0.05]">
          <LoginForm />
        </div>

        <p className="text-center mt-8 text-xs text-muted-foreground font-medium">
          &copy; {new Date().getFullYear()} FeeSync System. All rights reserved.
        </p>
      </div>
    </div>
  )
}
