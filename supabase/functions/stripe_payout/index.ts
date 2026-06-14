// Stripe Connect Payout Function for Gold-Taxi
// This edge function handles payout requests to driver bank accounts

import { serve } from "https://deno.land/std@0.198.0/http/server.ts"
import { Stripe } from "https://esm.sh/@stripe/stripe-js@v2.2.0"

// Configuration
const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY") || ""
const STRIPE_WEBHOOK_SECRET = Deno.env.get("STRIPE_WEBHOOK_SECRET") || ""
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || ""
const SUPABASE_KEY = Deno.env.get("SUPABASE_KEY") || ""

// Stripe client
const stripe = Stripe(STRIPE_SECRET_KEY)

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'OPTIONS, POST, GET',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Parse request body
    const { driverId, amount, stripeAccountId, bankAccountLast4 } = await req.json()

    // Validate inputs
    if (!driverId || !amount || !stripeAccountId) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: driverId, amount, stripeAccountId' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Amount must be positive and at least 1.00
    const amountInCents = Math.round(parseFloat(amount) * 100)
    if (amountInCents < 100) {
      return new Response(
        JSON.stringify({ error: 'Minimum payout amount is €1.00' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Create Transfer to connected account (Stripe Connect)
    const transfer = await stripe.transfers.create({
      amount: amountInCents,
      currency: 'eur',
      destination: stripeAccountId,
      transfer_group: `goldtaxi_payout_${driverId}_${Date.now()}`,
      metadata: {
        driver_id: driverId,
        goldtaxi_function: 'stripe_payout',
      },
    })

    // Record payout in Supabase
    const supabaseResponse = await fetch(`${SUPABASE_URL}/rest/v1/payouts`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`,
        'Prefer': 'return=representation',
      },
      body: JSON.stringify({
        driver_id: driverId,
        amount: amount,
        stripe_payout_id: transfer.id,
        bank_account_last4: bankAccountLast4 || null,
        status: 'in_transit',
      }),
    })

    const supabaseData = await supabaseResponse.json()

    return new Response(
      JSON.stringify({
        success: true,
        payoutId: supabaseData[0]?.id,
        stripeTransferId: transfer.id,
        status: 'in_transit',
        message: 'Payout initiated successfully',
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Payout error:', error)
    
    return new Response(
      JSON.stringify({
        error: error.message || 'Failed to process payout',
        details: error.toString(),
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

// Helper to parse float safely
function parseFloat(value: any): number {
  const num = Number(value)
  if (isNaN(num)) {
    throw new Error(`Invalid number: ${value}`)
  }
  return num
}
