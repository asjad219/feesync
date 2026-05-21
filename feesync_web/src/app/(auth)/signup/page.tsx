'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { Eye, EyeOff, Loader2 } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { signupSchema, type SignupFormData } from '@/lib/validations/auth'
import { createClient } from '@/lib/supabase/client'

export default function SignupPage() {
  const [showPassword, setShowPassword] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(false)
  const router = useRouter()
  const supabase = createClient()

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<SignupFormData>({
    resolver: zodResolver(signupSchema),
  })

  const onSubmit = async (data: SignupFormData) => {
    setIsLoading(true)
    setError(null)

    const { data: authData, error: authError } = await supabase.auth.signUp({
      email: data.email,
      password: data.password,
      options: {
        data: {
          full_name: data.full_name,
          school_name: data.school_name,
        },
      },
    })

    if (authError) {
      setError(authError.message)
      setIsLoading(false)
      return
    }

    if (authData.user) {
      router.push('/login')
    }
  }

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-background p-4 relative overflow-hidden">
      {/* Background Decorative Elements */}
      <div className="absolute -top-[10%] -right-[10%] w-[40%] h-[40%] rounded-full bg-primary/10 blur-[120px] pointer-events-none" />
      <div className="absolute -bottom-[10%] -left-[10%] w-[40%] h-[40%] rounded-full bg-secondary/10 blur-[120px] pointer-events-none" />

      <div className="w-full max-w-lg relative z-10 py-12">
        <div className="text-center mb-10">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-gradient-to-br from-primary to-secondary p-0.5 mb-6 shadow-xl shadow-primary/20">
            <div className="w-full h-full rounded-[14px] bg-background flex items-center justify-center">
              <span className="text-2xl font-black text-white">FS</span>
            </div>
          </div>
          <h1 className="text-4xl font-extrabold text-white tracking-tight">Create Account</h1>
          <p className="text-muted mt-3 text-sm font-medium uppercase tracking-[0.2em]">Join the FeeSync Platform</p>
        </div>

        <div className="card-elevated border border-white/[0.05]">
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
            <div className="space-y-1">
              <h2 className="text-2xl font-bold text-white">Register</h2>
              <p className="text-sm text-muted">
                Enter your professional details below
              </p>
            </div>

            <div className="space-y-4">
              {error && (
                <div className="p-3 text-xs font-bold text-rose-400 bg-rose-500/10 border border-rose-500/20 rounded-xl">
                  {error}
                </div>
              )}

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="full_name" className="text-xs font-bold uppercase tracking-wider text-muted">Full Name</Label>
                  <Input
                    id="full_name"
                    placeholder="John Doe"
                    className="input-stitch h-12"
                    {...register('full_name')}
                  />
                  {errors.full_name && (
                    <p className="text-xs font-medium text-rose-400 mt-1">{errors.full_name.message as string}</p>
                  )}
                </div>
                <div className="space-y-2">
                  <Label htmlFor="school_name" className="text-xs font-bold uppercase tracking-wider text-muted">School Name</Label>
                  <Input
                    id="school_name"
                    placeholder="Greenwood Academy"
                    className="input-stitch h-12"
                    {...register('school_name')}
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="email" className="text-xs font-bold uppercase tracking-wider text-muted">Email Address</Label>
                <Input
                  id="email"
                  type="email"
                  placeholder="admin@school.com"
                  className="input-stitch h-12"
                  {...register('email')}
                />
                {errors.email && (
                  <p className="text-xs font-medium text-rose-400 mt-1">{errors.email.message as string}</p>
                )}
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="password" className="text-xs font-bold uppercase tracking-wider text-muted">Password</Label>
                  <div className="relative">
                    <Input
                      id="password"
                      type={showPassword ? 'text' : 'password'}
                      placeholder="••••••••"
                      className="input-stitch h-12 pr-12"
                      {...register('password')}
                    />
                    <button
                      type="button"
                      className="absolute right-0 top-0 h-full px-4 text-muted hover:text-white transition-colors"
                      onClick={() => setShowPassword(!showPassword)}
                    >
                      {showPassword ? (
                        <EyeOff className="h-5 w-5" />
                      ) : (
                        <Eye className="h-5 w-5" />
                      )}
                    </button>
                  </div>
                  {errors.password && (
                    <p className="text-xs font-medium text-rose-400 mt-1">{errors.password.message as string}</p>
                  )}
                </div>
                <div className="space-y-2">
                  <Label htmlFor="confirmPassword" className="text-xs font-bold uppercase tracking-wider text-muted">Confirm</Label>
                  <Input
                    id="confirmPassword"
                    type="password"
                    placeholder="••••••••"
                    className="input-stitch h-12"
                    {...register('confirmPassword')}
                  />
                  {errors.confirmPassword && (
                    <p className="text-xs font-medium text-rose-400 mt-1">{errors.confirmPassword.message as string}</p>
                  )}
                </div>
              </div>
            </div>

            <div className="pt-2 space-y-6">
              <Button type="submit" className="btn-primary-gradient w-full h-12 text-base" disabled={isLoading}>
                {isLoading ? (
                  <Loader2 className="h-5 w-5 animate-spin" />
                ) : (
                  'Create System Account'
                )}
              </Button>

              <p className="text-sm text-center text-muted">
                Already have an account?{' '}
                <Link href="/login" className="text-primary font-bold hover:underline">
                  Sign in
                </Link>
              </p>
            </div>
          </form>
        </div>
      </div>
    </div>
  )
}
