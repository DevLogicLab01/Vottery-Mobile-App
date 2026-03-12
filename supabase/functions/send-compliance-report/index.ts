import { serve } from "https://deno.land/std@0.192.0/http/server.ts";

serve(async (req) => {
  // CORS preflight
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
    const { report_id, report_type, report_data, recipients } = await req.json();

    // Get Resend API key from environment
    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    if (!resendApiKey) {
      throw new Error("RESEND_API_KEY not configured");
    }

    // Build email content
    const emailSubject = `Compliance Report: ${report_type} - ${new Date().toLocaleDateString()}`;
    const emailHtml = `
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .header { background: #4F46E5; color: white; padding: 20px; text-align: center; }
    .content { padding: 20px; }
    .summary { background: #F3F4F6; padding: 15px; border-radius: 8px; margin: 20px 0; }
    .metric { display: inline-block; margin: 10px 20px; }
    .metric-value { font-size: 24px; font-weight: bold; color: #4F46E5; }
    .metric-label { font-size: 14px; color: #6B7280; }
    .footer { background: #F9FAFB; padding: 20px; text-align: center; font-size: 12px; color: #6B7280; }
  </style>
</head>
<body>
  <div class="header">
    <h1>Vottery Compliance Report</h1>
    <p>${report_type} Compliance Report</p>
  </div>
  <div class="content">
    <h2>Executive Summary</h2>
    <div class="summary">
      <div class="metric">
        <div class="metric-value">${report_data.executive_summary.total_events}</div>
        <div class="metric-label">Total Events</div>
      </div>
      <div class="metric">
        <div class="metric-value">${report_data.executive_summary.compliance_status}</div>
        <div class="metric-label">Compliance Status</div>
      </div>
      <div class="metric">
        <div class="metric-value">${report_data.executive_summary.critical_findings}</div>
        <div class="metric-label">Critical Findings</div>
      </div>
    </div>
    <h3>Reporting Period</h3>
    <p><strong>Start:</strong> ${new Date(report_data.reporting_period.start).toLocaleDateString()}</p>
    <p><strong>End:</strong> ${new Date(report_data.reporting_period.end).toLocaleDateString()}</p>
    <h3>Report Details</h3>
    <p>The full compliance report has been generated and is available in your Vottery dashboard.</p>
    <p><strong>Report ID:</strong> ${report_id}</p>
    <p>Please log in to your account to view the complete report with detailed findings and recommendations.</p>
  </div>
  <div class="footer">
    <p>This is an automated compliance report from Vottery.</p>
    <p>Generated on ${new Date().toLocaleString()}</p>
  </div>
</body>
</html>
`;

    // Send email via Resend
    const resendResponse = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${resendApiKey}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        from: "onboarding@resend.dev",
        to: recipients,
        subject: emailSubject,
        html: emailHtml
      })
    });

    if (!resendResponse.ok) {
      const error = await resendResponse.text();
      throw new Error(`Resend API error: ${error}`);
    }

    const resendData = await resendResponse.json();

    return new Response(JSON.stringify({
      success: true,
      email_id: resendData.id,
      message: "Compliance report sent successfully"
    }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      }
    });
  } catch (error) {
    return new Response(JSON.stringify({
      success: false,
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
