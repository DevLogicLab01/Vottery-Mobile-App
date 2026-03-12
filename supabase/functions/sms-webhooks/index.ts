const TELNYX_PUBLIC_KEY = Deno.env.get('TELNYX_PUBLIC_KEY');
const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-telnyx-signature-ed25519, x-telnyx-timestamp',
};

interface TelnyxWebhookPayload {
  data: {
    event_type: string;
    id: string;
    occurred_at: string;
    payload: {
      id: string;
      to: Array<{ phone_number: string; status: string }>;
      from: { phone_number: string };
      text?: string;
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
    const signature = req.headers.get('x-telnyx-signature-ed25519');
    const timestamp = req.headers.get('x-telnyx-timestamp');
    const rawBody = await req.text();

    // Verify webhook signature
    if (!verifyTelnyxSignature(signature, timestamp, rawBody)) {
      console.error('Invalid Telnyx webhook signature');
      return new Response(
        JSON.stringify({ error: 'Invalid signature' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const webhookData: TelnyxWebhookPayload = JSON.parse(rawBody);
    const { event_type, payload, occurred_at } = webhookData.data;

    console.log(`Received Telnyx webhook: ${event_type}`);

    // Store webhook event
    await storeWebhookEvent({
      provider: 'telnyx',
      event_type,
      provider_message_id: payload.id,
      event_payload: webhookData.data,
      received_at: occurred_at,
    });

    // Route by event type
    switch (event_type) {
      case 'message.sent':
        await handleMessageSent(payload);
        break;
      case 'message.delivered':
        await handleMessageDelivered(payload);
        break;
      case 'message.failed':
        await handleMessageFailed(payload);
        break;
      case 'message.received':
        console.log('Inbound message received (no action required)');
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

function verifyTelnyxSignature(
  signature: string | null,
  timestamp: string | null,
  body: string
): boolean {
  // In production, implement Ed25519 signature verification
  // For now, basic validation
  if (!signature || !timestamp) {
    return false;
  }
  // TODO: Implement actual Ed25519 verification with TELNYX_PUBLIC_KEY
  return true;
}

async function storeWebhookEvent(event: any) {
  try {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/sms_webhook_events`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': SUPABASE_SERVICE_KEY!,
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      },
      body: JSON.stringify(event),
    });

    if (!response.ok) {
      console.error('Failed to store webhook event:', await response.text());
    }
  } catch (error) {
    console.error('Error storing webhook event:', error);
  }
}

async function handleMessageSent(payload: any) {
  await updateDeliveryLog(payload.id, {
    delivery_status: 'sent',
    sent_at: new Date().toISOString(),
  });
}

async function handleMessageDelivered(payload: any) {
  const deliveredAt = payload.completed_at || new Date().toISOString();
  
  await updateDeliveryLog(payload.id, {
    delivery_status: 'delivered',
    delivered_at: deliveredAt,
  });

  // Increment success counter
  await incrementProviderMetric('telnyx', 'success');
}

async function handleMessageFailed(payload: any) {
  const errors = payload.errors || [];
  const errorCode = errors[0]?.code || 'unknown';
  const errorMessage = errors[0]?.detail || 'Unknown error';

  // Categorize failure type
  const failureType = categorizeFailure(errorCode);

  await updateDeliveryLog(payload.id, {
    delivery_status: 'failed',
    error_message: errorMessage,
    metadata: { failure_type: failureType, error_code: errorCode },
  });

  // Check if bounced
  if (failureType === 'hard_bounce' || failureType === 'carrier_blocked') {
    await addToBounceList(payload.to[0]?.phone_number, failureType, errorMessage);
  }

  // Check failure rate for failover
  await checkFailoverThreshold('telnyx');
}

function categorizeFailure(errorCode: string): string {
  const bounceErrors = ['30001', '30003', '30004', '30007'];
  const networkErrors = ['30005', '30006'];
  const spamErrors = ['30008', '30009'];

  if (bounceErrors.includes(errorCode)) return 'hard_bounce';
  if (networkErrors.includes(errorCode)) return 'network_error';
  if (spamErrors.includes(errorCode)) return 'spam_detected';
  return 'unknown';
}

async function updateDeliveryLog(messageId: string, updates: any) {
  try {
    const response = await fetch(
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

    if (!response.ok) {
      console.error('Failed to update delivery log:', await response.text());
    }
  } catch (error) {
    console.error('Error updating delivery log:', error);
  }
}

async function addToBounceList(phoneNumber: string, bounceType: string, reason: string) {
  try {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/sms_bounce_list`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': SUPABASE_SERVICE_KEY!,
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        'Prefer': 'resolution=merge-duplicates',
      },
      body: JSON.stringify({
        phone_number: phoneNumber,
        bounce_type: bounceType,
        bounce_reason: reason,
        first_bounced_at: new Date().toISOString(),
        bounce_count: 1,
      }),
    });

    if (!response.ok) {
      console.error('Failed to add to bounce list:', await response.text());
    }
  } catch (error) {
    console.error('Error adding to bounce list:', error);
  }
}

async function incrementProviderMetric(provider: string, type: 'success' | 'failure') {
  // This would update provider_health_metrics table
  console.log(`Incrementing ${type} counter for ${provider}`);
}

async function checkFailoverThreshold(provider: string) {
  try {
    // Get recent failures in last 5 minutes
    const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000).toISOString();
    const response = await fetch(
      `${SUPABASE_URL}/rest/v1/sms_delivery_log?provider_used=eq.${provider}&delivery_status=eq.failed&sent_at=gte.${fiveMinutesAgo}&select=count`,
      {
        headers: {
          'apikey': SUPABASE_SERVICE_KEY!,
          'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        },
      }
    );

    const data = await response.json();
    const failureCount = data[0]?.count || 0;

    // Trigger failover if > 10 failures in 5 minutes
    if (failureCount > 10) {
      console.log(`⚠️ Failover threshold exceeded: ${failureCount} failures`);
      await triggerFailover(provider);
    }
  } catch (error) {
    console.error('Error checking failover threshold:', error);
  }
}

async function triggerFailover(fromProvider: string) {
  const toProvider = fromProvider === 'telnyx' ? 'twilio' : 'telnyx';
  
  try {
    // Update provider state
    await fetch(`${SUPABASE_URL}/rest/v1/sms_provider_state`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': SUPABASE_SERVICE_KEY!,
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      },
      body: JSON.stringify({
        current_provider: toProvider,
        previous_provider: fromProvider,
        switch_reason: 'Automatic failover: High failure rate detected',
        is_manual_override: false,
      }),
    });

    // Log failover event
    await fetch(`${SUPABASE_URL}/rest/v1/provider_failover_log`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': SUPABASE_SERVICE_KEY!,
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      },
      body: JSON.stringify({
        from_provider: fromProvider,
        to_provider: toProvider,
        failover_reason: 'High failure rate detected (>10 failures in 5 minutes)',
        triggered_by: 'automatic',
        confidence_score: 0.95,
      }),
    });

    console.log(`✅ Failover triggered: ${fromProvider} → ${toProvider}`);
  } catch (error) {
    console.error('Error triggering failover:', error);
  }
}