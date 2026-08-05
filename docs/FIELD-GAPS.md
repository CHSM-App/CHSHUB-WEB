# Field-level gaps — legacy vs migrated

The page-level migration is complete (all 104 `.aspx` accounted for), but a
page being present is not the same as every **field** on it being carried over.
This file tracks fields that the legacy screen captured and the migrated screen
does not.

Found by comparing input controls in the `.aspx` markup against the field names
used in `frontend/src`, then confirming each candidate by hand against the
stored procedure and the table columns. A name-based scan produces false
positives, so **nothing is listed here that was not read in the code.**

---

## Fixed

### 1. Family members lost occupation and date of birth

`owner_search.aspx` captured `txt_f_occu` and `txt_f_dob` and saved them via
`D_Update` (`f_occu`, `f_dob`). Both columns exist on `owner_extension`.

The migrated create path called only `AddFamilyMember`, whose `INSERT` names
just `f_name, relation, contactNo` — so occupation and DOB were **silently
dropped on every add**. The edit path (`PUT`) already sent them, so the fields
could be filled in only by adding a member and then editing it.

Neither SP branch does the whole job alone:

| branch | allocates `o_ex_id` | writes `f_occu` / `f_dob` |
|---|---|---|
| `AddFamilyMember` | yes | **no** |
| `D_Update` with `o_ex_id = 0` | no (table has no identity) | yes |

*Fix:* insert with `AddFamilyMember`, then apply the two fields with `D_Update`
against the id it allocated — `backend/web/routes/masters/family.js`.
Added to the grid and the add form in `OwnerDetailPanel.jsx`.

### 2. Helpers lost all five services and their charges

`servent_search.aspx` recorded five services, each a checkbox plus a rate:
preparing meal, cloth washing, utensil washing, floor washing, baby sitting.

All ten columns exist on `servent_maid_master` and all ten parameters exist on
`sp_servent_maid_master`. The migrated screen sent **none of them** — a helper
saved through the new UI kept name, mobile, address and remark only.

*Fix:* `HELPER_SERVICES` in `backend/web/routes/masters/misc.js` sends the flag
and charge pairs; the charge is zeroed when its checkbox is off. The screen in
`MasterPages.jsx` gained the five checkboxes, five charge inputs, a combined
"Services" column and a total-charge column.

`MasterScreen` had no render branch for `type: 'checkbox'` (it tracked checkbox
state but never drew one), so that was added too — available to every screen now.

*Not verified against live data:* `servent_maid_master` currently has zero rows
for every society, so this path could not be exercised end to end. The columns
and SP parameters were confirmed to exist; the round trip has not been observed.

### 3. Useful contacts lost the second address line

The API accepted `address2` and the SP has the parameter; the screen never
offered the input. One field added in `screens.jsx`.

### 4. Visitors was read-only — no register, edit, checkout or delete

`visitor_search.aspx` could add and edit visitors and stamp their exit. The
migrated screen had only `GET /visitors` and `GET /visitors/:id`; the whole
write half of the page was missing.

The per-type panels looked like four different forms, but the code-behind
assigned every one of them to the same three columns:

```
txtCabVehicle / txtServiceVehicle / txtDeliveryVehicle  -> Vehical_No
txtCabCompany / txtServiceCompany / txtDeliveryCompany  -> company
txtCabLocation / txtGuestAddress                        -> location
```

So the API takes one canonical shape and `VISITOR_TYPES` in the UI decides
which labels to show — rather than four near-duplicate forms.

*Added:* `POST /community/visitors`, `PUT /community/visitors/:id`,
`POST /community/visitors/:id/checkout` (SP branch `VisitorOut`, which stamps
`out_date`/`out_time` and sets `status = 3`) and `DELETE /community/visitors/:id`
(soft delete). All four confirmed reachable and auth-guarded.

One thing worth noting: `in_time`/`out_time` arrive from `<input type="time">`
as `"HH:MM"`, which `new Date()` cannot parse — the shared `date()` validator
would have rejected every save with a 400. `timeValue()` anchors the clock time
to a date before binding it to the `smalldatetime` column.

