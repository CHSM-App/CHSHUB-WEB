# Online payment integrity — deployment & operations

Fixes audit P0-3: the client used to set the payment amount, the signature was
compared with `!==`, and receipts were created from a client-supplied
`paid_amount`. Now the server prices the order from `maintenance_cal`, verifies
the signature in constant time, and creates the receipt transactionally, bound
to the Razorpay payment id.

## What changed in code

- `backend/routes/payments.js` *(new)* — `POST /payments/create-order`,
  `POST /payments/verify`, `POST /payments/webhook`.
- `backend/routes/test.js` — old `/create-order` + `/verify-payment` now return
  `410 Gone` pointing at `/payments`.
- `backend/routes/insert.js` — `POST /insert/AddReceipt` now returns `403`
  (residents can no longer settle a bill with an arbitrary amount). Manual/cash
  receipts stay on the admin API (`web/routes/billing/receipts.js`).
- `backend/app.js` — mounts `/payments`; keeps the raw request body
  (`req.rawBody`) so the webhook signature can be verified over the exact bytes.
- `SQL/ADD_payment_order.sql` *(new)* — `payment_order` table, `sp_payment_order`,
  `payment_reconciliation_vw`.

## The flow

```
create-order  (auth + own-flat)  ->  server prices bills from maintenance_cal
                                  ->  razorpay.orders.create(server amount)
                                  ->  payment_order row (status 'created')
verify        (auth)             ->  own order? signature ok (timingSafeEqual)?
                                  ->  razorpay amount == order amount?
                                  ->  TXN { insert receipt (transaction_ref =
                                          payment_id, UNIQUE), mark order 'paid' }
webhook       (signature only)   ->  same settlement if the client never returned
```

Idempotency/replay: `payment_order.status` only moves `created -> paid`, and
`receipt.transaction_ref` is UNIQUE — a repeated verify or webhook for the same
payment creates no second receipt.

## 1. SQL migration (apply first)

```bash
sqlcmd -S winsome.grabweb.in -d Society -U chsadmin -P '<db-password>' -i SQL/ADD_payment_order.sql
```
Idempotent: guarded `CREATE TABLE`, `DROP/CREATE PROCEDURE`, `DROP/CREATE VIEW`.
Verify:
```sql
SELECT name FROM sys.objects WHERE name IN ('payment_order','sp_payment_order','payment_reconciliation_vw');
```

## 2. Environment variables

Already present: `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`.
**New:** `RAZORPAY_WEBHOOK_SECRET` — the secret you set on the webhook in the
Razorpay dashboard. Without it, `/payments/webhook` returns 500.

## 3. Razorpay webhook URL

In Razorpay Dashboard > Settings > Webhooks, add:

```
URL:     https://chshub.co.in/payments/webhook
Secret:  <the same value as RAZORPAY_WEBHOOK_SECRET>
Events:  payment.captured   (payment.failed optional)
```

The endpoint is public by design (Razorpay sends no JWT) and authenticated by
the signature over the raw body.

## 4. Client contract (for when the app re-enables Razorpay)

The resident app's Razorpay code is currently commented out, so no client
change ships with this. When re-enabling, the app must:

1. `POST /payments/create-order` with `{ flat_id, bill_details }` (comma-separated
   `bill_no`s, <=20 chars). **Do not send the amount** — the server returns it.
2. Open Razorpay checkout with the returned `orderId`, `amount`, `keyId`.
3. `POST /payments/verify` with `{ razorpayOrderId, razorpayPaymentId, razorpaySignature }`.
4. Treat verify as confirmation, but the webhook is authoritative if the app is
   killed mid-payment. Stop calling `/insert/AddReceipt` and `/test/*` (both gone).

## 5. Reconciliation (read-only — never mutates financial data)

Primary report:
```sql
SELECT * FROM dbo.payment_reconciliation_vw WHERE issue <> 'ok' ORDER BY created_at DESC;
```
Covers: `paid_without_receipt`, `receipt_missing`, `amount_mismatch`,
`payment_id_unbound`, `failed_but_settled`, `stale_unpaid`.

Duplicate payment id across receipts (UNIQUE should prevent; verify):
```sql
SELECT transaction_ref, COUNT(*) n FROM dbo.receipt
WHERE transaction_ref LIKE 'pay\_%' ESCAPE '\'
GROUP BY transaction_ref HAVING COUNT(*) > 1;
```

Online-looking receipt with no matching order (pre-fix or manual):
```sql
SELECT r.receipt_id, r.transaction_ref, r.paid_amount
FROM dbo.receipt r
LEFT JOIN dbo.payment_order po ON po.razorpay_payment_id = r.transaction_ref
WHERE r.transaction_ref LIKE 'pay\_%' ESCAPE '\' AND po.payment_order_id IS NULL;
```

Investigate and correct by hand; do not auto-mutate.

## 6. Rollback

Code and data are decoupled and additive:
- **Code:** revert the commit. `/payments/*` disappears; nothing else regresses.
  (`AddReceipt`/`test/*` return to their prior behaviour — note that reopens the
  vulnerability, so prefer fixing forward.)
- **Data:** `payment_order` is a new table written only by the new routes;
  leaving it in place is harmless after a code rollback. Drop only if certain:
  ```sql
  DROP VIEW dbo.payment_reconciliation_vw;
  DROP PROCEDURE dbo.sp_payment_order;
  DROP TABLE dbo.payment_order;   -- loses the order audit trail
  ```
  No existing table or SP was altered, so there is nothing else to undo.

## 7. Deployment checklist

- [ ] Apply `SQL/ADD_payment_order.sql`; confirm the three objects exist.
- [ ] Set `RAZORPAY_WEBHOOK_SECRET` in the server environment; restart backend.
- [ ] Register the webhook URL + secret in the Razorpay dashboard.
- [ ] Smoke test in Razorpay test mode: create-order → pay → verify → confirm one
      receipt with `transaction_ref = payment_id` and the bill's `due` reduced.
- [ ] Repeat verify with the same payment → `idempotent:true`, no second receipt.
- [ ] Confirm `POST /insert/AddReceipt` returns 403 and `POST /test/create-order`
      returns 410.
- [ ] Run the reconciliation query; expect no rows for fresh data.
- [ ] `node backend/test/payments.test.js` green in CI.

## Known limitation

`sp_MaintenanceReceipt` derives `receipt_id` as `MAX(receipt_id)+1`. Under heavy
concurrency two settlements could collide on the PK; the transaction rolls back
and the call is retryable (the payment is not lost — the webhook re-settles).
If online volume grows, switch that id to an `IDENTITY`/`SEQUENCE`.
<!-- ponytail: MAX+1 receipt id, move to IDENTITY/SEQUENCE if online volume rises -->
