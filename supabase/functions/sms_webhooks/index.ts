const TELNYX_PUBLIC_KEY = Deno.env.get('TELNYX_PUBLIC_KEY');
const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': '*',
};

interface TelnyxWebhookPayload {
  data: {
    event_type: string;
    id: string;
    occurred_at: string;
    payload: {
      id: string;
      to: Array<{ phone_number: string }>;
      from: { phone_number: string };
      text: string;
      completed_at?: string;
      errors?: Array<{ code: string; title: string; detail: string }>;
    };
  };
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const signature = req.headers.get('telnyx-signature-ed25519');
    const timestamp = req.headers.get('telnyx-timestamp');
    const body = await req.text();

    // Verify webhook signature (production implementation would use Ed25519)
    if (!signature || !timestamp) {
      console.error('Missing signature or timestamp');
      return new Response(
        JSON.stringify({ error: 'Missing webhook signature' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const payload: TelnyxWebhookPayload = JSON.parse(body);
    const { event_type, payload: eventPayload } = payload.data;

    // Log webhook event
    await fetch(`${SUPABASE_URL}/rest/v1/sms_webhook_events`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': SUPABASE_SERVICE_KEY!,
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      },
      body: JSON.stringify({
        provider: 'telnyx',
        event_type,
        provider_message_id: eventPayload.id,
        event_payload: payload.data,
        received_at: new Date().toISOString(),
      }),
    });

    // Route by event type
    switch (event_type) {
      case 'message.sent':
        await handleMessageSent(eventPayload);
        break;
      case 'message.delivered':
        await handleMessageDelivered(eventPayload);
        break;
      case 'message.failed':
        await handleMessageFailed(eventPayload);
        break;
      case 'message.finalized':
        await handleMessageFinalized(eventPayload);
        break;
      default:
        console.log(`Unhandled event type: ${event_type}`);
    }

    return new Response(
      JSON.stringify({ status: 'success', received_at: new Date().toISOString() }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Webhook processing error:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});

async function handleMessageSent(payload: any) {
  await updateDeliveryLog(payload.id, {
    delivery_status: 'sent',
    provider_message_id: payload.id,
  });
}

async function handleMessageDelivered(payload: any) {
  const deliveredAt = payload.completed_at || new Date().toISOString();
  
  await updateDeliveryLog(payload.id, {
    delivery_status: 'delivered',
    delivered_at: deliveredAt,
  });

  // Increment success counter
  await fetch(`${SUPABASE_URL}/rest/v1/provider_health_metrics`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': SUPABASE_SERVICE_KEY!,
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
    },
    body: JSON.stringify({
      provider_name: 'telnyx',
      is_healthy: true,
      latency_ms: 0,
      error_rate: 0,
      consecutive_failures: 0,
    }),
  });
}

async function handleMessageFailed(payload: any) {
  const errors = payload.errors || [];
  const errorCode = errors[0]?.code || 'unknown';
  const errorMessage = errors[0]?.detail || 'Message delivery failed';

  // Categorize failure type
  let failureType = 'unknown';
  if (['30001', '30003'].includes(errorCode)) {
    failureType = 'network_error';
  } else if (errorCode === '30004') {
    failureType = 'carrier_blocked';
  } else if (errorCode === '30007') {
    failureType = 'spam_detected';
  } else if (errorCode === '30008') {
    failureType = 'invalid_number';
  }

  await updateDeliveryLog(payload.id, {
    delivery_status: 'failed',
    error_message: errorMessage,
    metadata: { failure_type: failureType, error_code: errorCode },
  });

  // Check if we should trigger failover
  await checkFailoverThreshold();

  // Add to bounce list if permanent failure
  if (['carrier_blocked', 'invalid_number'].includes(failureType)) {
    const phoneNumber = payload.to?.[0]?.phone_number;
    if (phoneNumber) {
      await addToBounceList(phoneNumber, failureType, errorMessage);
    }
  }
}

async function handleMessageFinalized(payload: any) {
  // Final status update
  await updateDeliveryLog(payload.id, {
    delivery_status: payload.status || 'delivered',
  });
}

async function updateDeliveryLog(messageId: string, updates: any) {
  await fetch(
    `${SUPABASE_URL}/rest/v1/sms_delivery_log?provider_message_id=eq.${messageId}`,
    {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'apikey': SUPABASE_SERVICE_KEY!,
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      },
      body: JSON.stringify(updates),
    }
  );
}

async function checkFailoverThreshold() {
  // Check recent failures in last 5 minutes
  const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000).toISOString();
  
  const response = await fetch(
    `${SUPABASE_URL}/rest/v1/sms_delivery_log?provider_used=eq.telnyx&delivery_status=eq.failed&sent_at=gte.${fiveMinutesAgo}&select=count`,
    {
      headers: {
        'apikey': SUPABASE_SERVICE_KEY!,
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      },
    }
  );

  const data = await response.json();
  const failureCount = data[0]?.count || 0;

  // Trigger failover if more than 10 failures in 5 minutes
  if (failureCount > 10) {
    console.log(`Failover threshold exceeded: ${failureCount} failures`);
    // Failover logic would be triggered here via provider monitor
  }
}

async function addToBounceList(
  phoneNumber: string,
  bounceType: string,
  bounceReason: string
) {
  await fetch(`${SUPABASE_URL}/rest/v1/sms_bounce_list`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': SUPABASE_SERVICE_KEY!,
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      'Prefer': 'resolution=merge-duplicates',
    },
    body: JSON.stringify({
      phone_number: phoneNumber,
      bounce_type: bounceType === 'invalid_number' ? 'hard_bounce' : 'soft_bounce',
      bounce_reason: bounceReason,
      first_bounced_at: new Date().toISOString(),
      bounce_count: 1,
    }),
  });
}