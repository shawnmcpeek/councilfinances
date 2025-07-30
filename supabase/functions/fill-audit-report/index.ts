import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { PDFDocument } from 'https://esm.sh/pdf-lib@1.17.1'

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
    // Validate request method
    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ error: 'Method Not Allowed' }),
        { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get request body
    const body = await req.json()

    // Validate required fields
    if (!body.period || !['January-June', 'July-December'].includes(body.period)) {
      return new Response(
        JSON.stringify({ error: 'Invalid period. Must be January-June or July-December' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    if (!body.year) {
      return new Response(
        JSON.stringify({ error: 'Year is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log('Audit report data received:', body)

    // Load the template PDF from the request body
    // The PDF template should be sent as base64 in the request
    if (!body.pdfTemplate) {
      throw new Error('PDF template is required')
    }
    
    const templateBytes = new Uint8Array(
      atob(body.pdfTemplate).split('').map(char => char.charCodeAt(0))
    )
    const pdfDoc = await PDFDocument.load(templateBytes)
    const form = pdfDoc.getForm()

    // Fill in the form fields
    const fieldMappings = {
      // Basic Info
      'Text1': body.council_number || '',
      'Text2': body.auditor_name || '',
      'Text3': body.year?.toString().slice(-2) || '',
      'Text4': body.organization_name || '',
      
      // Income Section
      'Text50': body.manual_income_1 || '',
      'Text51': body.membership_dues || '',
      'Text52': body.top_program_1_name || '',
      'Text53': body.top_program_1_amount || '',
      'Text54': body.top_program_2_name || '',
      'Text55': body.top_program_2_amount || '',
      'Text56': 'Other',
      'Text57': body.other_programs_amount || '',
      'Text58': body.total_income || '',
      'Text59': body.manual_income_2 || '',
      'Text60': body.net_income || '',
      
      // Interest and Per Capita
      'Text61': body.reserved_1 || '',
      'Text62': body.reserved_2 || '',
      'Text63': body.reserved_3 || '',
      'Text64': body.interest_earned || '',
      'Text65': body.total_interest || '',
      'Text66': body.supreme_per_capita || '',
      'Text67': body.state_per_capita || '',
      'Text68': body.other_council_programs || '',
      'Text69': body.manual_expense_1 || '',
      'Text70': body.manual_expense_2 || '',
      'Text71': body.total_expenses || '',
      'Text72': body.net_council || '',
      'Text73': body.net_council_verify || '',
      
      // Membership Section
      'Text74': body.manual_membership_1 || '',
      'Text75': body.manual_membership_2 || '',
      'Text76': body.manual_membership_3 || '',
      'Text77': body.membership_count || '',
      'Text78': body.membership_dues_total || '',
      'Text79': body.total_membership || '',
      'Text80': body.total_disbursements || '',
      'Text83': body.net_membership || '',
      
      // Disbursements Section
      'Text84': body.manual_disbursement_1 || '',
      'Text85': body.manual_disbursement_2 || '',
      'Text86': body.manual_disbursement_3 || '',
      'Text87': body.manual_disbursement_4 || '',
      'Text88': body.total_disbursements_verify || '',
      
      // Additional Fields
      'Text89': body.manual_field_1 || '',
      'Text90': body.manual_field_2 || '',
      'Text91': body.manual_field_3 || '',
      'Text92': body.manual_field_4 || '',
      'Text93': body.manual_field_5 || '',
      'Text95': body.manual_field_6 || '',
      'Text96': body.manual_field_7 || '',
      'Text97': body.manual_field_8 || '',
      'Text98': body.manual_field_9 || '',
      'Text99': body.manual_field_10 || '',
      'Text100': body.manual_field_11 || '',
      'Text101': body.manual_field_12 || '',
      'Text102': body.manual_field_13 || '',
      'Text103': body.total_disbursements_sum || '',
      'Text104': body.manual_field_14 || '',
      'Text105': body.manual_field_15 || '',
      'Text106': body.manual_field_16 || '',
      'Text107': body.manual_field_17 || '',
      'Text108': body.manual_field_18 || '',
      'Text109': body.manual_field_19 || '',
      'Text110': body.manual_field_20 || '',
    }

    // Fill each field
    for (const [fieldName, value] of Object.entries(fieldMappings)) {
      try {
        const field = form.getTextField(fieldName)
        if (field) {
          field.setText(value.toString())
        }
      } catch (error) {
        console.warn(`Field ${fieldName} not found in PDF template:`, error)
      }
    }

    // Generate the filled PDF
    const filledPdfBytes = await pdfDoc.save()
    
    // Return the PDF as a response
    return new Response(filledPdfBytes, {
      status: 200,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/pdf',
        'Content-Disposition': `attachment; filename="audit_report_${body.period.toLowerCase()}_${body.year}.pdf"`,
      },
    })

  } catch (error) {
    console.error('Error processing audit report:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}) 