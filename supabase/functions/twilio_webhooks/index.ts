const TWILIO_AUTH_TOKEN = Deno.env.get('TWILIO_AUTH_TOKEN');
const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': '*',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    // Parse form-encoded data (Twilio sends form data, not JSON)
    const formData = await req.formData();
    const data: Record<string, string> = {};
    
    for (const [key, value] of formData.entries()) {
      data[key] = value.toString();
    }

    const {
      MessageSid,
      MessageStatus,
      To,
      From,
      Body,
      ErrorCode,
      ErrorMessage,
    } = data;

    // Log webhook event
    await fetch(`${SUPABASE_URL}/rest/v1/sms_webhook_events`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': SUPABASE_SERVICE_KEY!,
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      },
      body: JSON.stringify({
        provider: 'twilio',
        event_type: `message.${MessageStatus}`,
        provider_message_id: MessageSid,
        event_payload: data,
        received_at: new Date().toISOString(),
      }),
    });

    // Update delivery status based on Twilio status
    let deliveryStatus = 'pending';
    switch (MessageStatus) {
      case 'sent':
        deliveryStatus = 'sent';
        break;
      case 'delivered':
        deliveryStatus = 'delivered';
        await handleTwilioDelivered(MessageSid);
        break;
      case 'failed':
      case 'undelivered':
        deliveryStatus = 'failed';
        await handleTwilioFailed(MessageSid, ErrorCode, ErrorMessage, To);
        break;
      default:
        deliveryStatus = MessageStatus;
    }

    await updateTwilioDeliveryLog(MessageSid, {
      delivery_status: deliveryStatus,
      error_message: ErrorMessage || null,
    });

    return new Response(
      JSON.stringify({ status: 'success', received_at: new Date().toISOString() }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Twilio webhook processing error:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});

async function handleTwilioDelivered(messageSid: string) {
  await updateTwilioDeliveryLog(messageSid, {
    delivered_at: new Date().toISOString(),
  });

  // Log health metric
  await fetch(`${SUPABASE_URL}/rest/v1/provider_health_metrics`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': SUPABASE_SERVICE_KEY!,
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
    },
    body: JSON.stringify({
      provider_name: 'twilio',
      is_healthy: true,
      latency_ms: 0,
      error_rate: 0,
      consecutive_failures: 0,
    }),
  });
}

async function handleTwilioFailed(
  messageSid: string,
  errorCode: string,
  errorMessage: string,
  phoneNumber: string
) {
  // Categorize failure
  let failureType = 'unknown';
  if (['30001', '30003', '30005'].includes(errorCode)) {
    failureType = 'network_error';
  } else if (['30004', '30006'].includes(errorCode)) {
    failureType = 'carrier_blocked';
  } else if (errorCode === '30007') {
    failureType = 'spam_detected';
  } else if (['30008', '21211'].includes(errorCode)) {
    failureType = 'invalid_number';
  }

  // Add to bounce list if permanent failure
  if (['carrier_blocked', 'invalid_number'].includes(failureType)) {
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
        bounce_type: failureType === 'invalid_number' ? 'hard_bounce' : 'soft_bounce',
        bounce_reason: errorMessage,
        first_bounced_at: new Date().toISOString(),
        bounce_count: 1,
      }),
    });
  }
}

async function updateTwilioDeliveryLog(messageSid: string, updates: any) {
  await fetch(
    `${SUPABASE_URL}/rest/v1/sms_delivery_log?provider_message_id=eq.${messageSid}`,
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