import { serve } from "https://deno.land/std@0.192.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

serve(async (req) => {
  // ✅ CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "*"
      }
    });
  }

  try {
    const { notification_id, creator_id, document_id, notification_type, channel, payload } = await req.json();

    // Get Resend API key
    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    if (!resendApiKey) {
      throw new Error("RESEND_API_KEY not configured");
    }

    // Get Supabase credentials
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error("Supabase credentials not configured");
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Get creator details
    const { data: creator, error: creatorError } = await supabase
      .from('user_profiles')
      .select('email, full_name')
      .eq('id', creator_id)
      .single();

    if (creatorError || !creator) {
      throw new Error(`Failed to fetch creator: ${creatorError?.message}`);
    }

    // Get notification template
    const { data: template, error: templateError } = await supabase
      .from('tax_notification_templates')
      .select('subject_template, body_template')
      .eq('notification_type', notification_type)
      .eq('channel', channel)
      .eq('is_active', true)
      .maybeSingle();

    if (templateError) {
      throw new Error(`Failed to fetch template: ${templateError.message}`);
    }

    // Build email content
    let subject = template?.subject_template || `Tax Compliance Notification - ${notification_type}`;
    let body = template?.body_template || `<p>Tax compliance notification for document ${document_id}</p>`;

    // Replace template variables
    if (payload) {
      Object.keys(payload).forEach(key => {
        const value = payload[key];
        subject = subject.replace(new RegExp(`{{${key}}}`, 'g'), value);
        body = body.replace(new RegExp(`{{${key}}}`, 'g'), value);
      });
    }

    // Send email via Resend
    const resendResponse = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${resendApiKey}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        from: "onboarding@resend.dev",
        to: creator.email,
        subject: subject,
        html: body
      })
    });

    if (!resendResponse.ok) {
      const errorData = await resendResponse.json();
      throw new Error(`Resend API error: ${JSON.stringify(errorData)}`);
    }

    const resendData = await resendResponse.json();

    // Mark notification as processed
    await supabase.rpc('mark_tax_notification_processed', {
      p_queue_id: notification_id,
      p_external_id: resendData.id,
      p_status: 'sent'
    });

    return new Response(JSON.stringify({
      success: true,
      email_id: resendData.id,
      notification_id: notification_id
    }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      }
    });
  } catch (error) {
    console.error('Send tax notification error:', error);
    return new Response(JSON.stringify({
      error: error.message
    }), {
      status: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      }
    });
  }
});