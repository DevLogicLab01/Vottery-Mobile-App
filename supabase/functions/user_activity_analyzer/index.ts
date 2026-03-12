// User Activity Analyzer Edge Function
// Analyzes user_activity_patterns to determine optimal notification windows
// Stores results in user_notification_preferences table

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
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { user_id } = await req.json()

    // Query user sessions to analyze activity patterns
    const { data: sessions } = await supabaseClient
      .from('user_sessions')
      .select('started_at, ended_at, session_duration_seconds')
      .eq('user_id', user_id)
      .gte('started_at', new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString())
      .order('started_at', { ascending: false })
      .limit(200)

    // Aggregate activity by hour
    const activityByHour: Record<number, number> = {}
    for (let h = 0; h < 24; h++) activityByHour[h] = 0

    if (sessions && sessions.length > 0) {
      for (const session of sessions) {
        const hour = new Date(session.started_at).getHours()
        const weight = session.session_duration_seconds ?? 60
        activityByHour[hour] += weight
      }
    } else {
      // Default pattern: evening hours
      activityByHour[18] = 300
      activityByHour[19] = 400
      activityByHour[20] = 350
      activityByHour[21] = 250
      activityByHour[12] = 200
    }

    // Calculate engagement probability per hour
    const totalActivity = Object.values(activityByHour).reduce((a, b) => a + b, 0)
    const engagementByHour: Record<number, number> = {}
    for (const [hour, activity] of Object.entries(activityByHour)) {
      engagementByHour[parseInt(hour)] = totalActivity > 0 ? activity / totalActivity : 0
    }

    // Identify top 3 optimal notification windows
    const sortedHours = Object.entries(engagementByHour)
      .sort(([, a], [, b]) => b - a)
      .slice(0, 3)
      .map(([hour]) => parseInt(hour))

    // Get user timezone
    const { data: profile } = await supabaseClient
      .from('user_profiles')
      .select('timezone')
      .eq('id', user_id)
      .single()

    const timezone = profile?.timezone ?? 'UTC'

    // Store in user_notification_preferences
    await supabaseClient
      .from('user_notification_preferences')
      .upsert({
        user_id,
        optimal_hours: sortedHours,
        timezone,
        engagement_by_hour: engagementByHour,
        last_analyzed_at: new Date().toISOString(),
        total_sessions_analyzed: sessions?.length ?? 0,
      }, { onConflict: 'user_id' })

    return new Response(
      JSON.stringify({
        success: true,
        optimal_hours: sortedHours,
        timezone,
        engagement_by_hour: engagementByHour,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('User activity analyzer error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
