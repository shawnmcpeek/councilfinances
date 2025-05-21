# Program ID Standardization Migration Plan

## Overview
This document outlines the migration plan to standardize all program IDs across the app to the `CP001`/`AP001` format, ensuring consistency for both council and assembly programs. The plan incorporates feedback and best practices discussed in recent development sessions.

---

## 1. Compare 1728 Forms ("Bibles")
- Compare the program/activity lists from the 1728a (individual) and 1728 (fraternal) forms.
- Use these as the canonical source for the system/default program list.
- Assign each default program a unique numeric suffix (e.g., `CP001`/`AP001` for Refund Support Vocations Program).

## 1a. Custom Program Numbering
- After the last system/default program (e.g., `CP037`), the first custom program is `CP038`, then `CP039`, etc.
- For assemblies, use `AP038`, `AP039`, etc.
- Optionally, reserve a block for custom programs (e.g., `CP9XX`/`AP9XX`).

## 2. Descriptive IDs and Names
- Keep descriptive names (e.g., "Refund Support Vocations Program" or "RSVP") uniform across the app.
- The canonical ID (`CP001`/`AP001`) is the primary key for all backend logic.
- Descriptive IDs (like `rsvp`) can be kept as a secondary field for search/legacy, but the numeric ID is primary.

## 3. Source of Truth: JSON vs. Firestore
- System default programs are stored in a JSON file and loaded as the master list.
- Custom programs are stored in Firestore per-organization.
- Both system and custom programs use the same ID format.
- When displaying/selecting programs, merge the lists as needed, using the CP/AP ID as the unique key.

## 4. Backend Mapping
- All backend logic (report generation, aggregation, etc.) uses the CP/AP ID as the canonical reference.
- Update any backend code that currently uses descriptive IDs or names to use the new format.

## 5. Custom Program Migration
- Manually assign the next available CP/AP number to each custom program and update their records in Firestore.
- This is feasible given the current small number of custom programs.

## 6. Custom Program ID Range
- Use `CP9XX`/`AP9XX` for custom programs for clarity and future-proofing.
- This makes it easy to distinguish system from custom programs at a glance.

## 7. Update All Codebase References
- Update all code, forms, dropdowns, and reports to use the new ID system.
- Ensures consistency and prevents bugs.

## 8. No Backward Compatibility Needed
- Migrate all old IDs to the new format and remove any legacy handling code.
- No need for backward compatibility or transition logic at this stage.

## 9. Testing
- Test as you go, especially after each major migration step.
- Validate that all reports, forms, and program selection UIs work as expected.

## 10. Deployment and Documentation
- Once everything is migrated and tested, update documentation to explain the new system.
- This will help future developers and admins understand the structure.

---

## Key Feedback Incorporated
- The 1728 forms are the "bibles" for the canonical program list.
- Custom programs are numbered sequentially after system programs, or in a reserved block.
- Descriptive names are kept uniform, but the numeric CP/AP ID is the primary key.
- System programs come from JSON, custom from Firestore, both using the same ID format.
- Backend logic always uses the new ID format.
- Manual migration for custom programs is acceptable at this scale.
- No backward compatibility is needed; a hard cutover is preferred.
- Testing and documentation are essential throughout the process.

---

**This plan should be referenced for all future work related to program ID standardization.** 