/*
 * Let earlier periods be billed: move each charge's effective_from back.
 *
 * Run at the user's explicit instruction, to raise the periods the village is
 * missing — January to July 2026 for the monthly charges, and 2025 for
 * property tax.
 *
 *
 * WHY THIS IS NEEDED
 * ------------------
 * house_charge.effective_from says the first period a charge may be billed
 * for. It currently reads 1 August 2026 for the monthly charges and 1 January
 * 2026 for property tax, so sp_village_bill_run refuses anything earlier — a
 * January preview comes back with nothing at all. That guard is doing its job:
 * it stops an amount entered today from being applied to months that closed
 * before it existed.
 *
 * Here that is not what happened. The amounts were not changed; they were only
 * ever dated from when the new billing was set up. Moving the date back says
 * "this charge was already in force then", which is what the village is
 * telling us.
 *
 *
 * WHAT IT DOES
 * ------------
 *   monthly charges -> effective_from = 1 January 2026
 *   yearly charges  -> effective_from = 1 January 2025
 *
 * Property tax goes back a further year because 2025's charge is wanted too,
 * and a yearly charge is compared against the start of its year.
 *
 *
 * WHAT IT WILL LET YOU RAISE
 * --------------------------
 * Nothing is billed by this script. It only unlocks the periods. Afterwards,
 * from Generate Bills:
 *
 *   each month Jan-Jul 2026   waste 2,500 + water 1,310 + other 100 = 3,910
 *   seven months              27,370
 *   property tax 2025         153,700
 *   property tax 2026         153,700
 *
 * The monthly figures are today's amounts applied to every month. If a charge
 * was genuinely different in, say, March, this will bill March at today's
 * figure — the old amount was never recorded, so there is nothing else to use.
 * Raise those months only if today's amounts are what those months should
 * carry.
 *
 *
 * WHAT IT DOES NOT CHANGE
 * -----------------------
 * No amount, no charge, and no bill. Bills already raised keep their own
 * amount regardless of this, and the rule that a changed amount takes effect
 * from the first unbilled period still applies from here on: this only moves
 * the floor.
 *
 * Safe to re-run.
 */

SET NOCOUNT ON;
GO

/* --------------------------------------------------------- before */

SELECT t.payment_type_name, t.frequency, c.effective_from, COUNT(*) AS houses
FROM   dbo.house_charge AS c
JOIN   dbo.Village_payment_type AS t ON t.payment_type = c.payment_type
GROUP  BY t.payment_type_name, t.frequency, c.effective_from
ORDER  BY t.payment_type_name, c.effective_from;
GO

/* --------------------------------------------------------- the change */

/*
 * Only dates later than the target move. A charge already dated earlier is
 * left alone — it is in force further back than this asks for, and pushing it
 * forward would take away periods that are currently billable.
 */
UPDATE c
SET    c.effective_from = DATEFROMPARTS(2026, 1, 1)
FROM   dbo.house_charge AS c
JOIN   dbo.Village_payment_type AS t ON t.payment_type = c.payment_type
WHERE  t.frequency = 'M'
  AND  (c.effective_from IS NULL OR c.effective_from > DATEFROMPARTS(2026, 1, 1));

PRINT CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' monthly charge(s) moved back to 1 January 2026.';

UPDATE c
SET    c.effective_from = DATEFROMPARTS(2025, 1, 1)
FROM   dbo.house_charge AS c
JOIN   dbo.Village_payment_type AS t ON t.payment_type = c.payment_type
WHERE  t.frequency = 'Y'
  AND  (c.effective_from IS NULL OR c.effective_from > DATEFROMPARTS(2025, 1, 1));

PRINT CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' yearly charge(s) moved back to 1 January 2025.';
GO

/* --------------------------------------------------------- verification */

SELECT t.payment_type_name, t.frequency, c.effective_from, COUNT(*) AS houses
FROM   dbo.house_charge AS c
JOIN   dbo.Village_payment_type AS t ON t.payment_type = c.payment_type
GROUP  BY t.payment_type_name, t.frequency, c.effective_from
ORDER  BY t.payment_type_name, c.effective_from;

/*
 * January 2026 should now have something to raise, where it had nothing.
 * Property tax appears against whichever month is previewed, because a yearly
 * charge belongs to the year rather than the month.
 */
DECLARE @v NVARCHAR(50) = (SELECT TOP 1 village_id FROM dbo.house WHERE village_id IS NOT NULL);
EXEC dbo.sp_village_bill_run @operation = 'Preview', @village_id = @v,
                             @bill_year = 2026, @bill_month = 1;
GO
