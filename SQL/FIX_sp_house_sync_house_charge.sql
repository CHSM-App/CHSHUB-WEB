/*
 * Saving a house keeps house_charge in step with it.
 *
 * The problem
 * -----------
 * Charges are entered in two places and stored in two places:
 *
 *     Village Residents  ->  house.gharpatti_charges / water_charges / waste_charges
 *     Charges screen     ->  house_charge.amount
 *
 * Neither knows about the other. Change a figure on Residents and the Charges
 * screen still shows the old one; change it on Charges and Residents does. Two
 * answers to "what does this house pay", and no way to tell which is right.
 *
 * The fix
 * -------
 * sp_house's Update branch writes house_charge as well as house, so whichever
 * screen — or the legacy WebForms app — saves a house, both end up saying the
 * same thing. house keeps its three columns because the legacy pages read
 * them; house_charge becomes the copy the new billing works from.
 *
 * The rules it follows
 * --------------------
 *   - An amount above zero means the charge applies. Zero or NULL means it
 *     does not, and the row is deactivated rather than deleted so its history
 *     and its amount survive.
 *
 *   - Water needs a tap. no_of_tab = 0 switches water off however much is
 *     typed into water_charges — the case the three-column shape could not
 *     express, and the reason house number 0 was being billed for water it has
 *     no connection for.
 *
 *   - effective_from follows the rule already in
 *     fn_house_charge_effective_from: a changed amount applies from the first
 *     period that has not been billed, and an unchanged amount is left alone.
 *
 *   - Charges a village has added itself — payment_type 4 and up — are not
 *     touched. They have no column on dbo.house, so a save here knows nothing
 *     about them and must not disturb what the Charges screen set.
 *
 * Safe to re-run.
 */

SET NOCOUNT ON;
GO

DECLARE @body NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.sp_house'));
DECLARE @stop BIT = 0;

IF @body IS NULL
BEGIN
    RAISERROR('sp_house not found in this database.', 16, 1);
    SET @stop = 1;
END

IF @stop = 0 AND @body LIKE '%house_charge_synced%'
BEGIN
    PRINT 'sp_house: already syncs house_charge - no change made.';
    SET @stop = 1;
END

IF @stop = 0 AND OBJECT_ID('dbo.fn_house_charge_effective_from', 'FN') IS NULL
BEGIN
    RAISERROR('fn_house_charge_effective_from is missing - run FIX_house_charge_effective_from_rule.sql first.', 16, 1);
    SET @stop = 1;
END

/*
 * Inserted just before the Update branch returns the id, so it runs whether
 * the house was created or edited and @finalId is known either way.
 *
 * A single line, not two: the stored body uses CRLF, and a literal written
 * across two lines in this file would carry whatever this file uses. Matching
 * one line avoids the question entirely.
 */
DECLARE @anchor NVARCHAR(MAX) = N'SELECT @finalId AS house_id;';

DECLARE @sync NVARCHAR(MAX) = N'
    /* house_charge_synced — keep house_charge in step with the three columns
       above, so the billing screens and the legacy pages agree. */
    DECLARE @sync TABLE (payment_type INT, amount DECIMAL(18,2), applies BIT);

    INSERT INTO @sync (payment_type, amount, applies)
    VALUES (1, @gharpatti_charges, CASE WHEN ISNULL(@gharpatti_charges, 0) > 0 THEN 1 ELSE 0 END),
           -- Water needs a tap connection, however much is typed in.
           (2, @water_charges,     CASE WHEN ISNULL(@water_charges, 0) > 0
                                        AND ISNULL(@no_of_tab, 0) > 0 THEN 1 ELSE 0 END),
           (3, @waste_charges,     CASE WHEN ISNULL(@waste_charges, 0) > 0 THEN 1 ELSE 0 END);

    -- Existing rows: the amount, and the date only when the amount moved.
    UPDATE c
    SET    c.amount         = s.amount,
           c.active_status  = CASE WHEN s.applies = 1 THEN 0 ELSE 1 END,
           c.effective_from = CASE
                                WHEN s.applies = 1 AND s.amount <> ISNULL(c.amount, -1)
                                THEN dbo.fn_house_charge_effective_from(@finalId, s.payment_type)
                                ELSE c.effective_from
                              END
    FROM   dbo.house_charge AS c
    JOIN   @sync AS s ON s.payment_type = c.payment_type
    WHERE  c.house_id = @finalId;

    -- Charges that now apply and had no row at all.
    INSERT INTO dbo.house_charge (house_id, payment_type, amount, active_status, effective_from)
    SELECT @finalId, s.payment_type, s.amount, 0,
           dbo.fn_house_charge_effective_from(@finalId, s.payment_type)
    FROM   @sync AS s
    WHERE  s.applies = 1
      AND  NOT EXISTS (SELECT 1 FROM dbo.house_charge c
                        WHERE c.house_id = @finalId AND c.payment_type = s.payment_type);

    SELECT @finalId AS house_id;';

IF @stop = 0 AND CHARINDEX(@anchor, @body) = 0
BEGIN
    RAISERROR('Could not locate the Update branch return - apply the change by hand.', 16, 1);
    SET @stop = 1;
END

IF @stop = 0
BEGIN
    SET @body = REPLACE(@body, @anchor, @sync);
    SET @body = STUFF(@body, CHARINDEX('CREATE', @body), 6, 'ALTER');

    EXEC sp_executesql @body;

    PRINT 'sp_house: saving a house now writes house_charge too.';
END
GO

/* ---------------------------------------------------------- verification */

SELECT h.house_no, h.no_of_tab, t.payment_type_name, c.amount, c.effective_from,
       CASE WHEN c.active_status = 0 THEN 'billed' ELSE 'not billed' END AS state
FROM   dbo.house AS h
JOIN   dbo.house_charge AS c ON c.house_id = h.house_id
JOIN   dbo.Village_payment_type AS t ON t.payment_type = c.payment_type
ORDER  BY h.house_no, c.payment_type;
GO
