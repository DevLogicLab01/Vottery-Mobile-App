import { serve } from "https://deno.land/std@0.192.0/http/server.ts";
import Stripe from "https://esm.sh/stripe@14.21.0";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") || "");
const supabase = createClient(
  Deno.env.get("SUPABASE_URL") || "",
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || ""
);

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
    // Get all creators eligible for payout
    const { data: eligibleCreators, error: fetchError } = await supabase
      .from("creator_accounts")
      .select("creator_user_id, pending_balance, stripe_account_id, tier_level")
      .gte("pending_balance", 5.00)
      .eq("stripe_account_status", "active");

    if (fetchError) throw fetchError;

    const processedPayouts = [];
    const failedPayouts = [];

    for (const creator of eligibleCreators || []) {
      try {
        // Get tier config
        const { data: tierConfig } = await supabase
          .from("payout_schedule_config")
          .select("minimum_threshold, schedule_frequency, auto_enabled")
          .eq("tier_level", creator.tier_level || "bronze")
          .single();

        if (!tierConfig?.auto_enabled) continue;
        if (creator.pending_balance < tierConfig.minimum_threshold) continue;

        // Get creator profile for tax info
        const { data: profile } = await supabase
          .from("user_profiles")
          .select("country_code, email")
          .eq("id", creator.creator_user_id)
          .single();

        // Calculate tax withholding
        const { data: taxRate } = await supabase.rpc(
          "get_tax_withholding_rate",
          { p_country_code: profile?.country_code || "US" }
        );

        const settlementAmount = creator.pending_balance;
        const withholdingRate = taxRate || 0.0;
        const withholdingAmount = settlementAmount * withholdingRate;
        const netPayout = settlementAmount - withholdingAmount;

        // Create Stripe transfer
        const transfer = await stripe.transfers.create({
          amount: Math.round(netPayout * 100),
          currency: "usd",
          destination: creator.stripe_account_id,
          description: `Automated Settlement - ${new Date().toISOString().split("T")[0]}`,
        });

        // Create settlement record
        const { data: settlement } = await supabase
          .from("settlement_records")
          .insert({
            creator_user_id: creator.creator_user_id,
            settlement_period_start: new Date(
              Date.now() - 7 * 24 * 60 * 60 * 1000
            ).toISOString(),
            settlement_period_end: new Date().toISOString(),
            total_earnings: settlementAmount,
            platform_fees: 0,
            payment_processing_fees: 0,
            net_amount: netPayout,
            currency: "USD",
            tax_withheld: withholdingAmount,
            status: "processing",
            stripe_transfer_id: transfer.id,
          })
          .select()
          .single();

        // Record tax withholding
        if (withholdingAmount > 0) {
          await supabase.from("tax_withholding_records").insert({
            creator_user_id: creator.creator_user_id,
            settlement_id: settlement.settlement_id,
            withholding_amount: withholdingAmount,
            tax_rate: withholdingRate,
            country_code: profile?.country_code || "US",
          });
        }

        // Update creator account
        await supabase
          .from("creator_accounts")
          .update({
            pending_balance: 0,
            lifetime_payouts:
              (creator.lifetime_payouts || 0) + settlementAmount,
          })
          .eq("creator_user_id", creator.creator_user_id);

        // Send notification via Resend
        await fetch(Deno.env.get("SUPABASE_URL") + "/functions/v1/send-payout-notification", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${Deno.env.get("SUPABASE_ANON_KEY")}`,
          },
          body: JSON.stringify({
            recipientEmail: profile?.email,
            payoutAmount: netPayout,
            settlementId: settlement.settlement_id,
            eventType: "processing",
          }),
        });

        processedPayouts.push({
          creator_id: creator.creator_user_id,
          amount: netPayout,
          transfer_id: transfer.id,
        });
      } catch (error) {
        console.error(`Payout failed for creator ${creator.creator_user_id}:`, error);
        failedPayouts.push({
          creator_id: creator.creator_user_id,
          error: error.message,
        });
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        processed: processedPayouts.length,
        failed: failedPayouts.length,
        processedPayouts,
        failedPayouts,
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