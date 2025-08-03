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
    
    // Determine template type based on period
    const templateType = body.period === 'January-June' ? 'june' : 'december'

    console.log('Audit report data received:', body)
    console.log('Text60 value from body:', body.cash_on_hand_end_period)

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

    // Fill in the form fields based on template type
    let fieldMappings = {}
    
    if (templateType === 'december') {
      // December template field mappings (Text1, Text2, etc.)
      fieldMappings = {
        // Basic Info
        'Text1': body.organization_name || '',
        'Text2': body.organization_city || '',
        'Text3': body.year?.toString().slice(-2) || '',
        'Text4': body.organization_jurisdiction || '',
        
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
        'Text60': body.cash_on_hand_end_period || '',
        
        // Treasurer Section
        'Text61': body.treasurer_cash_beginning || '',
        'Text62': body.treasurer_received_financial_secretary || '',
        'Text63': body.treasurer_transfers_from_savings || '',
        'Text64': body.treasurer_interest_earned || '',
        'Text65': body.treasurer_total_receipts || '',
        'Text66': body.treasurer_supreme_per_capita || '',
        'Text67': body.treasurer_state_per_capita || '',
        'Text68': Math.abs(parseFloat(body.treasurer_general_council_expenses || '0')).toString(),
        'Text69': body.treasurer_transfers_to_savings || '',
        'Text70': body.treasurer_miscellaneous || '',
        'Text71': body.treasurer_total_disbursements || '',
        'Text72': body.treasurer_net_balance || '',
        'Text73': body.net_council_verify || '',
        
                 // Membership Section
         'Text74': body.manual_membership_1 || '',
         'Text75': body.manual_membership_2 || '',
         'Text76': body.manual_membership_3 || '',
         'Text77': body.membership_count || '',
         'Text78': body.membership_dues_total || '',
         'Text79': body.total_membership || '',
         'Text80': body.total_disbursements_sum || '',
         // Note: Text81 and Text82 don't exist in December template
         'Text83': body.net_membership || '',
        
        // Disbursements Section
        'Text84': body.manual_disbursement_1 || '',
        'Text85': body.manual_disbursement_2 || '',
        'Text86': body.manual_disbursement_3 || '',
        'Text87': body.total_assets || '',
        'Text88': body.total_disbursements_verify || '',
        
        // Additional Fields
        'Text89': body.manual_field_1 || '',
        'Text90': body.manual_field_2 || '',
        'Text91': body.manual_field_3 || '',
        'Text92': body.manual_field_4 || '',
                 'Text93': body.manual_field_5 || '',
         // Note: Text94 doesn't exist in December template
         'Text95': body.manual_field_6 || '',
        'Text96': body.manual_field_7 || '',
        'Text97': body.manual_field_8 || '',
        'Text98': body.manual_field_9 || '',
        'Text99': body.manual_field_10 || '',
        'Text100': body.manual_field_11 || '',
        'Text101': body.manual_field_12 || '',
                 'Text102': body.manual_field_13 || '',
         'Text103': body.total_liabilities || '',
         // Note: Text81, Text82, Text94 don't exist in December template
         'Text104': '', // No data from app
         'Text105': '', // No data from app
         'Text106': '', // No data from app
         'Text107': '', // No data from app
         'Text108': '', // No data from app
         'Text109': '', // No data from app
         'Text110': '', // No data from app
      }
         } else {
       // June template field mappings - using position-based mapping from comparison
       // These mappings are based on exact field position comparison between June and December templates
       // Only mapping the fields that are actually used in the audit reports
       fieldMappings = {
         // Basic Info
         'Text341': body.year?.toString().slice(-2) || '',
         'Text342': body.organization_name || '',
         'Text343': body.organization_city || '',
         'Text344': body.organization_jurisdiction || '',
         
         // Income Section - these correspond to Text50-Text60 in December
         'Text391': body.manual_income_1 || '',
         'Text392': body.membership_dues || '',
         'Text393': body.top_program_1_name || '',
         'Text394': body.top_program_1_amount || '',
         'Text395': body.top_program_2_name || '',
         'Text396': body.top_program_2_amount || '',
         'Text397': 'Other',
         'Text398': body.other_programs_amount || '',
         'Text399': body.total_income || '',
         'Text400': body.manual_income_2 || '',
         'Text402': body.cash_on_hand_end_period || '',
         
         // Treasurer Section - these correspond to Text61-Text73 in December
         'Text403': body.treasurer_cash_beginning || '',
         'Text404': body.treasurer_received_financial_secretary || '',
         'Text405': body.treasurer_transfers_from_savings || '',
         'Text406': body.treasurer_interest_earned || '',
         'Text407': body.treasurer_total_receipts || '',
         'Text408': body.treasurer_supreme_per_capita || '',
         'Text409': body.treasurer_state_per_capita || '',
         'Text410': Math.abs(parseFloat(body.treasurer_general_council_expenses || '0')).toString(),
         'Text411': body.treasurer_transfers_to_savings || '',
         'Text412': body.treasurer_miscellaneous || '',
         'Text413': body.treasurer_total_disbursements || '',
         'Text414': body.treasurer_net_balance || '',
         'Text415': body.net_council_verify || '',
         
         // Membership Section - these correspond to Text74-Text83 in December
         'Text416': body.manual_membership_1 || '',
         'Text417': body.manual_membership_2 || '',
         'Text418': body.manual_membership_3 || '',
         'Text422': body.membership_count || '',
         'Text423': body.membership_dues_total || '',
         'Text424': body.total_membership || '',
         'Text425': body.total_disbursements_sum || '',
         'Text426': body.net_membership || '',
         
         // Disbursements Section - these correspond to Text84-Text88 in December
         'Text427': body.manual_disbursement_1 || '',
         'Text428': body.manual_disbursement_2 || '',
         'Text429': body.manual_disbursement_3 || '',
         'Text430': body.total_assets || '',
         'Text431': body.total_disbursements_verify || '',
         
         // Additional Fields - these correspond to Text89-Text103 in December
         'Text432': body.manual_field_1 || '',
         'Text433': body.manual_field_2 || '',
         'Text434': body.manual_field_3 || '',
         'Text435': body.manual_field_4 || '',
         'Text436': body.manual_field_5 || '',
         'Text440': body.manual_field_6 || '',
         'Text441': body.manual_field_7 || '',
         'Text442': body.manual_field_8 || '',
         'Text443': body.manual_field_9 || '',
         'Text444': body.manual_field_10 || '',
         'Text445': body.manual_field_11 || '',
         'Text446': body.manual_field_12 || '',
         'Text447': body.manual_field_13 || '',
         'Text448': body.total_liabilities || '',
       }
    }

    // Debug Text60 specifically
    console.log('Text60 value from body:', body.cash_on_hand_end_period)
    console.log('Text60 mapped value:', fieldMappings['Text60'])
    console.log('All field mappings:', Object.keys(fieldMappings))

    // Fill each field
    for (const [fieldName, value] of Object.entries(fieldMappings)) {
      try {
        const field = form.getTextField(fieldName)
        if (field) {
          field.setText(value.toString())
          console.log(`Successfully filled field ${fieldName} with value: ${value}`)
        } else {
          console.warn(`Field ${fieldName} not found in PDF template`)
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