### 5. Field ORDER did not match the legacy forms

Separate from fields being absent: several screens had every field but in a
different sequence, so muscle memory from the WebForms app did not carry over.
Compared by reading control order out of the `.aspx` markup against the field
order in each screen.

| Screen | Legacy order | Was |
|---|---|---|
| `building_search` | name > print > **reg** > add1 > add2 > floors > bank > **bank address** > branch | reg had moved below floors; bank address absent entirely |
| `caretaker` | **flat** > name > address > area > mobile > email > city > pincode > **doc executed** | name first, flat last, doc executed absent |
| `car_polling` | name > vehicle > seat > **time** > date > destination > charges | destination before date; time absent |
| `InventoryMaster` | item > date > cost > quantity > warranty | quantity and warranty before cost |
| `VendorBill` | bill number > bill date > **service type** | service type first |

`bank_add`, `doc_executed` and `time` were all already accepted by the API — only
the inputs were missing.

One legacy field was deliberately **not** added: `txtWarrantyLastDate` on
`InventoryMaster`. There is no column for it (`inventory_master` has `warranty`
only, and `sp_inventory_master` has no matching parameter) — the legacy page
computed it from purchase date + warranty months. Adding an input would have
produced a control that silently discards what you type.

### 6. Bare clock times were rejected by the API

`<input type="time">` submits `"14:30"`, and `new Date("14:30")` is Invalid Date,
so the shared `date()` validator 400'd every such save. This affected car
pooling's `time` and meetings' `meeting_time` as well as the new visitor
in/out times.

Added `time()` to `lib/validate.js`: it anchors a bare `HH:MM[:SS]` to a date for
the `smalldatetime` columns, passes anything else through to `date()`, and
rejects out-of-range values. Verified against `14:30`, `09:05:30`, `00:00`,
`23:59`, a full date, blank, null and `25:00`.

### 7. Navigation and dashboard did not match Site.Master

The first styling pass matched colours and geometry but kept the migrated app's
own menu structure. It was wrong in shape, not just in skin.

**Sidebar.** Rebuilt from the `Site.Master` markup: the same two headings
(Interface / ADDONS), the same nine collapsible groups in the same order, the
same labels — including the legacy's own casing and punctuation, so
`vendor management` and `Assistant|Technician|Supplier` are reproduced verbatim
— and the same sub-headings (`Properties:`, `Masters:`, `Services:`). One group
open at a time, as `data-parent="#accordionSidebar"` enforced. The group holding
the current route opens on load, so a deep link or reload does not land fully
collapsed. Icons are inline SVG stand-ins for the Font Awesome glyphs — no CDN.

Items the legacy markup had commented out are left out here too, so the menu
shows what users actually see. All 43 links were checked against the routes
declared in `App.jsx`: no dead links.

**Topbar.** Red `.chs-logo` gradient (`#c94040 → #e85555`, 12px radius) — the
first pass had guessed blue — plus the white `.society-name-pill` and a profile
dropdown with Profile / Settings / Log Out. Logout keeps the legacy
`confirm('Are you sure you want to log out?')`.

`account_setting.aspx` was never in the legacy sidebar; it hung off this
dropdown, and it does here too.

**Dashboard.** Rebuilt against `dashboard.aspx` rather than from the screenshot,
which showed only part of the page.

Structure is `.layout-container` verbatim — `grid-template-columns: 2fr 1fr`,
16px gap:

* **left** — three headline tiles, Maintenance Tracker, then PDC Clearing /
  Weekly Updates / HelpDesk Ticket
