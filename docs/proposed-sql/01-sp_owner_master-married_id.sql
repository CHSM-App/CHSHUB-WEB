/* =============================================================================
   WITHDRAWN — NO CHANGE REQUIRED.  Verified against the live database 2026-08-04.

   Object : dbo.sp_owner_master
   Status : The deployed procedure is CORRECT. No ALTER is needed.
   =============================================================================

   WHAT WAS REPORTED
   -----------------
   The sp_owner_master script supplied at project start contains, in the ELSE
   (edit) branch of @operation = 'Update':

       @married_id              = @married_id,

   which is a variable self-assignment, not a column assignment, and would mean
   marital status is silently discarded on edit.

   WHAT IS ACTUALLY DEPLOYED
   -------------------------
   Retrieved with:

       SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.sp_owner_master'));

   Result: 769 lines. Occurrences of the pattern `@married_id = @married_id`: 0.
   Line 132 of the deployed definition reads:

       married_id              = @married_id,

   i.e. the column IS assigned and marital status DOES persist on update.

   CONCLUSION
   ----------
   The defect exists only in the text file shared at project start, which has
   drifted from the database. The live procedure needs no change.

   ACTIONS TAKEN (application side, no SQL touched)
   -----------------------------------------------
   * Removed the 409 guard in backend/web/routes/masters/owners.js.
   * Re-enabled the marital-status field in
     frontend/src/pages/masters/ResidentsPage.jsx.
   * Test updated to assert the field is editable.

   =============================================================================
   LESSON — applies to every remaining slice

   The supplied .txt scripts are not a reliable description of the database.
   Defects are now confirmed against OBJECT_DEFINITION before being reported or
   worked around. Re-verified at the same time:

     CONFIRMED PRESENT in the live database:
       * sp_flat_master    'Update' :  @flat_type_id = @flat_type_id
                                       -> flat type never persists on edit.
                                       API workaround remains justified.
       * sp_loan           'Delete' :  sets active_status = 0  (the LIVE value)
                                       -> delete does nothing.
       * sp_pdc_reminder   'Delete' :  sets active_status = 0  (the LIVE value)
                                       -> delete does nothing.
       * sp_village_master          :  stray trailing SELECT filtered to
                                       village_id='V10010' AND name LIKE 'Wayri%'
                                       -> spurious extra result set on every call.

   Fix scripts for the three genuine defects above will be raised individually,
   for review, when their modules are migrated (Masters revisit, Accounts,
   Billing/PDC, Village respectively).
   ============================================================================= */
