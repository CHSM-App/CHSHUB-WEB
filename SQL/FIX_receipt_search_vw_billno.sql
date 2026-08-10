/*
  receipt_search_vw -- bill numbers truncate to 'MBL-2026-00*'.

  The view formats Billno with RIGHT('000' + CAST(bill_no AS VARCHAR(3)), 3).
  Casting a 4-digit bill_no into VARCHAR(3) overflows, and SQL Server renders
  the result as '*'. Every bill on the receipt-detail screen therefore shows the
  same 'MBL-2026-00*' and they cannot be told apart.

  bill_no passed 1000 some time ago -- MAX(bill_no) is currently 1304 -- so this
  affects every recent receipt. The same defect was already fixed in
  sp_MaintenanceReceipt's GetBills action (SQL/FIX_receipt_pdc_and_billno.sql);
  this view was missed because it is a separate object.

  Display only: settlement matches on the raw bill_no, which is untouched.

  ROLLBACK: SQL/receipt_search_vw_BEFORE_billno_fix.sql holds the current
  definition. No data is modified.
*/

USE [Society];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

ALTER VIEW dbo.receipt_search_vw
AS
SELECT r.receipt_no, r.receipt_id, ISNULL(r.pay_mode + ': ' + r.transaction_ref, r.pay_mode + ': ' + r.cheque_no) AS transaction_ref, ow.name, r.bank_name, r.society_id, r.flat_id, r.paid_amount, bs.bill_status, r.receipt_date AS [date], 
                  sm.name AS society_name, sm.city + ' ' + d .division + ', ' + dis.district + ' ' + s.state + ' ' + sm.pincode AS address, sm.registration_no, r.pay_mode, ow.unit, ow.build_id, ow.owner_id, 'MBL-' + CAST(YEAR(gen_date) AS VARCHAR(4)) 
                  + '-' + RIGHT('0000' + CAST(bill_no AS VARCHAR(10)), 4) AS Billno, mc.gen_date, CASE WHEN mc.bill_type = 1 THEN 'Bill: ' + LEFT(DATENAME(MONTH, gen_date), 3) + ' ' + + CAST(YEAR(gen_date) AS VARCHAR(4)) 
                  ELSE 'Add-ON Bill: ' + LEFT(DATENAME(MONTH, gen_date), 3) + ' ' + + CAST(YEAR(gen_date) AS VARCHAR(4)) END AS bill_ref, CASE WHEN mc.status = 3 THEN total_amount + ISNULL(mc.tax_interest_amt, 0) WHEN mc.status = 5 THEN abs(mc.total_amount - mc.due) 


                  END AS amount, DATENAME(MONTH, mc.gen_date) AS month_name
FROM     dbo.receipt AS r INNER JOIN
                  dbo.society_master AS sm ON r.society_id = sm.society_id INNER JOIN
                  dbo.owner_search_vw AS ow ON sm.society_id = ow.society_id AND r.flat_id = ow.flat_id INNER JOIN
                  dbo.bill_status AS bs ON r.status = bs.status_id INNER JOIN
                  dbo.division AS d ON sm.division_id = d .division_id INNER JOIN
                  dbo.district AS dis ON d .district_id = dis.district_id INNER JOIN
                  dbo.state AS s ON dis.state_id = s.state_id CROSS APPLY STRING_SPLIT(r.bill_details, ',') AS split_vals INNER JOIN
                  dbo.maintenance_cal AS mc ON mc.society_id = sm.society_id AND mc.bill_no = TRIM(split_vals.value)
WHERE  ow.type = 'Owner';

GO
