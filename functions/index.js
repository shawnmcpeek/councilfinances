const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { PDFDocument } = require('pdf-lib');
const fs = require('fs');
const cors = require('cors')({ origin: true });

admin.initializeApp();

exports.fillForm1728 = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    try {
      if (req.method !== 'POST') {
        return res.status(405).send('Method Not Allowed');
      }

      // Load the template PDF
      const templateBytes = fs.readFileSync(__dirname + '/fraternal_survey1728_p.pdf');
      const pdfDoc = await PDFDocument.load(templateBytes);

      // Get the form and fill fields
      const form = pdfDoc.getForm();
      // Example: fill fields from req.body
      form.getTextField('Text1').setText(req.body.councilNumber || '');
      form.getTextField('Text2').setText(req.body.yearStart || '');
      // ...repeat for all fields you want to fill...

      // Flatten the form (optional)
      form.flatten();

      // Return the filled PDF
      const pdfBytes = await pdfDoc.save();
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', 'attachment; filename=Form1728P_filled.pdf');
      res.status(200).send(Buffer.from(pdfBytes));
    } catch (err) {
      console.error(err);
      res.status(500).send('Failed to fill PDF');
    }
  });
});

exports.fillAuditReport = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    try {
      console.log('AUDIT PDF DATA RECEIVED:', JSON.stringify(req.body));
      if (req.method !== 'POST') {
        return res.status(405).send('Method Not Allowed');
      }

      // Validate required fields
      if (!req.body.period || !['January-June', 'July-December'].includes(req.body.period)) {
        return res.status(400).send('Invalid period. Must be January-June or July-December');
      }
      if (!req.body.year) {
        return res.status(400).send('Year is required');
      }

      // Load the template PDF
      const templateBytes = fs.readFileSync(__dirname + '/audit2_1295_p.pdf');
      const pdfDoc = await PDFDocument.load(templateBytes);
      const form = pdfDoc.getForm();

      // Basic Info - From user profile and request
      form.getTextField('Text1').setText(req.body.council_number || ''); // From user profile
      form.getTextField('Text2').setText(req.body.auditor_name || ''); // Manual entry for now
      form.getTextField('Text3').setText(req.body.year.toString().slice(-2) || ''); // Last 2 digits of year
      form.getTextField('Text4').setText(req.body.organization_name || ''); // Manual entry for now

      // === NEW: Calculate and fill Text51–Text58 ===
      const data = { ...req.body };
      const period = data.period;
      const year = data.year;
      // Parse period for date range
      let periodStart, periodEnd;
      if (period === 'January-June') {
        periodStart = new Date(`${year}-01-01`);
        periodEnd = new Date(`${year}-06-30`);
      } else if (period === 'July-December') {
        periodStart = new Date(`${year}-07-01`);
        periodEnd = new Date(`${year}-12-31`);
      } else {
        throw new Error('Invalid period');
      }

      // Helper to parse date
      function parseDate(raw) {
        if (!raw) return new Date(1900, 0, 1);
        if (typeof raw === 'string') return new Date(raw);
        if (raw._seconds) return new Date(raw._seconds * 1000);
        return new Date(1900, 0, 1);
      }

      // Combine all entries (income + expenses)
      const allEntries = [
        ...(data.income || []),
        ...(data.expenses || [])
      ];
      // Filter for period
      const periodEntries = allEntries.filter(entry => {
        const date = parseDate(entry.date);
        return date >= periodStart && date <= periodEnd;
      });

      // Text51: Total of all 'Council - Membership Dues'
      const membershipDuesEntries = periodEntries.filter(entry => {
        const programName = entry.programName || (entry.program && entry.program.name) || '';
        return programName.toLowerCase().includes('membership dues');
      });
      const text51 = membershipDuesEntries.reduce((sum, e) => sum + (e.amount || 0), 0);

      // Group all income (excluding membership dues) by program
      const incomeEntries = periodEntries.filter(entry => {
        const isExpense = entry.isExpense || false;
        return !isExpense;
      }).filter(entry => {
        const programName = entry.programName || (entry.program && entry.program.name) || '';
        return !programName.toLowerCase().includes('membership dues');
      });
      const incomeByProgram = {};
      for (const entry of incomeEntries) {
        const programName = entry.programName || (entry.program && entry.program.name) || 'Unknown';
        incomeByProgram[programName] = (incomeByProgram[programName] || 0) + (entry.amount || 0);
      }
      const sortedPrograms = Object.entries(incomeByProgram).sort((a, b) => b[1] - a[1]);
      const top1 = sortedPrograms[0] || [null, 0];
      const top2 = sortedPrograms[1] || [null, 0];
      const others = sortedPrograms.slice(2);
      const text52 = top1[0] || '';
      const text53 = top1[1] || 0;
      const text54 = top2[0] || '';
      const text55 = top2[1] || 0;
      const text56 = others.length > 0 ? 'Other' : '';
      const text57 = others.reduce((sum, e) => sum + e[1], 0);
      // Text50 is manual, use data.Text50 if present, else 0
      const text50 = data.Text50 ? parseFloat(data.Text50) : 0;
      const text58 = text50 + text51 + text53 + text55 + text57;
      // Round all
      function fmt(n) { return Number(n).toFixed(2); }
      data.Text51 = fmt(text51);
      data.Text52 = text52;
      data.Text53 = fmt(text53);
      data.Text54 = text54;
      data.Text55 = fmt(text55);
      data.Text56 = text56;
      data.Text57 = fmt(text57);
      data.Text58 = fmt(text58);

      // === END NEW ===

      // Text59: Manual income entry
      form.getTextField('Text59').setText(req.body.manual_income_2 || '');

      // Text60: Net Income (calculated)
      const netIncome = (parseFloat(text58) - (parseFloat(req.body.manual_income_2) || 0)).toFixed(2);
      form.getTextField('Text60').setText(netIncome);

      // Interest and Per Capita Section
      // Text64: Interest earned from council program
      form.getTextField('Text64').setText(req.body.interest_earned || '');

      // Text65: Total interest (calculated)
      const totalInterest = (
        (parseFloat(req.body.interest_earned) || 0) +
        (parseFloat(req.body.manual_interest_1) || 0) +
        (parseFloat(req.body.manual_interest_2) || 0)
      ).toFixed(2);
      form.getTextField('Text65').setText(totalInterest);

      // Text66-68: Per capita and other council programs
      form.getTextField('Text66').setText(req.body.supreme_per_capita || '');
      form.getTextField('Text67').setText(req.body.state_per_capita || '');
      form.getTextField('Text68').setText(req.body.other_council_programs || '');

      // Text69-70: Manual expense entries
      form.getTextField('Text69').setText(req.body.manual_expense_1 || '');
      form.getTextField('Text70').setText(req.body.manual_expense_2 || '0'); // Default to 0 as per spec

      // Text71: Total Expenses (calculated)
      const totalExpenses = (
        (parseFloat(req.body.other_council_programs) || 0) +
        (parseFloat(req.body.manual_expense_1) || 0) +
        (parseFloat(req.body.manual_expense_2) || 0)
      ).toFixed(2);
      form.getTextField('Text71').setText(totalExpenses);

      // Text72: Net Council (calculated)
      const netCouncil = (parseFloat(totalInterest) - parseFloat(totalExpenses)).toFixed(2);
      form.getTextField('Text72').setText(netCouncil);

      // Text73: Net Council Verification (should equal Text72)
      form.getTextField('Text73').setText(netCouncil);

      // Membership Section
      // Text74-76: Manual membership entries
      form.getTextField('Text74').setText(req.body.manual_membership_1 || '');
      form.getTextField('Text75').setText(req.body.manual_membership_2 || '');
      form.getTextField('Text76').setText(req.body.manual_membership_3 || '');

      // Text77-78: Membership count and dues
      form.getTextField('Text77').setText(req.body.membership_count || '');
      form.getTextField('Text78').setText(req.body.membership_dues_total || '');

      // Text79: Total Membership (calculated)
      const totalMembership = (
        parseFloat(netCouncil) +
        (parseFloat(req.body.manual_membership_1) || 0) +
        (parseFloat(req.body.manual_membership_2) || 0) +
        (parseFloat(req.body.manual_membership_3) || 0) +
        (parseFloat(req.body.membership_count) || 0) +
        (parseFloat(req.body.membership_dues_total) || 0)
      ).toFixed(2);
      form.getTextField('Text79').setText(totalMembership);

      // Text80: Total Disbursements (pulls from Text103)
      form.getTextField('Text80').setText(req.body.total_disbursements_sum || '');

      // Text83: Net Membership (calculated)
      const netMembership = (parseFloat(totalMembership) - (parseFloat(req.body.total_disbursements_sum) || 0)).toFixed(2);
      form.getTextField('Text83').setText(netMembership);

      // Disbursements Section
      // Text84-87: Manual disbursement entries
      form.getTextField('Text84').setText(req.body.manual_disbursement_1 || '');
      form.getTextField('Text85').setText(req.body.manual_disbursement_2 || '');
      form.getTextField('Text86').setText(req.body.manual_disbursement_3 || '');
      form.getTextField('Text87').setText(req.body.manual_disbursement_4 || '');

      // Text88: Total Disbursements Verification (calculated)
      const totalDisbursementsVerify = (
        parseFloat(netMembership) +
        (parseFloat(req.body.manual_disbursement_1) || 0) +
        (parseFloat(req.body.manual_disbursement_2) || 0) +
        (parseFloat(req.body.manual_disbursement_3) || 0) +
        (parseFloat(req.body.manual_disbursement_4) || 0)
      ).toFixed(2);
      form.getTextField('Text88').setText(totalDisbursementsVerify);

      // Additional Fields (Text89-110)
      // All manual entries with Text92 defaulting to 0
      form.getTextField('Text89').setText(req.body.manual_field_1 || '');
      form.getTextField('Text90').setText(req.body.manual_field_2 || '');
      form.getTextField('Text91').setText(req.body.manual_field_3 || '');
      form.getTextField('Text92').setText(req.body.manual_field_4 || '0');
      form.getTextField('Text93').setText(req.body.manual_field_5 || '');
      form.getTextField('Text95').setText(req.body.manual_field_6 || '');
      form.getTextField('Text96').setText(req.body.manual_field_7 || '');
      form.getTextField('Text97').setText(req.body.manual_field_8 || '');
      form.getTextField('Text98').setText(req.body.manual_field_9 || '');
      form.getTextField('Text99').setText(req.body.manual_field_10 || '');
      form.getTextField('Text100').setText(req.body.manual_field_11 || '');
      form.getTextField('Text101').setText(req.body.manual_field_12 || '');
      form.getTextField('Text102').setText(req.body.manual_field_13 || '');

      // Text103: Total Disbursements Sum (calculated)
      const totalDisbursementsSum = (
        (parseFloat(req.body.manual_field_1) || 0) +
        (parseFloat(req.body.manual_field_2) || 0) +
        (parseFloat(req.body.manual_field_3) || 0) +
        (parseFloat(req.body.manual_field_4) || 0) +
        (parseFloat(req.body.manual_field_5) || 0) +
        (parseFloat(req.body.manual_field_6) || 0) +
        (parseFloat(req.body.manual_field_7) || 0) +
        (parseFloat(req.body.manual_field_9) || 0) +
        (parseFloat(req.body.manual_field_11) || 0) +
        (parseFloat(req.body.manual_field_13) || 0)
      ).toFixed(2);
      form.getTextField('Text103').setText(totalDisbursementsSum);

      // Log and fill every field from the request body
      Object.keys(req.body).forEach((key) => {
        try {
          form.getTextField(key).setText(String(req.body[key]));
          console.log(`PDF FILL: ${key} = ${req.body[key]}`);
        } catch (e) {
          // Ignore if field does not exist
        }
      });

      // Flatten the form
      form.flatten();

      // Return the filled PDF
      const pdfBytes = await pdfDoc.save();
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', `attachment; filename=audit_report_${req.body.period.replace(' ', '_')}_${req.body.year}.pdf`);
      res.status(200).send(Buffer.from(pdfBytes));
    } catch (err) {
      console.error('Error filling audit report:', err);
      res.status(500).send('Failed to fill audit report PDF');
    }
  });
});

