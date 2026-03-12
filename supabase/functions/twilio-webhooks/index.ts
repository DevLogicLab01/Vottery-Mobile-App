const TWILIO_AUTH_TOKEN = Deno.env.get('TWILIO_AUTH_TOKEN');
const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-twilio-signature',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const signature = req.headers.get('x-twilio-signature');
    const contentType = req.headers.get('content-type');

    if (!contentType?.includes('application/x-www-form-urlencoded')) {
      return new Response(
        JSON.stringify({ error: 'Invalid content type' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Parse form-encoded body
    const formData = await req.formData();
    const webhookData: any = {};
    formData.forEach((value, key) => {
      webhookData[key] = value;
    });

    console.log('Received Twilio webhook:', webhookData.MessageStatus);

    // Store webhook event
    await storeWebhookEvent({
      provider: 'twilio',
      event_type: `message.${webhookData.MessageStatus}`,
      provider_message_id: webhookData.MessageSid,
      event_payload: webhookData,
      received_at: new Date().toISOString(),
    });

    // Route by message status
    switch (webhookData.MessageStatus) {
      case 'sent':
        await handleMessageSent(webhookData);
        break;
      case 'delivered':
        await handleMessageDelivered(webhookData);
        break;
      case 'failed':
      case 'undelivered':
        await handleMessageFailed(webhookData);
        break;
      default:
        console.log(`Unhandled status: ${webhookData.MessageStatus}`);
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

async function handleMessageSent(data: any) {
  await updateDeliveryLog(data.MessageSid, {
    delivery_status: 'sent',
    sent_at: new Date().toISOString(),
  });
}

async function handleMessageDelivered(data: any) {
  await updateDeliveryLog(data.MessageSid, {
    delivery_status: 'delivered',
    delivered_at: new Date().toISOString(),
  });

  await incrementProviderMetric('twilio', 'success');
}

async function handleMessageFailed(data: any) {
  const errorCode = data.ErrorCode || 'unknown';
  const errorMessage = data.ErrorMessage || 'Unknown error';

  await updateDeliveryLog(data.MessageSid, {
    delivery_status: 'failed',
    error_message: errorMessage,
    metadata: { error_code: errorCode },
  });

  // Check failure rate
  await checkFailoverThreshold('twilio');
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

async function incrementProviderMetric(provider: string, type: 'success' | 'failure') {
  console.log(`Incrementing ${type} counter for ${provider}`);
}

async function checkFailoverThreshold(provider: string) {
  try {
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

    if (failureCount > 10) {
      console.log(`⚠️ Twilio failover threshold exceeded: ${failureCount} failures`);
    }
  } catch (error) {
    console.error('Error checking failover threshold:', error);
  }
}