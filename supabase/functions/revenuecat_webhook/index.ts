import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const REVENUECAT_WEBHOOK_SECRET = Deno.env.get('REVENUE_CAT_WEBHOOK_SECRET');

serve(async (req: Request) => {
  // Validate authorization
  const authHeader = req.headers.get("Authorization");
  if (!REVENUECAT_WEBHOOK_SECRET || authHeader !== `Bearer ${REVENUECAT_WEBHOOK_SECRET}`) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), { 
      status: 401, 
      headers: { "Content-Type": "application/json" } 
    });
  }

  try {
    const payload = await req.json();
    const event = payload.event;
    
    if (!event) {
      return new Response(JSON.stringify({ error: "No event found" }), { status: 400 });
    }

    const eventId = event.id;
    const appUserId = event.app_user_id; // UUID in our case
    const eventType = event.type;
    const entitlementId = event.entitlement_ids ? event.entitlement_ids[0] : null; 
    const expirationAtMs = event.expiration_at_ms;

    // Create a Supabase client with the Auth context of the function
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // Check for idempotency
    const { data: existingSub, error: fetchError } = await supabaseClient
      .from('subscriptions')
      .select('revenuecat_event_id, status, plan_type')
      .eq('user_id', appUserId)
      .maybeSingle();

    if (existingSub && existingSub.revenuecat_event_id === eventId) {
      // Already processed this event
      return new Response(JSON.stringify({ success: true, message: "Already processed" }), { status: 200 });
    }

    // Map RC event type to plan action
    let newStatus = existingSub?.status || 'active';
    
    switch (eventType) {
      case 'INITIAL_PURCHASE':
      case 'RENEWAL':
      case 'PRODUCT_CHANGE':
      case 'RESTORATION':
        newStatus = 'active';
        break;
      case 'CANCELLATION':
        newStatus = 'cancelled';
        break;
      case 'EXPIRATION':
      case 'GRACE_PERIOD_EXPIRED':
        newStatus = 'inactive';
        break;
      case 'BILLING_ISSUE':
      case 'GRACE_PERIOD_STARTED':
        newStatus = 'past_due';
        break;
      default:
        // Other events ignored for state change
        break;
    }

    // Map RC entitlement -> FeeSync plan tier
    let planType = 'free';
    if (newStatus === 'active' || newStatus === 'cancelled' || newStatus === 'past_due') {
      if (entitlementId === 'institute') planType = 'institute';
      else if (entitlementId === 'growth') planType = 'growth';
      else if (entitlementId === 'starter') planType = 'starter';
      else if (existingSub?.plan_type && existingSub.plan_type !== 'free') {
         planType = existingSub.plan_type;
      }
    }

    // Expiry Date logic
    let validUntil = null;
    if (expirationAtMs) {
      validUntil = new Date(parseInt(expirationAtMs)).toISOString();
    }

    // Upsert logic using service_role
    if (newStatus === 'inactive' || planType === 'free') {
      // Reset to free
      await supabaseClient.rpc('upsert_subscription', {
        p_owner_id: appUserId,
        p_plan_tier: 'free',
        p_billing_cycle: 'monthly',
        p_valid_until: null
      });
      
      // Update RC fields and status explicitly
      await supabaseClient.from('subscriptions').update({
        status: newStatus,
        revenuecat_event_id: eventId,
        revenuecat_entitlement_id: null,
        revenuecat_customer_id: appUserId
      }).eq('user_id', appUserId);
      
    } else {
      // Paid plan logic
      await supabaseClient.rpc('upsert_subscription', {
        p_owner_id: appUserId,
        p_plan_tier: planType,
        p_billing_cycle: event.product_id?.includes('annual') ? 'annual' : 'monthly',
        p_valid_until: validUntil
      });
      
      // Update RC fields and status explicitly
      await supabaseClient.from('subscriptions').update({
        status: newStatus,
        revenuecat_event_id: eventId,
        revenuecat_entitlement_id: entitlementId,
        revenuecat_customer_id: appUserId
      }).eq('user_id', appUserId);
    }

    return new Response(JSON.stringify({ success: true }), { 
      status: 200,
      headers: { "Content-Type": "application/json" }
    });

  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 });
  }
});