exports.fillIndividualSurveyReport = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    try {
      if (req.method !== 'POST') {
        return res.status(405).send('Method Not Allowed');
      }

      // Validate required fields
      if (!req.body.year) {
        return res.status(400).send('Year is required');
      }

      // Load the template PDF
      const templateBytes = fs.readFileSync(__dirname + '/individual_survey1728a_p.pdf');
      const pdfDoc = await PDFDocument.load(templateBytes);
      const form = pdfDoc.getForm();

      // Set the year (last 2 digits) in both fields
      const yearDigits = req.body.year.toString().slice(-2);
      form.getTextField('Text1').setText(yearDigits);
      form.getTextField('undefined').setText(yearDigits);

      // Fill council activity fields (Text2-Text41)
      for (let i = 2; i <= 41; i++) {
        const fieldName = `Text${i}`;
        const hours = req.body[`council_activity_${i-1}`] || 0;
        form.getTextField(fieldName).setText(hours.toString());
      }

      // Fill assembly activity fields (Text42-Text79)
      for (let i = 42; i <= 79; i++) {
        const fieldName = `Text${i}`;
        const hours = req.body[`assembly_activity_${i-41}`] || 0;
        form.getTextField(fieldName).setText(hours.toString());
      }

      // Set totals
      form.getTextField('TOTAL').setText(req.body.council_total?.toString() || '0');
      form.getTextField('TOTAL_2').setText(req.body.assembly_total?.toString() || '0');

      // Flatten the form
      form.flatten();

      // Return the filled PDF
      const pdfBytes = await pdfDoc.save();
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', `attachment; filename=individual_survey_${req.body.year}.pdf`);
      res.status(200).send(Buffer.from(pdfBytes));
    } catch (err) {
      console.error('Error filling individual survey report:', err);
      res.status(500).send('Failed to fill individual survey PDF');
    }
  });
});

// TESTING FUNCTION: Fill all PDF fields by name from JSON
exports.fillAuditReportTest = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    try {
      console.log('AUDIT PDF TEST DATA RECEIVED:', JSON.stringify(req.body));
      if (req.method !== 'POST') {
        return res.status(405).send('Method Not Allowed');
      }

      // Load the template PDF
      const templateBytes = fs.readFileSync(__dirname + '/audit2_1295_p.pdf');
      const pdfDoc = await PDFDocument.load(templateBytes);
      const form = pdfDoc.getForm();

      // Fill every field in the request body by name
      Object.keys(req.body).forEach((key) => {
        try {
          const field = form.getTextField(key);
          if (field) {
            field.setText(String(req.body[key]));
          }
        } catch (e) {
          // Ignore missing fields
        }
      });

      // Return the filled PDF
      const pdfBytes = await pdfDoc.save();
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', 'attachment; filename="filled_audit_test.pdf"');
      res.status(200).send(Buffer.from(pdfBytes));
    } catch (e) {
      res.status(500).send('Error generating test PDF: ' + e.toString());
    }
  });
}); 