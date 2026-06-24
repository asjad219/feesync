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
      throw new Error('Not authorized to delete staff')
    }

    const { targetUserId } = await req.json()

    if (!targetUserId) {
      throw new Error('Missing targetUserId')
    }
    
    if (targetUserId === user.id) {
        throw new Error('Cannot delete yourself')
    }

    // Verify target user belongs to the same account
    const { data: targetData, error: targetError } = await supabaseClient
      .from('users')
      .select('account_id')
      .eq('id', targetUserId)
      .single()
      
    if (targetError || !targetData || targetData.account_id !== callerData.account_id) {
        throw new Error('User not found or not in your account')
    }

    // Initialize Supabase Admin to bypass RLS and use auth admin API
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Soft delete target user in public.users (deactivate them)
    const { error: updateError } = await supabaseAdmin
      .from('users')
      .update({ is_active: false })
      .eq('id', targetUserId)

    if (updateError) throw updateError

    // Ban the auth user for 10 years to prevent them from logging back in
    const { error: authError } = await supabaseAdmin.auth.admin.updateUserById(
      targetUserId,
      { ban_duration: '87600h' }
    )

    if (authError) throw authError

    return new Response(
      JSON.stringify({ success: true, message: 'User deleted successfully' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})
