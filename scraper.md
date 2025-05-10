# Council/Assembly Data Scraper Process

## Purpose
Automate the retrieval of official city and state information for Knights of Columbus councils and assemblies from kofc.org, ensuring data accuracy and uniformity across all users with the same council or assembly number.

---

## Workflow Overview

1. **User Input**
   - User enters or updates their council or assembly number in the app.

2. **Number Formatting**
   - App formats the number:
     - Council: e.g., 3434 → C003434
     - Assembly: e.g., 123 → A000123

3. **Firestore Lookup**
   - App queries Firestore for the organization document:
     - `organizations/C003434` or `organizations/A000123`

4. **Check for Existing Data**
   - If the organization document exists:
     - Check the `orgdata` subcollection for a `location` document containing city and state.
     - If city/state exist: **Use them, skip scraping.**
     - If city/state missing: **Run the scraper, save the data to `orgdata/location`.**
   - If the organization document does not exist:
     - **Run the scraper, create the org document and `orgdata/location` with city/state.**

5. **Scraping Logic**
   - Use a backend service (headless browser or HTTP client with HTML parsing) to:
     1. Load the kofc.org Find a Council/Assembly page.
     2. Select the appropriate dropdown value ("Council #" or "Assembly #").
     3. Enter the provided number.
     4. Submit the form (simulate clicking "Find").
     5. Parse the resulting HTML to extract the city and state from the result section.
   - **Extracting City/State:**
     - The city and state are in a single string (e.g., `MEAD, CO 80542`).
     - Use a comma as the delimiter: split on "," to get city and state+zip.
     - Further split state+zip on space to get just the state (e.g., `CO`).

6. **Saving to Firestore**
   - Store city and state in the `orgdata` subcollection under the organization document:
     ```
     organizations
       └── C003434
             └── orgdata
                   └── location
                         ├── city: "MEAD"
                         └── state: "CO"
     ```

---

## Additional Notes
- Only trigger scraping when a user enters or changes their council/assembly number (not on every app load).
- If city/state are missing but the org exists, fallback to scraping and update Firestore.
- Optionally, add a timestamp to the location data for future freshness checks.
- If kofc.org ever provides an official API, switch to using it instead of scraping.
- Be mindful of kofc.org's terms of service and avoid excessive requests.

---

## Future Enhancements
- Add support for periodic re-scraping to keep data up to date.
- Expand `orgdata` to include additional metadata as needed.
- Add error handling and user feedback for failed lookups or scraping issues. 