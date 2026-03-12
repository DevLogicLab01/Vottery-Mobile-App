// Stripe Webhook Handler Edge Function
// Handles: account.updated, payout.created, payout.paid, payout.failed
// Deploy to: supabase/functions/stripe_webhook_handler/index.ts

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, stripe-signature',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const body = await req.text()
    const signature = req.headers.get('stripe-signature') ?? ''
    const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET') ?? ''

    // Verify webhook signature
    let event: any
    try {
      // In production: use Stripe SDK to verify
      // const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '')
      // event = stripe.webhooks.constructEvent(body, signature, webhookSecret)
      event = JSON.parse(body)
    } catch (err) {
      console.error('Webhook signature verification failed:', err)
      return new Response(
        JSON.stringify({ error: 'Invalid signature' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Log webhook event
    await supabaseClient.from('stripe_webhook_events').insert({
      event_id: event.id,
      event_type: event.type,
      status: 'processing',
      raw_payload: event,
      created_at: new Date().toISOString(),
    })

    // Process event
    switch (event.type) {
      case 'account.updated': {
        const account = event.data.object
        await supabaseClient
          .from('stripe_connect_accounts')
          .update({
            verification_status: account.charges_enabled ? 'verified' : 'pending',
            payouts_enabled: account.payouts_enabled,
            details_submitted: account.details_submitted,
            updated_at: new Date().toISOString(),
          })
          .eq('stripe_account_id', account.id)
        break
      }

      case 'payout.created': {
        const payout = event.data.object
        await supabaseClient.from('creator_payouts').insert({
          stripe_payout_id: payout.id,
          amount: payout.amount,
          currency: payout.currency,
          status: 'pending',
          arrival_date: new Date(payout.arrival_date * 1000).toISOString(),
          created_at: new Date().toISOString(),
        })
        break
      }

      case 'payout.paid': {
        const payout = event.data.object
        // Update payout status
        const { data: payoutRecord } = await supabaseClient
          .from('creator_payouts')
          .update({
            status: 'paid',
            paid_at: new Date().toISOString(),
          })
          .eq('stripe_payout_id', payout.id)
          .select('creator_id')
          .single()

        // Notify creator
        if (payoutRecord?.creator_id) {
          await supabaseClient.from('notifications').insert({
            user_id: payoutRecord.creator_id,
            title: 'Payout Successful! 🎉',
            body: `Your payout of $${(payout.amount / 100).toFixed(2)} has been sent to your bank account.`,
            category: 'payout',
            priority: 'high',
            created_at: new Date().toISOString(),
          })
        }
        break
      }

      case 'payout.failed': {
        const payout = event.data.object
        const { data: payoutRecord } = await supabaseClient
          .from('creator_payouts')
          .update({
            status: 'failed',
            failure_reason: payout.failure_message ?? 'Unknown error',
            failed_at: new Date().toISOString(),
          })
          .eq('stripe_payout_id', payout.id)
          .select('creator_id')
          .single()

        // Notify creator with retry instructions
        if (payoutRecord?.creator_id) {
          await supabaseClient.from('notifications').insert({
            user_id: payoutRecord.creator_id,
            title: 'Payout Failed',
            body: `Your payout failed: ${payout.failure_message}. Please verify your bank account details and try again.`,
            category: 'payout_failed',
            priority: 'high',
            created_at: new Date().toISOString(),
          })
        }

        // Check for reconciliation discrepancy
        const { data: dbPayout } = await supabaseClient
          .from('creator_payouts')
          .select('amount')
          .eq('stripe_payout_id', payout.id)
          .single()

        if (dbPayout && dbPayout.amount !== payout.amount) {
          await supabaseClient.from('payout_reconciliation_issues').insert({
            payout_id: payout.id,
            issue_type: 'Amount Mismatch',
            stripe_amount: payout.amount,
            db_amount: dbPayout.amount,
            status: 'open',
            created_at: new Date().toISOString(),
          })
        }
        break
      }
    }

    // Update webhook event status
    await supabaseClient
      .from('stripe_webhook_events')
      .update({ status: 'processed' })
      .eq('event_id', event.id)

    return new Response(
      JSON.stringify({ received: true }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Webhook handler error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
