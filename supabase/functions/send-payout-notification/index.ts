import { serve } from "https://deno.land/std@0.192.0/http/server.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "*",
      },
    });
  }

  try {
    const { recipientEmail, payoutAmount, settlementId, eventType } = await req.json();

    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    if (!resendApiKey) {
      throw new Error("RESEND_API_KEY not configured");
    }

    let subject = "";
    let htmlContent = "";

    if (eventType === "scheduled") {
      subject = "Payout Scheduled - Vottery";
      htmlContent = `
        <h2>Your payout has been scheduled</h2>
        <p>Amount: $${payoutAmount.toFixed(2)}</p>
        <p>Settlement ID: ${settlementId}</p>
        <p>Your payout will be processed shortly.</p>
      `;
    } else if (eventType === "processing") {
      subject = "Payout Processing - Vottery";
      htmlContent = `
        <h2>Your payout is being processed</h2>
        <p>Amount: $${payoutAmount.toFixed(2)}</p>
        <p>Expected arrival: 2-7 business days</p>
      `;
    } else if (eventType === "completed") {
      subject = "Payout Completed - Vottery";
      htmlContent = `
        <h2>Your payout has been sent successfully!</h2>
        <p>Amount: $${payoutAmount.toFixed(2)}</p>
        <p>Settlement ID: ${settlementId}</p>
      `;
    } else if (eventType === "failed") {
      subject = "Payout Failed - Vottery";
      htmlContent = `
        <h2>Your payout could not be processed</h2>
        <p>Amount: $${payoutAmount.toFixed(2)}</p>
        <p>Please contact support or update your bank account details.</p>
      `;
    }

    const resendResponse = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${resendApiKey}`,
      },
      body: JSON.stringify({
        from: "onboarding@resend.dev",
        to: [recipientEmail],
        subject,
        html: htmlContent,
      }),
    });

    const resendData = await resendResponse.json();

    return new Response(
      JSON.stringify({
        success: true,
        emailId: resendData.id,
      }),
      {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({
        error: error.message,
      }),
      {
        status: 500,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  }
});