* **right** — Recent Activity (scrolling at the legacy's fixed 226px) above the
  Income Tracker donut

Details that needed the markup, not a guess:

* `ToShortNumber()` (dashboard.aspx.cs:306) **truncates**, and uses k/M/B —
  not Indian L/Cr, and not rounding. Ported and checked against the live figure:
  `288638.66 → 288.6k`, matching the screenshot exactly.
* The Due Payments tile plots the IncomeChart **`Due`** value (288,638.66), not
  the defaulters roll-up (271,659.25) — two different numbers.
* Recent Activity rows are `particular` / `timestamp` / `paid_amount`. An
  earlier pass read `title`/`date`/`amount`, so every row would have rendered
  blank. The icon and amount colour key off `paid_amount` — zero gives a blue
  tools glyph and a date, non-zero a green tick and the amount — as the
  GridView's inline `Eval` did.
* Only Due Payments and Total Members were links in the legacy page; the
  Defaulters tile was not.
* Regular / Add on drive the tracker series (Regular = `Get_Month`,
  Add on = the expense chart). Unticking both empties the chart, as before.

`Updates` (Weekly Updates) had no endpoint at all — added to
`GET /reports/dashboard` as `weeklyUpdates`. The SP branch runs clean but
returns no rows for the test societies, so the card renders its "No Updates"
state; the populated state has not been seen.

Verified against the live database for C10001: tickets 13/8, residents 10,
defaulters 10, due 288,638.66 — the same figures as the screenshot.

**Page background corrected.** The first pass set `#ecf0f1` from
`css/layout.css`. That value belongs to `.helpdesk-card`, not the page —
sb-admin-2's `body` rule sets type and colour but no background, so the legacy
app is white. Fixed.

### 8. "Download PDF" was missing from every page

Auditing legacy **actions** (button text) rather than fields found the largest
single gap: **26 pages** carried a "Download PDF" / "Download Report" button and
the migrated app had no PDF export at all. `jspdf` and `html2canvas` were not
even installed, though `PARITY-CHECKLIST.md` described print output as
"jsPDF where a file download is wanted".

The legacy pages did this client-side with jsPDF + html2canvas
(`Defaulter.aspx`, `owner_search.aspx`, the `print*` pages), so the same
approach is used rather than adding a server-side renderer.

`src/lib/pdf.js` provides two exports:

* `tableToPdf` — grid data straight to a PDF. Preferred for grids: the output
  is selectable text at a predictable width, where an html2canvas capture would
  be a bitmap of whatever was on screen, missing rows scrolled out of view.
  Paginates, repeats the header row, honours each column's `exportValue`.
* `elementToPdf` — html2canvas capture for report and print views, where the
  on-screen layout *is* the document. Slices tall captures across pages.

`DataGrid` now shows all three actions the legacy grids had — **Export to
Excel** (renamed from "Export CSV" to match), **Download PDF** and **Print** —
so every grid in the app gained them at once.

Both libraries load dynamically and were given their own rolldown chunk;
without that the catch-all `vendor` group swallowed them and every visitor
downloaded ~730 kB to render a login page. Vendor is back to 73 kB and
`pdf-vendor` is not referenced by `index.html`.

Covered by `src/lib/pdf.test.js` (headers, rows, dated filename, `exportValue`,
empty rows).

### 9. Income Tracker period menu was missing

The ⋮ menu on the Income Tracker card (This Month / Last Month / This Year) had
no equivalent. Added, backed by a new `GET /reports/income-split?to=`.

Two legacy quirks are reproduced rather than corrected, so the figures agree
with the old dashboard:

* `sp_dashboard`/`IncomeChart` **ignores `@date1`** — it overrides the start
  with `MIN(gen_date)` and applies only `@date2`. The period therefore changes
  the end date alone.
* `due_last_month_Click` passes the *same* end date as `due_this_month_Click`
  (it varies only `date1`, which the SP discards), so "This Month" and "Last
  Month" return identical numbers.

Verified against C10001: both periods return Due 288,638.66 / Collection
72,964.65 — every bill there predates the window, so the totals genuinely do
not differ on this data.

### 10. Staff bill numbers had to be typed by hand

`VendorBill.aspx` generated them as `STAFF-{roleId}-{yyyyMM}-{HHmmss}` from the
payment month. The migrated screen required manual entry. A "Generate staff bill
number" action now reproduces the legacy format; the field stays editable.

---

## Not gaps — checked and dismissed

| Reported | Why it is not a gap |
|---|---|
| `BalanceSheet` — `rbLiability`, `rbAsset`, `txtHeaderTitle` … | Implemented in `AuditBalancePages.jsx` under different names |
| `owner_search` / `rental_search` — `txt_add_mob` | Present as "Alternate mobile" |
| Generic `TextBox1`, `CheckAll`, `chk` | Visual Studio default names — grid select-all boxes and layout controls, not data fields |
| `Contact_OTP`, `Email_OTP` | OTP flow is unchanged and still served by the mobile API |
| `VendorBill` — staff salary run (`chkSelectAllStaff`, `txtSalary`) | Migrated as `SERVICE.STAFF` with a staff-id → salary map |

### `VendorBill` split payments — the scan was wrong

`txtamtcash`, `txtcheqamount` and `txtonlineamount` look like a payment split
across three modes at once, which the migrated single-mode `ModeSwitch` would
not support. They are not.

* `vendor_bill_payments` has one `pay_mode` and one `paid_amount` — there are no
  per-mode amount columns to split into.
* The code-behind sets all three boxes to the *same* `RemainingAmount`
  (`VendorBill.aspx.cs:1526-1528`).
* Validation only ever checks the amount belonging to the visible panel
  (`pnlPayCheque` / `pnlPayOnline` / `pnlCash`).

They are per-mode aliases for one amount, so the existing `ModeSwitch` design is
correct. **No change made** — worth recording, because "add split payments"
would have been a plausible-looking change that corrupted the payment model.

---

## Still open — not yet investigated

Reported by the scan, **not yet confirmed either way**. Each needs the same
treatment: read the legacy `.aspx`, the SP and the table before deciding.

### Actions still unmatched

Auditing button text found 62 legacy actions with no textual match in the
frontend. PDF export accounted for 26 pages and is now done; **59 remain across
42 pages**. As with fields, each is a *candidate* — some will be present under a
different label, so none should be "fixed" before reading the legacy handler.

Ranked by how much is missing from one screen:

| Page | Unmatched actions |
|---|---|
| `v_tax_payment` | Pay All, Send SMS, Process Payment, Print Receipt |
| `Audit` | View Audit Form, + Add New, Save Sequence |
| `BalanceSheet` | + Add New Entry, Save Sequence, + Add Subpoint |
| `homeTax` | Submit Payment, Print Receipt |
| `house_tax_receipt` | Verify & Proceed, New Entry |
| `society_expense` | Add Approver, Not Approved |
| `society_receipt` | View Details, Submit Payment |
| `support_ticket` | View Image, Send |
| `vendor_bill_payments` | Save Payment, New Payment |
| `village_master`, `village_owner_master` | Import Data From Excel |
| `Vote` | Start Poll |
| `v_resident` | Save All Changes |

`login1` / `new_registration` / `verifyOTP` also report gaps (`visibility`,
`Verify`, `Resend OTP`), but `visibility` is a show/hide-password icon and the
OTP flow still runs on the unchanged mobile API — those are likely false
positives.

The Excel **import** on the two village pages is the only one that implies a
capability the app does not have at all (there is an upload API, but no
spreadsheet parser).

To re-run: `node <scratch>/audit.js`.

### Fields still open

| Page | Candidate fields |
|---|---|
| `VendorBill` | inline "new vendor" sub-form (`txtNewVendorName` … `txtNewVendorGST`) — vendors can still be created on the Vendors screen, so this is a convenience gap at most |
| `user_login` | designation, department, manager, branch, join/leave dates |
| `society_receipt` | payment mode and its per-mode reference fields (UPI, card, bank, wallet) |
| `pdc_reminder_search` | deposit / return / bounce state flags |
| `v_resident` | sqft, tap count, tap charges, solid-waste fee |
| `new_society` | district, division, street, per-sqft and vehicle rates, bill generation day |
| `society_expense` | regular vs add-on split, approver amount |
| `Facility_master` | slot radio group, "to" time |

`society_receipt` is the one to look at next: per-mode reference fields are the
same shape as the visitor per-type panels, so it may be aliases over one column
— or it may be a real gap. It needs the table checked before assuming either.

## How to re-run the scan

```
node <scratch>/fieldgap.js
```

It prints, per page, the legacy control IDs that appear nowhere in
`frontend/src`. Treat every line as a *candidate*, never as a confirmed gap.
