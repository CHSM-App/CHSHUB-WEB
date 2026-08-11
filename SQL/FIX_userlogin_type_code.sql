/*
 * FIX: UserLogin.type must hold a numeric code, not the word.
 *
 * Symptom
 * -------
 *   POST /auth/login  ->  500
 *   Msg 245, procedure validateuser, line 19:
 *   "Conversion failed when converting the nvarchar value 'Society' to data
 *    type int."
 *
 * Cause
 * -----
 * UserLogin.type is nvarchar(50), but every proc that reads it compares it to
 * a number. validateuser's login branch does:
 *
 *     case when UserLogin.type = 1 then 'Society' else 'Village' end as type
 *
 * A comparison between nvarchar and int makes SQL Server convert the *string*
 * side to int, so the row is only readable while type holds something numeric.
 * Registration wrote the word ('Society' / 'Village') into it, which stores
 * fine and then breaks that user's every subsequent login.
 *
 * The legacy WebForms page had the same defect — new_registration.aspx.cs set
 *   Details.Type = radiobtn1.Checked ? "Society" : "Village"
 * so accounts created there are affected too.
 *
 * Fix
 * ---
 * The API now normalises the value before writing it (see tenantTypeCode() in
 * backend/web/routes/onboarding.js). This script repairs the rows already
 * written, mapping the words to the codes the procs expect: 1 society,
 * 2 village.
 *
 * Safe to re-run: only non-numeric values are touched.
 */

SET NOCOUNT ON;

BEGIN TRANSACTION;

-- What is about to change.
SELECT  user_id,
        username,
        [type]      AS type_before,
        CASE WHEN LOWER(LTRIM(RTRIM([type]))) = 'village' THEN '2' ELSE '1' END AS type_after
FROM    dbo.UserLogin
WHERE   [type] IS NOT NULL
  AND   LTRIM(RTRIM([type])) <> ''
  AND   ISNUMERIC([type]) = 0;

UPDATE  dbo.UserLogin
SET     [type] = CASE WHEN LOWER(LTRIM(RTRIM([type]))) = 'village' THEN '2' ELSE '1' END
WHERE   [type] IS NOT NULL
  AND   LTRIM(RTRIM([type])) <> ''
  AND   ISNUMERIC([type]) = 0;

PRINT CONCAT('Rows repaired: ', @@ROWCOUNT);

/*
 * A row with type NULL or '' is left alone: validateuser's CASE sends anything
 * that is not 1 down the 'Village' branch without converting, so those log in
 * without error. Guessing a tenant kind for them would be a data change this
 * fix has no basis for.
 */
SELECT  COUNT(*) AS rows_left_null_or_blank
FROM    dbo.UserLogin
WHERE   [type] IS NULL OR LTRIM(RTRIM([type])) = '';

COMMIT TRANSACTION;
GO
