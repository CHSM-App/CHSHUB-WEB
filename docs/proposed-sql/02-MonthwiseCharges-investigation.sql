/* =============================================================================
   PROPOSED NEW TABLE — FOR REVIEW ONLY.  NOT EXECUTED.  NOTHING CREATED.

   Object : dbo.MonthwiseCharges
   Status : Referenced by two DEPLOYED stored procedures. Does not exist in the
            database. Verified 2026-08-04 against the live server.
   =============================================================================

   ---------------------------------------------------------------------------
   STEP 1 — DOES THE DATA ALREADY EXIST SOMEWHERE ELSE?   (you asked me to check)
   ---------------------------------------------------------------------------
   No. Three searches, all negative:

   (a) Any table carrying the key column:
         SELECT table_name FROM information_schema.columns
         WHERE  column_name = 'mon_charge_id';
       -> 0 rows.

   (b) Any table with the same column shape:
         SELECT table_name FROM information_schema.columns
         WHERE  column_name IN ('advance','amount','society_id','active_status')
         GROUP BY table_name HAVING COUNT(*) >= 4;
       -> 0 rows.

   (c) Society_Charges — the closest-named table — inspected in full:

         COLUMNS : charge_id int | society_id nvarchar(10) | amount decimal
                   active_status int | total_unit int
         DATA    : 4 rows, exactly one per society
                     C10001  amount=10     total_unit=19
                     C10004  amount=50     total_unit=4
                     C10005  amount=20000  total_unit=10
                     C10006  amount=50     total_unit=10

   WHY Society_Charges CANNOT BE REUSED
   ------------------------------------
   * Cardinality.  Society_Charges is 1 row per society (a current rate).
     MonthwiseCharges is 1 row per society PER MONTH (a ledger). Reusing it
     would require multiple rows per society, which breaks its meaning.
   * Lifecycle.  Society_Charges.amount is a fixed rate that is read, never
     decremented. MonthwiseCharges.amount is a running balance that
     sp_SocietyReceipt writes down to 0 as payments clear (see evidence below).
   * Missing columns.  Society_Charges has no `date` and no `advance`. Both are
     written by sp_SocietyReceipt.
   * Collateral damage.  sp_society_charges and admin_vw both read
     Society_Charges as a per-unit rate (admin_vw exposes it as
     `chargesPerUnit`). Repurposing the table would corrupt both.

   CONCLUSION: the data exists nowhere. The table was either never migrated with
   the rest of the schema, or dropped at some point.

   ---------------------------------------------------------------------------
   STEP 2 — WHAT BREAKS TODAY
   ---------------------------------------------------------------------------
   dbo.sp_society_charges_monthwise   every branch
                                      (Update / Delete / Select /
                                       Charges_Show / Remaining_due)

   dbo.sp_SocietyReceipt              the 'ClearDue' branch — invoked
                                      automatically by the 'UPDATE' branch after
                                      each society receipt is inserted

   Live impact: `society_receipt` already contains 7 rows, so this screen is in
   use. Any call reaching ClearDue fails with:

       Msg 208, Level 16: Invalid object name 'MonthwiseCharges'.

   ---------------------------------------------------------------------------
   STEP 3 — COLUMN-BY-COLUMN MAPPING, WITH THE LINE THAT REQUIRES IT
   ---------------------------------------------------------------------------
   Every column below is required by a statement in a deployed procedure. No
   column is speculative; nothing has been added "for completeness".

   1. mon_charge_id   int  NOT NULL   (primary key)
      WHY : the key each procedure reads, updates and deletes by.
      FROM : sp_society_charges_monthwise
               SELECT TOP (1) @new = mon_charge_id FROM dbo.MonthwiseCharges
               ORDER BY mon_charge_id DESC          -- MAX(id)+1 allocation
             sp_SocietyReceipt (ClearDue), line 75
               select mon_charge_id, amount, date from MonthwiseCharges ...
      TYPE : int — matches the @mon_charge_id INT parameter and the
             ORDER BY ... DESC allocation pattern.
      NOT IDENTITY: the procedure allocates the key itself (MAX+1). Making it
             IDENTITY would conflict with the explicit INSERT of mon_charge_id.
             ~40 other procedures in this database use the same pattern.

   2. society_id      nvarchar(10)  NULL
      WHY : tenant scoping; every read filters on it.
      FROM : sp_SocietyReceipt line 75  WHERE society_id = @society_id
             sp_SocietyReceipt line 94  WHERE society_id = @society_id
      TYPE : nvarchar(10) — identical to society_master.society_id and to every
             other society_id column in the schema.

   3. amount          decimal(18,2) NULL
      WHY : the outstanding balance for that month. NOT a static rate — it is
             written down as payments are applied.
      FROM : sp_SocietyReceipt line 82  update ... set amount = 0
             sp_SocietyReceipt line 87  update ... set amount = abs(@balance)
             sp_SocietyReceipt line 94  select @total_due = sum(amount)
      TYPE : decimal(18,2) — matches Society_Charges.amount and the
             @amount DECIMAL(18,2) parameter on sp_society_charges_monthwise.

   4. date            smalldatetime NULL
      WHY : which month the row represents; selected by the ClearDue cursor and
             set on insert.
      FROM : sp_society_charges_monthwise
               INSERT ... values(@new, @society_id, @amount, getdate(), 0, 0)
               UPDATE ... set ... date = @date
             sp_SocietyReceipt line 75  select mon_charge_id, amount, date ...
      TYPE : smalldatetime — matches the @date SMALLDATETIME parameter and the
             convention used by maintenance_cal.gen_date.

   5. advance         decimal(18,2) NULL
      WHY : overpayment carried forward once every month is settled.
      FROM : sp_SocietyReceipt line 99  update ... set advance = @balance
             sp_society_charges_monthwise INSERT ... , advance) values (..., 0)
      TYPE : decimal(18,2) — same money type as amount.

   6. active_status   int NULL
      WHY : soft delete, the convention used throughout this schema.
      FROM : sp_society_charges_monthwise
               Update MonthwiseCharges set active_status = 1 where ...   (delete)
               ... WHERE active_status = 0 ...                           (reads)
      TYPE : int — 0 = live, 1 = deleted, matching every other table here.

   ---------------------------------------------------------------------------
   STEP 4 — THE COMPLETE SCRIPT (NOT EXECUTED)
   ---------------------------------------------------------------------------
   Safe to re-run: guarded by an existence check so it cannot overwrite a table
   that appears later.

       IF OBJECT_ID('dbo.MonthwiseCharges', 'U') IS NOT NULL
       BEGIN
           PRINT 'dbo.MonthwiseCharges already exists - no action taken.';
           RETURN;
       END
       GO

       CREATE TABLE [dbo].[MonthwiseCharges](
           [mon_charge_id] [int]             NOT NULL,
           [society_id]    [nvarchar](10)        NULL,
           [amount]        [decimal](18, 2)      NULL,
           [date]          [smalldatetime]       NULL,
           [advance]       [decimal](18, 2)      NULL,
           [active_status] [int]                 NULL,
        CONSTRAINT [PK_MonthwiseCharges] PRIMARY KEY CLUSTERED
           ([mon_charge_id] ASC)
           WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF,
                 IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON,
                 ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
           ON [PRIMARY]
       ) ON [PRIMARY];
       GO

       -- Optional. Mirrors FK_Society_Charges -> society_master. Several
       -- comparable tables here omit it; say if you would rather not have it.
       ALTER TABLE [dbo].[MonthwiseCharges] WITH CHECK
           ADD CONSTRAINT [FK_MonthwiseCharges_society]
           FOREIGN KEY([society_id])
           REFERENCES [dbo].[society_master]([society_id]);
       GO

       ALTER TABLE [dbo].[MonthwiseCharges]
           CHECK CONSTRAINT [FK_MonthwiseCharges_society];
       GO

   ROLLBACK
   --------
       DROP TABLE [dbo].[MonthwiseCharges];

   No existing object is altered by this script. It only adds a table that two
   deployed procedures already expect to find.

   ---------------------------------------------------------------------------
   STEP 5 — RISK
   ---------------------------------------------------------------------------
   Creating it   : low. Nothing currently reads or writes the table (it does not
                   exist), so no existing behaviour can change. The two broken
                   procedures begin working; everything else is untouched.
   Not creating  : sp_SocietyReceipt/ClearDue keeps failing at runtime, and
                   /settings/society-charges/monthly cannot be migrated.
   Note          : the table starts EMPTY. Historical monthly charges from
                   before it was lost cannot be reconstructed from what remains
                   in the database — Society_Charges holds only current rates.

   ---------------------------------------------------------------------------
   STEP 6 — YOUR OPTIONS
   ---------------------------------------------------------------------------
   (a) Approve the script above.
   (b) Point me at where the data actually lives, if it is somewhere I have not
       found, and I will map to it instead.
   (c) Declare the module out of scope. I will leave it unimplemented and record
       that sp_SocietyReceipt/ClearDue fails when invoked.

   NOTHING HAS BEEN CREATED. Awaiting your decision.
   ============================================================================= */
