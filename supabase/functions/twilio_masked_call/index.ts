// Twilio Masked Calling Edge Function for Gold-Taxi
// Masks customer and driver real numbers during active rides

declare const Deno: any;

// @ts-ignore
import { serve } from "https://deno.land/std@0.198.0/http/server.ts"

const TWILIO_ACCOUNT_SID = Deno.env.get("TWILIO_ACCOUNT_SID") || ""
const TWILIO_AUTH_TOKEN = Deno.env.get("TWILIO_AUTH_TOKEN") || ""
const TWILIO_PROXY_SERVICE_SID = Deno.env.get("TWILIO_PROXY_SERVICE_SID") || ""
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || ""
const SUPABASE_KEY = Deno.env.get("SUPABASE_KEY") || ""

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'OPTIONS, POST',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { rideId, callerId, receiverId } = await req.json()

    if (!rideId || !callerId || !receiverId) {
      return new Response(
        JSON.stringify({ error: 'Missing rideId, callerId, or receiverId' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 1. Fetch phone numbers of caller and receiver from profiles
    const response = await fetch(`${SUPABASE_URL}/rest/v1/profiles?id=in.("${callerId}","${receiverId}")`, {
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`,
      }
    })

    const profiles = await response.json()
    const callerProfile = profiles.find((p: any) => p.id === callerId)
    const receiverProfile = profiles.find((p: any) => p.id === receiverId)

    const callerPhone = callerProfile?.phone || "+421900111222"
    const receiverPhone = receiverProfile?.phone || "+421900333444"

    // 2. If Twilio keys are configured, create a Proxy Session & Participant
    let proxyNumber = "+421944987654" // Default mock Twilio proxy number
    let isMock = true

    if (TWILIO_ACCOUNT_SID && TWILIO_AUTH_TOKEN && TWILIO_PROXY_SERVICE_SID) {
      isMock = false
      try {
        // Create Proxy Session for this ride
        const sessionRes = await fetch(
          `https://proxy.twilio.com/v1/Services/${TWILIO_PROXY_SERVICE_SID}/Sessions`,
          {
            method: 'POST',
            headers: {
              'Authorization': `Basic ${btoa(`${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}`)}`,
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: new URLSearchParams({
              UniqueName: `ride_${rideId}`,
            }),
          }
        )

        const session = await sessionRes.json()
        const sessionSid = session.sid

        if (sessionSid) {
          // Add Caller Participant
          await fetch(
            `https://proxy.twilio.com/v1/Services/${TWILIO_PROXY_SERVICE_SID}/Sessions/${sessionSid}/Participants`,
            {
              method: 'POST',
              headers: {
                'Authorization': `Basic ${btoa(`${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}`)}`,
                'Content-Type': 'application/x-www-form-urlencoded',
              },
              body: new URLSearchParams({
                Identifier: callerPhone,
                FriendlyName: 'Caller',
              }),
            }
          )

          // Add Receiver Participant
          const receiverParticipantRes = await fetch(
            `https://proxy.twilio.com/v1/Services/${TWILIO_PROXY_SERVICE_SID}/Sessions/${sessionSid}/Participants`,
            {
              method: 'POST',
              headers: {
                'Authorization': `Basic ${btoa(`${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}`)}`,
                'Content-Type': 'application/x-www-form-urlencoded',
              },
              body: new URLSearchParams({
                Identifier: receiverPhone,
                FriendlyName: 'Receiver',
              }),
            }
          )

          const participant = await receiverParticipantRes.json()
          if (participant.proxy_identifier) {
            proxyNumber = participant.proxy_identifier
          }
        }
      } catch (err) {
        console.error("Failed to connect to Twilio, falling back to mock: ", err)
        isMock = true
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        proxyNumber: proxyNumber,
        isMock: isMock,
        message: 'Masked call session initialized',
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: (error as any).message || 'Failed to initialize masked call' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
