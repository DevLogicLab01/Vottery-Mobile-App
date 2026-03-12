import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.87.1'
import Stripe from 'https://esm.sh/stripe@14.21.0?target=deno'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

declare const Deno: {
  env: {
    get(key: string): string | undefined
  }
}

type ParticipationFeeTransaction = {
  id: string
  user_id: string
  amount: number
  payment_intent_id: string | null
  status: string
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed' }),
      { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
  const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return new Response(
      JSON.stringify({ error: 'Unauthorized' }),
      { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }

  try {
    const authClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: {
        headers: {
          Authorization: authHeader,
        },
      },
    })

    const {
      data: { user },
      error: userError,
    } = await authClient.auth.getUser()

    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey)

    const { data: profile, error: profileError } = await supabaseAdmin
      .from('user_profiles')
      .select('role')
      .eq('id', user.id)
      .single()

    if (profileError || !profile || !['admin', 'manager'].includes(profile.role)) {
      return new Response(
        JSON.stringify({ error: 'Forbidden' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const { electionId, reason } = await req.json()

    if (!electionId || typeof electionId !== 'string') {
      return new Response(
        JSON.stringify({ error: 'electionId is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const stripeSecret = Deno.env.get('STRIPE_SECRET_KEY') ?? ''
    if (!stripeSecret) {
      return new Response(
        JSON.stringify({ error: 'Stripe secret key is not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const stripe = new Stripe(stripeSecret, {
      apiVersion: '2023-10-16',
    })

    const { data: election, error: electionError } = await supabaseAdmin
      .from('elections')
      .select('id')
      .eq('id', electionId)
      .single()

    if (electionError || !election) {
      return new Response(
        JSON.stringify({ error: 'Election not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const { data: participationFees, error: feesError } = await supabaseAdmin
      .from('participation_fee_transactions')
      .select('id, user_id, amount, payment_intent_id, status')
      .eq('election_id', electionId)
      .eq('status', 'completed') as unknown as { data: ParticipationFeeTransaction[] | null; error: Error | null }

    if (feesError) {
      throw feesError
    }

    const transactions: ParticipationFeeTransaction[] = participationFees ?? []

    if (transactions.length === 0) {
      return new Response(
        JSON.stringify({
          electionId,
          message: 'No completed participation fee transactions to refund',
          refunded_count: 0,
          refunded_total: 0,
          stripe: { total: 0, successes: [], failures: [], skipped: [] },
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const skipped: any[] = []
    const stripeSuccesses: any[] = []
    const stripeFailures: any[] = []

    for (const tx of transactions) {
      if (!tx.payment_intent_id) {
        skipped.push({
          participation_fee_transaction_id: tx.id,
          reason: 'Missing payment_intent_id',
        })
        continue
      }

      try {
        const refund = await stripe.refunds.create({
          payment_intent: tx.payment_intent_id,
          amount: Math.round(Number(tx.amount) * 100),
          metadata: {
            election_id: electionId,
            participation_fee_transaction_id: tx.id,
            reason: reason || 'election_canceled_or_failed',
          },
        })

        stripeSuccesses.push({
          participation_fee_transaction_id: tx.id,
          stripe_refund_id: refund.id,
          amount: tx.amount,
        })
      } catch (err: any) {
        stripeFailures.push({
          participation_fee_transaction_id: tx.id,
          amount: tx.amount,
          error: err?.message ?? 'Unknown Stripe refund error',
        })
      }
    }

    const { data: rpcResult, error: rpcError } = await supabaseAdmin.rpc(
      'refund_participation_fees_for_election',
      { p_election_id: electionId },
    )

    if (rpcError) {
      throw rpcError
    }

    return new Response(
      JSON.stringify({
        electionId,
        db_result: rpcResult,
        stripe: {
          total: transactions.length,
          successes: stripeSuccesses,
          failures: stripeFailures,
          skipped,
        },
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error?.message ?? 'Unexpected error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }
})

