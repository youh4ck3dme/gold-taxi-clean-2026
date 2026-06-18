// @ts-nocheck
// Stripe Webhook handler for Gold-Taxi Connect Payouts and Capabilities updates
// Processes webhooks from Stripe Connect and updates payout status / driver bank accounts

import { serve } from "https://deno.land/std@0.198.0/http/server.ts"
import Stripe from "https://esm.sh/stripe@14.10.0"

// Configuration
const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY") || ""
const STRIPE_WEBHOOK_SECRET = Deno.env.get("STRIPE_WEBHOOK_SECRET") || ""
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || ""
const SUPABASE_KEY = Deno.env.get("SUPABASE_KEY") || ""

const stripe = new Stripe(STRIPE_SECRET_KEY, {
  apiVersion: "2023-10-16",
  httpClient: Stripe.createFetchHttpClient(),
})

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, stripe-signature',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const signature = req.headers.get("stripe-signature")
    if (!signature) {
      return new Response(
        JSON.stringify({ error: "Missing stripe-signature header" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      )
    }

    const body = await req.text()
    let event

    if (STRIPE_WEBHOOK_SECRET) {
      try {
        event = await stripe.webhooks.constructEventAsync(
          body,
          signature,
          STRIPE_WEBHOOK_SECRET
        )
      } catch (err: any) {
        console.error(`Webhook signature verification failed: ${err.message}`)
        return new Response(
          JSON.stringify({ error: `Webhook signature verification failed: ${err.message}` }),
          { status: 400, headers: { "Content-Type": "application/json" } }
        )
      }
    } else {
      // In local dev/testing without webhook secret, parse body directly
      event = JSON.parse(body)
    }

    console.log(`Received Stripe event: ${event.type}`)

    if (
      event.type === 'payout.paid' ||
      event.type === 'payout.failed' ||
      event.type === 'payout.canceled'
    ) {
      const payout = event.data.object
      const stripePayoutId = payout.id
      let newStatus = 'pending'

      if (event.type === 'payout.paid') {
        newStatus = 'paid'
      } else if (event.type === 'payout.failed') {
        newStatus = 'failed'
      } else if (event.type === 'payout.canceled') {
        newStatus = 'cancelled'
      }

      // Update payout in Supabase matching stripe_payout_id
      const response = await fetch(
        `${SUPABASE_URL}/rest/v1/payouts?stripe_payout_id=eq.${stripePayoutId}`,
        {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'apikey': SUPABASE_KEY,
            'Authorization': `Bearer ${SUPABASE_KEY}`,
            'Prefer': 'return=representation',
          },
          body: JSON.stringify({
            status: newStatus,
            completed_at: event.type === 'payout.paid' ? new Date().toISOString() : null,
          }),
        }
      )

      if (!response.ok) {
        throw new Error(`Failed to update payout status: ${await response.text()}`)
      }

      console.log(`Updated payout ${stripePayoutId} to ${newStatus}`)
    } else if (event.type === 'capability.updated') {
      // Handle Connect account capabilities verification status
      const capability = event.data.object
      const connectedAccountId = event.account

      if (capability.id === 'transfers' || capability.id === 'card_payments') {
        const isEnabled = capability.status === 'active'
        console.log(`Capability ${capability.id} status is ${capability.status} for Connect Account ${connectedAccountId}`)

        // Retrieve driver from driver_bank_accounts matching connectedAccountId
        const getDriverResponse = await fetch(
          `${SUPABASE_URL}/rest/v1/driver_bank_accounts?stripe_account_id=eq.${connectedAccountId}`,
          {
            method: 'GET',
            headers: {
              'Content-Type': 'application/json',
              'apikey': SUPABASE_KEY,
              'Authorization': `Bearer ${SUPABASE_KEY}`,
              'Prefer': 'return=representation',
            },
          }
        )

        if (getDriverResponse.ok) {
          const bankAccounts = await getDriverResponse.json()
          if (bankAccounts && bankAccounts.length > 0) {
            const currentAccount = bankAccounts[0]
            
            // If payout/transfer capability is now active, update status to verified and enable payout
            const updateResponse = await fetch(
              `${SUPABASE_URL}/rest/v1/driver_bank_accounts?id=eq.${currentAccount.id}`,
              {
                method: 'PATCH',
                headers: {
                  'Content-Type': 'application/json',
                  'apikey': SUPABASE_KEY,
                  'Authorization': `Bearer ${SUPABASE_KEY}`,
                  'Prefer': 'return=representation',
                },
                body: JSON.stringify({
                  status: isEnabled ? 'verified' : 'pending',
                  payout_enabled: isEnabled,
                }),
              }
            )

            if (updateResponse.ok) {
              console.log(`Updated driver bank account ${currentAccount.id} verification status`)
            }
          }
        }
      }
    }

    return new Response(JSON.stringify({ received: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    })
  } catch (error: any) {
    console.error("Webhook processing error:", error)
    return new Response(
      JSON.stringify({ error: error.message || 'Failed to process webhook' }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    )
  }
})
