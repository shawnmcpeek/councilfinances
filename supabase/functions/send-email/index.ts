import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Get request body
    const { to, subject, body, requestId } = await req.json()

    // Validate required fields
    if (!to || !subject || !body || !requestId) {
      throw new Error('Missing required fields: to, subject, body, requestId')
    }

    // Log the email attempt
    console.log(`Attempting to send email to ${to} for request ${requestId}`)

    // For now, we'll use a simple email service integration
    // In production, you would integrate with SendGrid, AWS SES, or similar
    const emailResult = await sendEmailViaService(to, subject, body)

    // Log the email notification
    await supabaseClient
      .from('email_notifications')
      .insert({
        id: `${requestId}_${Date.now()}`,
        request_id: requestId,
        role_email: to,
        notification_type: 'reimbursement_approval',
        status: emailResult.success ? 'sent' : 'failed',
        sent_at: new Date().toISOString(),
      })

    return new Response(
      JSON.stringify({ 
        success: emailResult.success, 
        message: emailResult.message 
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: emailResult.success ? 200 : 500,
      }
    )

  } catch (error) {
    console.error('Error in send-email function:', error)
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message 
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    )
  }
})

// Email service integration function
async function sendEmailViaService(to: string, subject: string, body: string) {
  try {
    // This is where you would integrate with your email service
    // Examples:
    
    // SendGrid
    // const response = await fetch('https://api.sendgrid.com/v3/mail/send', {
    //   method: 'POST',
    //   headers: {
    //     'Authorization': `Bearer ${Deno.env.get('SENDGRID_API_KEY')}`,
    //     'Content-Type': 'application/json',
    //   },
    //   body: JSON.stringify({
    //     personalizations: [{ to: [{ email: to }] }],
    //     from: { email: 'noreply@yourdomain.com' },
    //     subject: subject,
    //     content: [{ type: 'text/plain', value: body }],
    //   }),
    // })

    // AWS SES
    // const response = await fetch('https://email.us-east-1.amazonaws.com', {
    //   method: 'POST',
    //   headers: {
    //     'Authorization': `AWS4-HMAC-SHA256 Credential=${Deno.env.get('AWS_ACCESS_KEY_ID')}`,
    //     'Content-Type': 'application/x-www-form-urlencoded',
    //   },
    //   body: `Action=SendEmail&Source=noreply@yourdomain.com&Destination.ToAddresses.member.1=${to}&Message.Subject.Data=${encodeURIComponent(subject)}&Message.Body.Text.Data=${encodeURIComponent(body)}`,
    // })

    // For now, we'll simulate a successful email send
    // In production, replace this with actual email service integration
    console.log(`Email would be sent to ${to}:`)
    console.log(`Subject: ${subject}`)
    console.log(`Body: ${body}`)

    // Simulate network delay
    await new Promise(resolve => setTimeout(resolve, 100))

    return {
      success: true,
      message: 'Email sent successfully (simulated)'
    }

  } catch (error) {
    console.error('Email service error:', error)
    return {
      success: false,
      message: `Email service error: ${error.message}`
    }
  }
} 