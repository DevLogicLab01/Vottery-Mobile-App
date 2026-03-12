import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface WebhookPayload {
  event_type: 'pool_created' | 'prediction_submitted' | 'pool_resolved' | 'leaderboard_updated' | 'countdown_reminder'
  pool_id?: string
  election_id?: string
  election_title?: string
  user_id?: string
  vp_amount?: number
  accuracy_breakdown?: Record<string, number>
  rank?: number
  pool_name?: string
  minutes_until_close?: number
  leaderboard_data?: Array<{ user_id: string; rank: number; score: number }>
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const resendApiKey = Deno.env.get('RESEND_API_KEY') ?? ''
    const telnyxApiKey = Deno.env.get('TELNYX_API_KEY') ?? ''

    const supabase = createClient(supabaseUrl, supabaseServiceKey)
    const payload: WebhookPayload = await req.json()

    console.log('Prediction pool webhook received:', payload.event_type)

    switch (payload.event_type) {
      case 'pool_created':
        await handlePoolCreated(supabase, payload, resendApiKey, telnyxApiKey)
        break
      case 'prediction_submitted':
        await handlePredictionSubmitted(supabase, payload)
        break
      case 'pool_resolved':
        await handlePoolResolved(supabase, payload, resendApiKey, telnyxApiKey)
        break
      case 'leaderboard_updated':
        await handleLeaderboardUpdated(supabase, payload)
        break
      case 'countdown_reminder':
        await handleCountdownReminder(supabase, payload, resendApiKey, telnyxApiKey)
        break
    }

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error('Webhook error:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

async function handlePoolCreated(
  supabase: any,
  payload: WebhookPayload,
  resendApiKey: string,
  telnyxApiKey: string
) {
  const { pool_id, election_title } = payload
  if (!pool_id) return

  // Get all users who should be notified (opted in)
  const { data: preferences } = await supabase
    .from('user_notification_preferences')
    .select('user_id, notification_channels, prediction_pool_notifications_enabled')
    .eq('prediction_pool_notifications_enabled', true)

  if (!preferences?.length) return

  const message = `New prediction pool created for "${election_title || 'an election'}"! Make your prediction now.`

  for (const pref of preferences) {
    const channels = pref.notification_channels as Record<string, boolean> ?? {}

    // Push notification via Supabase Realtime
    if (channels.push_notification !== false) {
      await supabase.from('user_notifications').insert({
        user_id: pref.user_id,
        type: 'prediction_pool_created',
        title: 'New Prediction Pool',
        message,
        data: { pool_id, election_title },
        read: false,
        created_at: new Date().toISOString(),
      })
    }

    // Email notification
    if (channels.email && resendApiKey) {
      const { data: user } = await supabase
        .from('profiles')
        .select('email, full_name')
        .eq('id', pref.user_id)
        .single()

      if (user?.email) {
        await sendEmail(resendApiKey, {
          to: user.email,
          subject: `New Prediction Pool: ${election_title}`,
          html: `<p>Hi ${user.full_name || 'Voter'},</p><p>${message}</p><p><a href="https://vottery2205.builtwithrocket.new">Make your prediction now</a></p>`,
        })
      }
    }
  }
}

async function handlePredictionSubmitted(supabase: any, payload: WebhookPayload) {
  const { user_id, pool_id } = payload
  if (!user_id) return

  // Confirm submission to user
  await supabase.from('user_notifications').insert({
    user_id,
    type: 'prediction_confirmed',
    title: 'Prediction Locked In!',
    message: 'Your prediction has been submitted. Good luck!',
    data: { pool_id },
    read: false,
    created_at: new Date().toISOString(),
  })
}

async function handlePoolResolved(
  supabase: any,
  payload: WebhookPayload,
  resendApiKey: string,
  telnyxApiKey: string
) {
  const { pool_id, election_title, vp_amount, accuracy_breakdown, user_id } = payload
  if (!pool_id) return

  // Get all participants of this pool
  const { data: participants } = await supabase
    .from('election_predictions')
    .select('user_id, brier_score, vp_earned')
    .eq('pool_id', pool_id)

  if (!participants?.length) return

  for (const participant of participants) {
    const earned = participant.vp_earned ?? 0
    const score = participant.brier_score ?? 0.5
    const message = earned > 0
      ? `Prediction pool resolved! You earned ${earned} VP with a Brier score of ${score.toFixed(3)}.`
      : `Prediction pool resolved. Your Brier score: ${score.toFixed(3)}. Better luck next time!`

    // Check preferences
    const { data: pref } = await supabase
      .from('user_notification_preferences')
      .select('*')
      .eq('user_id', participant.user_id)
      .maybeSingle()

    if (pref?.prediction_pool_notifications_enabled !== false) {
      await supabase.from('user_notifications').insert({
        user_id: participant.user_id,
        type: 'prediction_resolved',
        title: 'Prediction Pool Resolved!',
        message,
        data: { pool_id, vp_earned: earned, brier_score: score, election_title },
        read: false,
        created_at: new Date().toISOString(),
      })

      // SMS for high earners
      if (earned > 100 && pref?.notification_channels?.sms && telnyxApiKey) {
        const { data: profile } = await supabase
          .from('profiles')
          .select('phone')
          .eq('id', participant.user_id)
          .single()

        if (profile?.phone) {
          await sendSms(telnyxApiKey, profile.phone, message)
        }
      }
    }
  }
}

async function handleLeaderboardUpdated(supabase: any, payload: WebhookPayload) {
  const { pool_id, pool_name, leaderboard_data } = payload
  if (!leaderboard_data?.length) return

  for (const entry of leaderboard_data) {
    // Only notify significant rank improvements (top 10)
    if (entry.rank > 10) continue

    const { data: pref } = await supabase
      .from('user_notification_preferences')
      .select('leaderboard_alerts_enabled, notification_channels')
      .eq('user_id', entry.user_id)
      .maybeSingle()

    if (pref?.leaderboard_alerts_enabled !== false) {
      await supabase.from('user_notifications').insert({
        user_id: entry.user_id,
        type: 'leaderboard_rank_change',
        title: `You're #${entry.rank}!`,
        message: `You moved up to #${entry.rank} in ${pool_name || 'the prediction pool'}!`,
        data: { pool_id, rank: entry.rank, score: entry.score },
        read: false,
        created_at: new Date().toISOString(),
      })
    }
  }
}

async function handleCountdownReminder(
  supabase: any,
  payload: WebhookPayload,
  resendApiKey: string,
  telnyxApiKey: string
) {
  const { pool_id, election_title, minutes_until_close } = payload
  if (!pool_id) return

  // Get users who haven't predicted yet
  const { data: poolParticipants } = await supabase
    .from('election_predictions')
    .select('user_id')
    .eq('pool_id', pool_id)

  const predictedUserIds = new Set((poolParticipants ?? []).map((p: any) => p.user_id))

  // Get users with countdown reminders enabled
  const { data: preferences } = await supabase
    .from('user_notification_preferences')
    .select('user_id, notification_channels, countdown_reminders_enabled')
    .eq('countdown_reminders_enabled', true)

  const message = `Election closes in ${minutes_until_close} minutes - lock in your prediction for "${election_title}"!`

  for (const pref of preferences ?? []) {
    if (predictedUserIds.has(pref.user_id)) continue // Already predicted

    await supabase.from('user_notifications').insert({
      user_id: pref.user_id,
      type: 'prediction_countdown',
      title: `${minutes_until_close}min Remaining!`,
      message,
      data: { pool_id, minutes_until_close, election_title },
      read: false,
      created_at: new Date().toISOString(),
    })
  }
}

async function sendEmail(
  apiKey: string,
  opts: { to: string; subject: string; html: string }
) {
  try {
    await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: 'Vottery <notifications@vottery2205.builtwithrocket.new>',
        to: opts.to,
        subject: opts.subject,
        html: opts.html,
      }),
    })
  } catch (e) {
    console.error('Email send error:', e)
  }
}

async function sendSms(apiKey: string, to: string, message: string) {
  try {
    await fetch('https://api.telnyx.com/v2/messages', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: '+18005551234',
        to,
        text: message,
      }),
    })
  } catch (e) {
    console.error('SMS send error:', e)
  }
}
