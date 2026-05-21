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
import { loginSchema, type LoginFormData } from '@/lib/validations/auth'
import { createClient } from '@/lib/supabase/client'

export function LoginForm() {
  const [showPassword, setShowPassword] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(false)
  const router = useRouter()
  const supabase = createClient()

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<LoginFormData>({
    resolver: zodResolver(loginSchema),
  })

  const onSubmit = async (data: LoginFormData) => {
    setIsLoading(true)
    setError(null)

    const { error } = await supabase.auth.signInWithPassword({
      email: data.email,
      password: data.password,
    })

    if (error) {
      setError(error.message)
      setIsLoading(false)
      return
    }

    router.push('/dashboard')
    router.refresh()
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
      <div className="space-y-1">
        <h2 className="text-2xl font-bold text-white">Sign in</h2>
        <p className="text-sm text-muted">
          Access your FeeSync account
        </p>
      </div>

      <div className="space-y-4">
        {error && (
          <div className="p-3 text-xs font-bold text-rose-400 bg-rose-500/10 border border-rose-500/20 rounded-xl">
            {error}
          </div>
        )}
        
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

        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <Label htmlFor="password" className="text-xs font-bold uppercase tracking-wider text-muted">Password</Label>
            <Link href="#" className="text-xs font-bold text-primary hover:text-primary/80 transition-colors">
              Forgot?
            </Link>
          </div>
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
      </div>

      <div className="pt-2 space-y-6">
        <Button type="submit" className="btn-primary-gradient w-full h-12 text-base" disabled={isLoading}>
          {isLoading ? (
            <Loader2 className="h-5 w-5 animate-spin" />
          ) : (
            'Sign In to Dashboard'
          )}
        </Button>
        
        <div className="relative">
          <div className="absolute inset-0 flex items-center">
            <span className="w-full border-t border-white/5" />
          </div>
          <div className="relative flex justify-center text-xs uppercase">
            <span className="bg-[#1e1f31] px-2 text-muted-foreground font-bold tracking-widest">or</span>
          </div>
        </div>

        <p className="text-sm text-center text-muted">
          New to FeeSync?{' '}
          <Link href="/signup" className="text-primary font-bold hover:underline">
            Create an account
          </Link>
        </p>
      </div>
    </form>
  )
}
