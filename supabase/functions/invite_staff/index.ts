import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) throw new Error('Missing Authorization header')

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    // Check if user is admin
    const { data: userData, error: userError } = await supabaseClient.auth.getUser()
    if (userError || !userData?.user) throw new Error('Not authenticated')
    const user = userData.user

    const { data: callerData, error: callerError } = await supabaseClient
      .from('users')
      .select('role, account_id')
      .eq('id', user.id)
      .single()

    if (callerError || !callerData || callerData.role !== 'admin') {
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

    // Find the original owner of the account to check subscription
    const { data: adminUsers } = await supabaseAdmin
      .from('users')
      .select('id')
      .eq('account_id', callerData.account_id)
      .eq('role', 'admin')
      .order('created_at', { ascending: true })
      .limit(1)

    const ownerId = adminUsers?.[0]?.id || user.id

    // Check staff limit
    const { data: subData } = await supabaseAdmin
      .from('subscriptions')
      .select('max_staff')
      .eq('owner_id', ownerId)
      .maybeSingle()

    // Assuming subData might not exist if they haven't set it up, default to 2.
    const maxStaff = subData?.max_staff ?? 2

    const { count, error: countError } = await supabaseAdmin
      .from('users')
      .select('*', { count: 'exact', head: true })
      .eq('account_id', callerData.account_id)
      .in('role', ['admin', 'accountant'])
      .eq('is_active', true)

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

    if (authError || !authData?.user) {
      throw authError || new Error('Failed to invite user')
    }
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
