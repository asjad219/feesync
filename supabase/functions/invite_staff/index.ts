import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    // Check if user is admin
    const { data: { user } } = await supabaseClient.auth.getUser()
    if (!user) throw new Error('Not authenticated')

    const { data: callerData, error: callerError } = await supabaseClient
      .from('users')
      .select('role, account_id')
      .eq('id', user.id)
      .single()

    if (callerError || callerData.role !== 'admin') {
      throw new Error('Not authorized to invite staff')
    }

    const { email, fullName, role, permissions } = await req.json()

    if (!email || !fullName || !role) {
      throw new Error('Missing required fields')
    }

    // Initialize Supabase Admin to bypass RLS and use auth admin API
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Check staff limit
    const { data: subData, error: subError } = await supabaseAdmin
      .from('subscriptions')
      .select('max_staff')
      .eq('owner_id', user.id)
      .single()

    // Assuming subData might not exist if they haven't set it up, default to 1.
    const maxStaff = subData?.max_staff ?? 1

    const { count, error: countError } = await supabaseAdmin
      .from('users')
      .select('*', { count: 'exact', head: true })
      .eq('account_id', callerData.account_id)

    if (countError) throw countError

    if (maxStaff !== -1 && (count ?? 0) >= maxStaff) {
      throw new Error('Staff limit reached for your subscription plan. Please upgrade to invite more staff.')
    }

    // Invite user via auth admin API
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.inviteUserByEmail(
      email,
      { 
        data: { 
          full_name: fullName, 
          onboarding_complete: true, 
          needs_password_set: true 
        },
        redirectTo: 'feesync://reset-password'
      }
    )

    if (authError) throw authError
    const newUserId = authData.user.id

    // Insert into public.users
    const { error: insertError } = await supabaseAdmin
      .from('users')
      .insert({
        id: newUserId,
        account_id: callerData.account_id,
        email: email,
        full_name: fullName,
        role: role,
        permissions: permissions || {},
        is_active: true
      })

    if (insertError) {
      // Rollback auth user creation if public.users fails
      await supabaseAdmin.auth.admin.deleteUser(newUserId)
      throw insertError
    }

    return new Response(
      JSON.stringify({ success: true, message: 'User invited successfully' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})
