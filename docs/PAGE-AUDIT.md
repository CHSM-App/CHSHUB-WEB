# Per-page audit — all 104 legacy pages

Every legacy `.aspx` checked field-by-field, action-by-action and
column-by-column against the migrated screen.

**Method.** Input controls, button text and grid headers are extracted from the
`.aspx` markup and looked up in `frontend/src`. That produces *candidates*, not
findings — a name-based check cannot see a renamed field. Every candidate below
was then read against the legacy **code-behind** and the **database** before
being classified. The classification, not the scan, is the result.

Re-run the scan with `node <scratch>/fullaudit.js`.

## Result

| | Pages |
|---|---|
| Nothing outstanding | 26 |
| Candidates raised by the scan | 78 |
| **Verified against the live schema** | **all of them** |
| → confirmed real | **2** — both now **built** |
| → already fixed this session | 9 |
| → false positives | the rest |

**Both confirmed gaps are closed.** Village tax payment is built and guarded
behind a flag pending a test-database run; poll creation is built and live.

**The raw scan overstates the problem by an order of magnitude.** Every
candidate was put through three tests against the real database:

1. Does the legacy code-behind actually *read* the control, or is it decorative?
2. Does a **column** exist for it?
3. Does the website API already send that column?

Only a candidate that passes all three is a gap. Of ~56 field candidates checked
column-by-column, **the overwhelming majority have no column at all** — they
were UI-only controls in the legacy page. Examples confirmed absent from the
schema: `society_master` has no `district`, `division`, `street`, `per_sqft_rate`,
`gen_day`; `usefull_contact` has no `org_tel`/`org_addr1`/`org_addr2`;
`pdc_reminder` has no `chq_amount` or bounce flags; `UserLogin` has no
`designation`, `manager`, `join_dt`.

Building those would mean inventing columns the original never had.

---

## Confirmed NOT gaps — verified against code-behind and schema

These looked like gaps and are not. Recorded so they are not "fixed" later by
someone reading the raw scan.

### `society_receipt` — UPI / card / bank / wallet reference fields

`txtUPIId`, `txtCardNumber`, `txtBankRef`, `txtWalletTxn`, `txtGatewayRef` are
rendered by the page but **never read by `society_receipt.aspx.cs`** — no
assignment, no parameter, nothing. The `society_receipt` table has a single
`paymode` column and no reference columns at all.

They are decorative inputs that save nowhere. Reproducing them would add five
boxes that silently discard what the user types.

### `v_resident` — sqft / tap / charge fields

`txtHouseSqft`, `txtSqftCharges`, `txtNoOfTaps`, `txtTapCharges`,
`txtSolidWasteFee` *are* saved by the legacy page, and the columns exist
(`house.area`, `gharpatti_charges`, `no_of_tab`, `water_charges`,
`waste_charges`).

But they are house attributes, not resident attributes, and the migration put
them on **`/village/houses`**, where the API (`houseParams`) already sends all
five and the screen already offers all five. Consolidated, not lost.

### `village_master`, `village_owner_master` — "Import Data From Excel"

Both handlers are empty in the legacy source:

```csharp
protected void btn_import_Click(object sender, EventArgs e)
{ }
```

The button exists and does nothing on **those two pages**.

**But `society_search.aspx`'s Import is real** — see below. The two must not be
confused: same button label, one a stub and one a working feature.

### `VendorBill` — cash / cheque / online amount boxes

Covered in `FIELD-GAPS.md`: per-mode aliases for one amount, not a split
payment. `vendor_bill_payments` has one `pay_mode` and one `paid_amount`.

### `society_expense` — regular vs add-on, approver amount

Fully migrated. `SocietyExpensePage.jsx` carries `regular` and `finalAmount`,
and the API sends `regular` and `f_amount`. The scan missed it because the
legacy controls are named `regular_chk` / `txt_famount` and the React fields are
`regular` / `finalAmount`.

### `user_login` — designation, department, manager, branch

Not reachable. `user_login.aspx` appears **zero times** in `Site.Master` — it is
not on the legacy menu, and the fields belong to an internal staff-directory
form that the society admin surface never exposed. Nothing to migrate unless you
say that page should exist.

### Generic control names

`CheckAll`, `chk`, `CheckBoxList1`, `TextBox1`, `radiobtn1`, `calendarRange`,
`visibility` — grid select-all boxes, layout controls and a show/hide-password
icon. Not data fields.

---

## Confirmed real gaps

### `visitor_search` — write path (FIXED)

Was read-only; register / edit / checkout / delete added. See `FIELD-GAPS.md` §4.

### `v_tax_payment` — payment workflow — **BUILT**

The migrated `/village/payments` was **read-only**: it listed pending charges
and receipts with no way to take a payment.

Legacy flow (`btnPayModal_Click`): select bills → pay mode → transaction ref or
cheque number/date → `sp_house_tax_receipt` / `Update_Payment`.

**Added:** `POST /village/house-tax/pay`, plus a pay modal on the pending grid
that lists a house's unpaid bills, ticks them individually or all at once, and
switches its fields on the payment mode.

Points that needed the SP read rather than assumed:

* `Update_Payment` takes a **comma-separated list** of `house_receipt_id` and
  cursors `House_wise_payment_vw`, paying each bill its **full**
  `pending_amount`. There is no partial payment — the UI says so rather than
  offering an amount box that would be ignored.
* Modes are `1 Cash · 2 Cheque · 4 UPI` (not 1/2/3), taken from
  `ddlPaymentMethod`.
* The SP scopes by `village_id` but will accept any id in the list, so the
  endpoint first checks every id belongs to this village and is still unpaid,
  and rejects the request otherwise.

Legacy validation kept: reference mandatory for UPI/cheque, cheque number
mandatory for cheque.

**Guarded.** Like bill generation and receipt entry, the Pay button is disabled
behind `VITE_ENABLE_VILLAGE_PAYMENTS` until the flow has been run against a test
database. The API is complete and validated; it has **not** been executed
against live data — that would move real money.

`homeTax` and `water_tax` use the same SP and endpoint, so they are covered by
the same work.

### `rental_search` — no PDF, missing columns, no View Docs — **FIXED**

Reported as "no PDF download on rental search". Three findings.

**1. The page never had the export buttons.** `DataGrid` grew "Export to Excel",
"Download PDF" and Print, but `ResidentsPage` (which serves both
`/masters/owners` and `/masters/tenants`) renders a **hand-rolled `<table>`**, so
it inherited none of them. Converted to `DataGrid`.

**2. Two grid columns were missing.** `rental_search.aspx`'s grid shows
**Sq.ft** and **Type**; `sp_owner_master/Grid_Show` already returns `sq_ft` and
`flat_type`, and the API already passed them through — nothing displayed them.

**3. "View Docs" did not exist.** The legacy grid had a per-row button opening
three uploaded files — ID proof, rent agreement and police verification
(`rental_search.aspx:285-292`). The API stores and returns all three paths
(`id_proof`, `agreement_path`, `police_verification_path`) and there is a
file-serving endpoint, but no screen exposed them. Added as a per-row action
that lists whichever of the three exist; the button is hidden when a resident
has none.

The existing `ResidentsPage` tests needed updating, not the code: `DataGrid`
renders a table row **and** a card for the same record (the card is the
below-`sm` layout), so names and row actions legitimately appear twice.

### Notice / Event / Meeting notifications — **BUILT, blocked by a dead Firebase key**

Asked whether creating a notice, event or meeting sends a notification. It does
not — **and it never did, in the original app either.**

The legacy code looks complete:

```csharp
var result = bL_Notice.updateNoticeDetails(notice);
foreach (DataRow row in result.Rows) {
    notice.User_Id  = row["user_id"];
    notice.UserType = row["type"];
    bL_Notice.send_notification(notice);    // DB record
    generate_notification(row["token"]);    // FCM push
}
```

But `sp_notice_master/Update` returns a single recordset of **`notice_id`
only** — no `user_id`, no `type`, no `token`. Confirmed by executing it:

```
recordsets returned: 1
  [0] 1 rows, cols: notice_id
```

So the loop body never runs. `sp_event_master` and `sp_meeting_master` don't
mention `token` or `user_id` in their Update branches at all. All three pages
have had dead notification code since before the migration.

The parts exist — `sp_notification` (with `Notice`, `Event`, `GetNotifications`
branches), the `notification_union` / `notify_status` tables, and a working FCM
sender in the mobile API (`routes/notify.js:28`). Only the wiring is absent.

**Built at the user's request**, to send to real residents. `web/lib/notify.js`:

1. **Resolve recipients** per group — 1 Owners, 2 Tenants, 3 both, 4 Members —
   with a direct query, since no SP returns them. Rows without a token are
   dropped, and one device serving two records (an owner who is also a
   committee member) is de-duplicated by token.
2. **Record** each one through `sp_notification/Update`, so the app's in-app
   list holds it even if the push fails.
3. **Push** via `admin.messaging().sendEachForMulticast`, reusing the Firebase
   app `routes/notify.js` already initialises — calling `initializeApp` twice
   throws, so the module reuses the default app when one exists.

Notification happens **after** the save and can never throw: the endpoints
return a `notified: {sent, failed, recipients}` summary so a failure is visible
rather than silent. Events and meetings have no recipient picker on their legacy
pages, so both address group 3.

**It will not deliver yet — the Firebase service account key is rejected:**

```
invalid_grant: Invalid JWT Signature
project society-management-32053, key 93816ad8df…
```

Both copies of `serviceAccountKey.json` carry the same dead key, so this
predates the migration and breaks the mobile API's notifications too. Verified
end to end: `notifyGroup` resolved all 7 recipients and returned
`{sent: 0, failed: 7, recipients: 7}` **without throwing**, so a dead key cannot
lose a notice.

**To finish:** generate a new service account key in the Firebase console for
`society-management-32053` and replace both files. Nothing in the code needs to
change. (See also the security note about those keys being committed to git.)

### `contact_master` — wrong layout, and the list was empty — **FIXED**

**The list returned nothing.** The endpoint lists through the SP's `Search`
branch (`Grid_Show` returns no rows), but never sent `@search`. That branch
matches `LIKE @search + '%'`, and `LIKE NULL` matches nothing — so the screen
showed an empty state while the society had **18 contacts**. Sending `''`
returns them all; `simpleCrud` gained an `alwaysSendSearch` flag for it, and
contacts is the only screen using that pattern.

**The layout was a table; the legacy page is a card grid.** `contact_master.aspx`
titles itself *Assistant Contact* and lays contacts out four to a row, each card
showing the name, the type beneath it, then organisation, phone, email, address
and remark against an icon.

Rebuilt as `ContactsPage.jsx` with that design, values from the legacy
stylesheet: `linear-gradient(145deg, #ffffff, #f8f9fa)` card, `#e9ecef` border,
a `#667eea → #764ba2` accent bar that scales in on hover, an 8px lift, `#667eea`
icons, `#1a1a1a` name and `#6c757d` type. Breakpoints match too — 4 per row,
2 on a tablet, 1 on a phone. Detail rows with no value are omitted rather than
printed as dashes.

Icons are inline SVG rather than Font Awesome, so nothing is fetched from a CDN.

**The add form was missing its file upload.** `contact_master.aspx` has a
`FileUpload` writing to `id_path` (`contact_master.aspx.cs:154, 179`). The API
accepted `idPath` all along, but the form never carried it — the same
silent-clear pattern already found on owners and staff, and **10 contacts in
C10001 already hold a document** that editing would have erased.

Added the upload, plus a **View ID** action on cards that have one. Paths here
show the same four shapes as elsewhere — two are absolute Windows paths on the
old server (`D:\VengurlaTech\…`), which cannot be served over HTTP, so the
viewer says so rather than opening a dead frame.

Field order and placeholders now follow the legacy modal: name, type,
organisation, mobile, email, remark, address 1, address 2, upload.

Covered by `ContactsPage.test.jsx` (5 tests): card rendering, omitting empty
detail rows, View ID appearing only with a document, the disk-path explanation,
and the form carrying all nine legacy fields.

### `facility_booking` — no Add button — **FIXED**

The screen was read-only, with a comment asserting that "residents create them
from the mobile app". That was wrong: `facility_booking.aspx` has an **Add**
button, and `sp_facility_booking` carries every branch needed —
`Update` (inserts when the id is 0), `fill_facilities`, `fill_owner`,
`GetCharge`, `CheckAvailability`.

Added `POST /community/facility-bookings` plus two lookup endpoints, and the
form as the legacy page has it — same fields, same order, same labels and
placeholders:

```
Facilities · Date · Resident · Flat no · Name · Contact No · Address ·
From Date · To Date · From Time · To Time · Charges · Note to Admin · In Society
```

All 14 map to `sp_facility_booking` parameters. Behaviours carried over:

* picking a **resident** fills flat, name, contact and address
* **Flat no** is read-only — on the legacy page `txt_flat` is display only and
  the save uses the hidden `flat_id` behind the picker
  (`facility_booking.aspx.cs:156, 243`), never the typed text

**Charges are computed, not copied.** The first pass put the facility's raw cost
in the box. The legacy rule (`facility_booking.aspx.cs:505-535`) is:

```
cost 0     -> "Free"
otherwise  -> cost × days + 18% GST,  days inclusive of both ends
              "Invalid date range" when To precedes From
```

The box is read-only and shows the working, with the figure after `=` being
what is saved — reproduced here, including refusing to save an invalid range.

Checked against a booking already in the database: Wedding hall at ₹20,000 for
one day stores **23,600**, and the formula returns exactly that. Three days
gives 60,000 + 10,800 = 70,800.

**Grid columns** differed from the legacy grid — `Building` was missing and the
labels did not match. Now: Name · Building · Unit · Phone · Facility · Date ·
Time · Charges.

**New bookings saved with `flat_id = 0`**, so Building, Unit and Phone came back
blank on the grid. The SP is inconsistent between its two paths:

```sql
-- insert
INSERT INTO facility_booking (…, flat_id, …) VALUES (…, @flat_no, …)
-- update
UPDATE facility_booking SET … flat_id = @flat_id …
```

The insert takes the flat from **`@flat_no`**, the update from `@flat_id`.
Sending only `@flat_id` — the obvious choice, and the one the column is named
after — left new rows at 0, and `facility_booking_vw` joins `owner_search_vw` on
`flat_id` to supply exactly those three columns. Both parameters are now sent.

Verified by inserting through the SP and reading the grid back: the row lands
with `flat_id = 5` and shows *Kohinoor Square / A-1 102 / 9096531563*. The test
row was deleted afterwards.

**Search** matched by prefix only in the SP (`LIKE @search + '%'`), so "edding"
found nothing while "Wedding" found five. Filtered in the endpoint instead, so
it matches anywhere — consistent with every other screen.

Verified against live data: 12 facilities, 16 residents, 7 bookings.

**Not reproduced:** the slot grid. `facility_booking.aspx` shows selectable time
slots for slot-based facilities, but `facilitySlotBooking` holds **zero rows in
the whole database** and no facility in C10001 uses slot booking (`slot` is 1
Day or 2 Hour throughout, never 3 Slot), so `GetSlots` returns nothing to build
it from.

Times go through `time()` rather than `date()` — `from_time`/`to_time` arrive as
`HH:MM` from `<input type="time">`, which `new Date()` cannot parse.

### `parking_allotment_search` — assignment silently did nothing — **FIXED**

Reported as "add doesn't work, and there's no edit". Both were real, and the
first had a cause worth spelling out.

**Why nothing saved.** `AssignPlace` is only:

```sql
UPDATE vehicle SET park_place_id = @place_id
WHERE vehicle_no = @vehicle_no AND flat_id = @flat_id
```

It never inserts. Vehicles are registered separately; allotment just stamps a
place onto an existing row. The form let you *type* a vehicle number, so
anything not already registered against that flat matched no row — the SP
returned success and changed nothing.

**The form now cascades resident → vehicle → place**, as the legacy page did:

1. **Resident** — was a raw "Flat ID" number box requiring an internal id;
   `fill_owner` lists residents by name (16 for C10001) with the flat behind.
2. **Vehicle** — a dropdown of *that flat's* vehicles with no place yet
   (`fill_vehicle`), not free text. This is what makes the save actually work.
3. **Parking place** — filtered to the chosen vehicle's type. Bike and car bays
   are separate: for C10001, 7 free bike places and 5 car places.

Each step clears the ones after it, so a stale pair cannot be submitted. The
assign endpoint also checks the vehicle exists first and returns a clear message
instead of a silent no-op.

**Edit** was missing entirely — only Release existed. Added: it reopens the same
form pre-filled, since `AssignPlace` overwrites `park_place_id` and re-allotting
is the same call.

Pre-filling took three fixes, because every list on the form is a list of what
is *free*, and an existing allotment is by definition not:

* `Grid_Show` returns `parking_no` (the label) but **not `place_id`** (the value
  the dropdown binds to), so the place could never be preselected. The endpoint
  now reads `Vehicle.park_place_id` and adds it to each row.
* `fill_vehicle` omits the vehicle (it has a place) and `fill_place` omits the
  place (it is taken) — both are carried in from the grid row and prepended, or
  the form opens blank on values it already holds.
* The place list is filtered by the vehicle's type, which is read from
  `fill_vehicle` — absent here for the same reason, so the type comes from the
  row instead.

Switching the vehicle mid-edit discards all three, since bike and car bays are
different lists.

**Tenants appeared where the owner belongs.** Reported as "selecting Rohit shows
Bhushan", then settled as: the list should show **owners only**.

`fill_owner` is `SELECT flat_id, name FROM owner_master WHERE society_id = @…`
— no filter on `type`, so it returns owners *and* tenants. Six flats in C10001
hold both, so the dropdown had two entries carrying the **same `flat_id`**,
which a dropdown cannot tell apart: picking either resolved to the first.

Parking belongs to the flat, and the flat belongs to its **owner**, so that is
the name to show. Both the dropdown and the grid now resolve the name from
`sp_owner_master/Grid_Show` with `type = 'Owner'`, keyed on `flat_id`, rather
than taking whichever row the SP happened to return first. 16 rows become 10
owners; the grid's 6 rows become 4.

Checked first that the data supports it: every flat in C10001 has **exactly one**
owner row — none missing, none duplicated. A flat with no owner row falls back
to whatever `fill_owner` gave, rather than dropping out of the list.

One result looks wrong but is not: "Vihan Raut" is still listed. There are two
different people with that name — a tenant on flat 2 (`owner_id` 91) and an
owner on flat 39 (`owner_id` 27). He appears for flat 39 only, which is correct.

**Parking still cannot be allotted to a *person*** — only to a flat:

```
Vehicle: vehicle_id, vehicle_no, model_name, society_id, flat_id,
         vehicle_type, park_place_id        -- no owner_id
```

`sp_parking_master` has no owner/resident parameter, `sp_parking/VehicleList`
selects by `flat_id` alone, and the mobile app's own insert
(`Insertfamilyvehicle`) writes no owner either — even though `AddVehicle` sends
one. `parking_master` *does* carry an `owner_id` column, but it holds zero rows
and the live SP never writes to it: the per-person design was started and never
finished.

Per-person allotment would mean a new column on `Vehicle`, changes to two SPs,
**and** a matching change in the mobile app — otherwise app-registered vehicles
would have no owner and vanish from the screen. A schema change, so **not done**.

**Search was missing.** The legacy page had one; this screen did not, unlike
every other list screen. Added in the standard position — search box then
action button in `PageHeader`.

The SP's own `Search` branch is unusable: it queries **`parking_master`**, which
holds zero rows, while the grid comes from **`Vehicle`** — so it returns nothing
for any term. Filtering happens in the endpoint instead, across **every column
the grid shows**, so searching for what is on screen works: owner, vehicle,
parking number, model, **type (Car/Bike)** and contact.

The type column was missed on the first pass — typing "Car" matched no field, so
the filter fell through and the screen looked unfiltered. Verified against live
data: `Car` → 3, `Bike` → 1, `bhushan` → 2, `P008` → 1, `nexon` → 1,
`8262` → 2, and a term matching nothing → 0 rather than everything.

One thing to get right: the owner list must not be refetched on every
keystroke. `load` changes with the search term, so the lookup fetch was split
into its own effect rather than left sharing `[load]`.

**One place could be allotted twice.** `AssignPlace` writes `park_place_id`
with no check that another vehicle already holds it, so two vehicles could end
up on one bay. The dropdown only offers free places, but a stale form or a
direct call would have gone through. The endpoint now rejects it by name —
*"Parking place P002 is already allotted to MH07P2324"* — while still allowing a
vehicle to be re-saved onto its own place.

**The grid listed each vehicle once per occupant.** Reported as "Bhushan's
vehicle also shows against Rohit". `Grid_Show` joins
`owner_master ON o.flat_id = v.flat_id`, which is one row per *person* living in
the flat, not one per allotment. Flat 7 has an owner (Bhushan) and a tenant
(Rohit), so both of its vehicles appeared twice — looking as though the same
vehicle and place were allotted to two people.

`Vehicle` held a single correct row throughout; only the display was wrong.
Collapsed to one row per vehicle, preferring the owner's name, resolved against
`owner_master` rather than by trusting row order the SP does not guarantee.
For C10001 that turns 6 rows into 4.

Three things the SP had to be read for, all of which name-based guessing gets
wrong:

* `fill_place` filters `park_for = @vehicle_id` — despite the name, that
  parameter carries the **vehicle type** (0 bike, 1 car), not a vehicle id.
  Passing `@park_for` returns every place regardless of type.
* The usable branch is `fill_place`; `fill_parking_place` duplicates it and
  `fill_park` returns nothing.
* `sp_parking_master` contains a **complete commented-out copy** of every
  branch above the live ones. Reading the first match finds dead code — the
  first `AssignPlace` in the file is inert.

### `Staff_Master` — Attendance column missing — **FIXED**

Mostly already correct: the routed screen (`MasterPages.StaffMasterPage`) has
all nine fields the legacy code-behind saves — name, role, address, contact,
email, date of join, salary — **including** the photo and ID-proof uploads, with
`id_path` mapped correctly (the column is `id_path`, the SP parameter is
`@id_proof`).

The gap was the grid's **Attendance** column, which opened that member's punch
log. `GET /masters/staff/:id/attendance` existed and returns real data — 23 rows
for staff 1 — but nothing in the app called it. Added as a per-row action
opening the log (in/out date and time, hours), with its own export.

Print and Excel export were already present via `MasterScreen`'s `exportName`.

### Viewing a stored file — "View ID" and "View Docs"

`Staff_Master.aspx` had a per-row **View ID** link opening `id_path` in a modal;
nothing in the migrated app did. Added, along with fixing the owners/tenants
**View Docs** list that had the same two problems.

**Protected files need the token.** Files served by this API sit behind the
bearer token, and neither `<iframe src>` nor `<a href>` sends an Authorization
header — pointing them at `/api/web/uploads/file/...` returns

```
{"ok":false,"error":{"message":"Missing Bearer token","code":"UNAUTHORIZED"}}
```

`fetchProtectedUrl` pulls the file through the axios client (which attaches and
refreshes the token) and hands back a `blob:` URL the iframe can show. The URL
is revoked when the modal closes or the row unmounts, so nothing leaks.

**Stored paths come in four shapes**, written by three generations of the app —
all four are present in `staff_master` today:

| Value | Handling |
|---|---|
| `staff/1785921102958-527564359.pdf` | uploaded here → served via the API, with auth |
| `https://app.chshub.co.in/upload/...` | absolute URL → linked directly |
| `/Documents/Docs/Gokuldham/StaffDetails.pdf` | legacy web path → root-relative link |
| `D:\VengurlaTech\...\MaintenanceReport (1)(3).pdf` | **a path on the old server's disk** |

The last is not reachable over HTTP at all. Rather than render a frame that
fails, the viewer explains that the file was recorded as a path rather than
uploaded, and suggests re-uploading. Two staff rows are in exactly this state.

`src/lib/storedFile.js` holds the resolver, covered by 16 tests built from the
real values above.

### Duplicate, unrouted screens

Found while checking staff: `screens.jsx` exports a `StaffPage` that **no route
renders** — `/masters/staff` uses `MasterPages.StaffMasterPage`. I edited the
dead one first before noticing, and reverted it.

There are **11 exported screen components with no `<Route>`**:

```
ErrorPages.jsx      ServerErrorPage
ReadOnlyPages.jsx   InventoryPage, CommitteePage, VillageOwnersPage,
                    VillageHouseTaxPage, VillageWaterTaxPage,
                    VillageHouseTaxReceiptsPage
screens.jsx         StaffPage, HelpersPage, ExpensesPage, FacilitiesPage
```

These are earlier versions superseded by richer ones. They are dead weight and,
worse, a trap: editing one looks like fixing a screen and changes nothing.
`StaffPage` now carries a comment saying so.

**Not deleted** — that is a call for you to make, not a side effect of a bug
fix. Say the word and they go.

Re-run the check with `node <scratch>/deadscreens.js`.

### `Facility_master` (amenity) — "slots" was the wrong field — **FIXED**

The form offered **"Number of slots"** as a free number. `facilities.slot` is
not a count: `Facility_master.aspx` renders a **Day / Hour / Slot radio group**
and the code-behind stores a 1/2/3 code for it
(`radiobtn1 ? 1 : radiobtn3 ? 2 : 3`, `Facility_master.aspx.cs:63`).

Confirmed in the data — every row in `facilities` holds 1 or 2, never a count:

```
Wedding hall 1 · Swimming Pool 2 · yoga 1 · Public libraries 1
```

So typing "20 slots" would have written 20 into a column that only means
Day/Hour/Slot. Replaced with a **Booked by** dropdown; the grid column now shows
the label instead of a bare number.

### `park_place_search` — "import data" button missing — **FIXED**

The legacy page has an **import data** button whose handler *is* live — it reads
the uploaded workbook over OLEDB and inserts each row
(`park_place_search.aspx.cs:213`). Nothing in the migrated screen offered it.

Its sheet is matched by **header name** (`row["Parking Number"]`), not by column
letter like the society imports, so `ExcelImport` gained a `headerColumns` mode
alongside the existing letter mode. Two columns: *Parking Number* and *Park For*
(0/Bike or 1/Car — both the code and the word are accepted, since a
hand-made sheet could hold either).

`GenericCrudPage` gained `headerActions` and `children` so a screen can add a
toolbar button and its dialog without being rewritten.

### `society_member_search` — add/edit/delete missing — **FIXED**

The committee members screen was **read-only**: no Add, no Edit, no Delete,
though the legacy page had all three plus a login for each member.

Added `PUT /masters/members/:id` and `DELETE /masters/members/:id` (soft delete
via the SP's `Delete` branch) to go with the `POST` built for the Excel import,
and a full add/edit form: resident, designation, contact, email, username,
password.

**The form shape was wrong on the first pass.** `society_member_search.aspx` has
*two* pickers, not a free-text name:

| Legacy control | Source | Purpose |
|---|---|---|
| `categoryRepeater1` | `sp_UserLogin/fill_owner` | pick the **resident** — fills contact, email and username from their record |
| `categoryRepeater2` | `sp_UserLogin/fill_type` | pick the **designation** (`UserType`) |

The save also stores `member.Owner_id` — the link back to that resident — which
the first version of the endpoint dropped entirely. Both create and update now
send it, and the UI reproduces the auto-fill
(`CategoryRepeater_ItemCommand1`, `society_member_search.aspx.cs:63`).

**Edit did not populate the Name picker.** The list branch (`Grid_Show`) does
**not** return `owner_id`, so opening the form from a grid row left the resident
unselected — and saving would then have sent `ownerId: 0`, unlinking the member
from their resident record. `Select` does return it, so editing now loads the
member through a new `GET /masters/members/:id` instead of reusing the row.

Verified against C10001: `Grid_Show` has no `owner_id` column at all, while
`Select` returns 27, 5 and 9 for the first three members.

**Password fields gained a show/hide toggle**, matching the `visibility` icon on
the legacy login and member forms. Added to `TextField` itself rather than to
one screen, so every password box in the app has it; the login page was switched
from a raw `<input>` to `TextField` to pick it up. The button is
`aria-pressed`-labelled by action ("Show password" / "Hide password") and kept
out of the tab order so it does not interrupt typing. Covered by
`FormControls.test.jsx` (4 tests).

**`UserType` vs `staff_role` are different lists**, which is easy to conflate
since both look like "roles":

* `UserType` — admin, Secretary, Chairman, Member, Sarpanch, Treasurer →
  **committee members**
* `staff_role` — Security Guard, Office Manager, Housekeeping, Lift Operators,
  Gardeners, Plumbers, Writer → **Staff Master**

Verified that the committee screen reads `fill_type` (UserType) and the staff
screen reads `Role_Show` (staff_role); neither crosses over.

One legacy behaviour deliberately **not** copied: `society_member_search.aspx`
always hashed and wrote whatever was in the password box, so editing a member
with the field blank replaced their password with the hash of an empty string,
locking them out. Here a blank password means "leave it alone", and the hint on
the field says so.

### `owner_search` — document uploads silently discarded — **FIXED**

`/masters/owners` and `/masters/tenants` are the same component, so the export
buttons and View Docs from the `rental_search` fix landed on owners too. Two
things were specific to this page.

**Data loss on every save.** The form offered "ID document type" but **no way to
attach the document**. `owner_master` has `id_proof`, `photo_name`,
`agreement_path` and `police_verification_path`; the API accepted all four and
the upload categories existed — but the form never carried them, so the submit
body sent them as empty and **every save cleared whatever was stored**.

Confirmed against live data: 2 of 10 owners in C10001 already hold a document
path, e.g.

```
Bhushan Gawade → /Documents/Gokuldham/rental/Vinay11/agreement/MaintenanceReport (1).pdf
```

Editing either of those would have erased it. Four `FileUploadField`s added —
ID proof and photo for everyone, rent agreement and police verification for
tenants — plus the paths threaded through `EMPTY`, `toForm` and the submit body.

**Sq.ft column.** `rental_search.aspx` has it, `owner_search.aspx` does not. The
grid now shows it only for tenants.

**Not a gap:** owner_search's "Upload" button. Its handler
(`owner_search.aspx.cs:283`) is entirely commented out — a dead control, like
the village Excel imports.

### Export buttons are missing from 9 more pages

Same root cause as above, found while checking whether `rental_search` was an
isolated case. **16 screens render a raw `<table>` instead of `DataGrid`**, so
none of them has Excel/PDF/Print.

Of those, these legacy pages **did** carry an export button and their migrated
screens currently have none:

| Legacy page | Export buttons it had |
|---|---|
| `maintenance_search` | 3 |
| `Defaulter` | 2 |
| `cashbook`, `pdc_reminder_search`, `receipt_search_form`, `flat_search`, `printledger_details`, `ownerwise_maintenance`, `BalanceSheet` | 1 each |

Not converted yet: several of these have bespoke layouts (grouped rows, footer
totals, editable cells) where swapping in `DataGrid` would change more than the
toolbar, so each needs looking at rather than a blanket replace.

### Tall modals were cut off — **FIXED** (affects every screen)

Reported from a screenshot of the Society edit dialog: the title was clipped at
the top and Save was below the fold.

`Modal` centred its panel (`sm:items-center`) but let it grow to whatever height
its content needed. Once the content was taller than the viewport, the overflow
split evenly above *and* below — so a long form hid its own header and pushed
its footer out of reach. Only the page behind it scrolled, which did not move
the dialog.

The panel is now `max-h-[calc(100vh-2rem)]` and a flex column: header and footer
are `shrink-0`, the body is `flex-1 min-h-0 overflow-y-auto`. (`min-h-0` is the
part that matters — without it a flex child refuses to shrink below its content
and will not scroll.)

That fixes the container, but four modals still had their Cancel/Save buttons
*inside* the body, so they would have scrolled away with the form. Moved to the
`footer` prop, submitting by `form="…"` id: **Society edit**, **Start a poll**,
**Register visitor**, **Village pay charges**.

Every modal in the app now has a fixed footer. Covered by `ui.test.jsx`
(5 tests), which asserts the height cap, the scrolling body, that header and
footer cannot be squeezed away, and that footer actions are outside the
scrolling region.

### `society_search` — edit form fields — **FIXED**

Four fields that `society_search.aspx.cs` saves were absent from the migrated
form. All four have real columns, and three were **already accepted by the API**
— only the inputs were missing, so the values were being written as `0` on every
save:

| Field | Column | Note |
|---|---|---|
| State | `state_id` | API already accepted `stateId` |
| District | `district_id` | API already accepted `districtId` |
| Division | `division_id` | API already accepted `divisionId` |
| Street | `home_no` | Missing from the API too — added |

State → district → division **cascade**, as they did on the legacy page: choosing
a state narrows the districts (692 → 39 for Maharashtra), and choosing a district
narrows the divisions. Changing a state clears the district and division beneath
it rather than leaving a stale pair.

There is no stored procedure for these lists — the legacy page built the queries
by string concatenation (`"... Where state_id=" + ddl_state.SelectedValue`,
`society_search.aspx.cs:391`). The new `GET /masters/regions?stateId=&districtId=`
reads the same three tables with **bound parameters** instead.

"Street" is labelled that way because the legacy page was, but it assigns to
`Home_No` and the column is an `int` — so it only ever held a number. The input
is numeric to match.

Field order also now follows the legacy form: name → registration → address 1/2
→ contact → email → state → district → division → city → street → pincode →
TAN/GSTIN/PAN.

### Header layout must be the same on every screen

While matching Society Master and Committee Member to their legacy pages, both
were given a bespoke header — a large left-aligned `<h1>`, a wide "Search here"
box with a magnifier button, and actions on the **left**. Every other list
screen in the app uses `PageHeader`: title on the left, search and actions on
the **right**.

Copying one legacy page's chrome onto two screens made those two inconsistent
with the other forty. Both reverted to `PageHeader`, keeping the legacy *titles*
("Committee Member List", "Society") but the app's standard arrangement.

Checked afterwards that no screen still carries a custom `text-3xl` heading or a
"Search here" box.

### `society_search` — page shape and Excel import — **BUILT**

Two problems, found from a screenshot of the running legacy app rather than from
the scan — which had marked this page clean.

**Shape.** `society_search.aspx` is a **list**: an `<h1>Society</h1>`, a search
box, an "Import Data" button, and a grid (No · Name · Registration No · Address ·
Contact No · Edit) whose pencil opens the form in a modal. The migration had
turned it into a bare always-open edit form with none of that. Rebuilt to match,
with Close/Save in the modal footer as the legacy had.

**Import.** The Import button opens a modal offering **Building**, **Owner** and
**Society Member**, and its handler is genuinely implemented with ClosedXML
(`society_search.aspx.cs:449`) — unlike the village stubs. The migrated app had
no spreadsheet capability at all.

Added `ExcelImport.jsx`: the workbook is parsed in the browser and each row goes
through the ordinary REST endpoint, so an import cannot bypass the validation a
manual entry faces. Column letters follow the legacy sheet (A name, B email,
C print name, D floors, F registration no); row 1 is a header and rows with an
empty column A are skipped, as the legacy loop did. One failing row is reported
with its spreadsheet row number and the rest continue.

**All three types are implemented**, matching the legacy behaviour:

* *Building* — straight through `POST /masters/buildings`.
* *Society Member* — needed a new `POST /masters/members`. It creates the member
  **and their login**, exactly as the legacy import did: username is the email
  (falling back to the contact number when the sheet has none) and the password
  is the contact number, hashed with `lib/password.js` — the same PBKDF2 format
  the WebForms app writes, so imported members can sign in. `chk_name` is probed
  first, so re-running an import skips existing members rather than duplicating
  them. The modal states on screen that logins are created and that the password
  is the contact number.
* *Owner* — the full legacy sequence: find the building by name, create the wing
  if new, create the flat if new, then create the owner. Handles the Own/Rent
  split with its agreement dates.

**Lookups resolve by name from the database, not by hardcoded numbers.** The
legacy helpers mapped names to fixed ids, and `getRole` was **wrong**:

| Sheet value | Legacy id | What that id actually is |
|---|---|---|
| President | 1 | `admin` — full administrator |
| Vice President | 5 | `Sarpanch` — a *village* role (`type = 2`) |

`UserType` has no President or Vice President row at all, so those sheet values
silently produced an administrator and a village office-bearer. The import now
resolves the designation against `sp_UserLogin/fill_type` and **rejects** an
unknown one with the list of valid designations, rather than guessing.

Marital status needed the same treatment in reverse: the sheet offers Married /
Not Married / Single / Widow but the `married` table holds only `married` and
`unmarried`, so anything that is not "married" collapses to unmarried.

Excel serial dates are converted from the 1899-12-30 epoch; a text date is
parsed as-is.

Covered by `ExcelImport.test.jsx` (6 tests) which builds real `.xlsx` files in
memory: column mapping, header skip, blank-row skip, partial failure, member
designation resolved by name, the "President" rejection, and an owner import
reusing an existing wing and flat instead of duplicating them.

`xlsx` loads only when a file is chosen and has its own chunk — without that it
would have pushed the shared vendor bundle from 73 kB to 488 kB.

### `Vote` — poll creation — **BUILT**

`/community/polls` had **two GET endpoints and no POST**: polls could be read
but not created.

**Added:** `POST /community/polls` and `DELETE /community/polls/:id`, with a
Start Poll form carrying topic, description, expiry, audience, the
allow-multiple-votes and one-vote-per-unit flags, and a repeatable option list.

`sp_polls` dispatches on `@Mode` (not `@operation`) and its `INSERT` branch
writes every one of those columns. Options are stored as **one comma-joined
string**, exactly as `Vote.aspx.cs:92` wrote them — so the API rejects an option
containing a comma, which would otherwise silently split into two options. The
legacy minimum of two options is enforced in both the API and the form.

### `doc_master` — document tags — **withdrawn**

Listed as a gap in the first pass on the strength of the code-behind reading
`txt_tags`. The schema says otherwise: `doc_master` has **no `tag` or `tags`
column**. The legacy page reads the box and drops it. Not a gap.

### Smaller confirmed gaps

| Page | Gap |
|---|---|
| `building_search` | bank address — **fixed** |
| `caretaker` | flat / doc executed, field order — **fixed** |
| `car_polling` | time — **fixed** |
| `servent_search` | five services + charges — **fixed** |
| `owner_search` | family occupation / DOB — **fixed** |
| `contact_master` | address line 2 — **fixed** |
| 26 pages | Download PDF — **fixed** |

---

## Dismissed — no column exists

Every one of these was flagged by the scan, is genuinely read by the legacy
code-behind, and still is **not** a gap: the database has nowhere to put it.
The legacy page collects the value and discards it.

| Page | Fields with no column |
|---|---|
| `new_society`, `society_search` | district, division, street, per-sqft rate, 2W/4W rate, bill generation day |
| `maintenance_search` | per-sqft rate, 2W/4W rate, gen day (same set) |
| `contact_master` | org telephone, org address 1 / 2 |
| `servent_search` | org address 1 / 2 |
| `pdc_reminder_search` | cheque amount, deposit / return / bounce flags |
| `user_login` | short name, telephone, designation, manager, join / leave dates |
| `doc_master` | tags |
| `house_tax_receipt` | paid amount box, pay status |
| `ledger_form` | ledger type |
| `Messages_master` | message body |

## Verified present already

| Page | Field | Where |
|---|---|---|
| `contact_master` | address 2 | fixed this session |
| `servent_search` | cloth / utensil wash + charges | fixed this session |
| `InventoryMaster` | item name, warranty | already sent |
| `square_feet_rate` | rate, applied date | already sent |
| `facility_booking` | from / to time | shown in the Slot column |
| `house_tax_receipt` | `Amount_paid` | shown on the receipts grid and viewer |
| `v_resident` | sqft / tap / waste charges | on `/village/houses` |
| `society_expense` | regular vs add-on, final amount | on the expenses screen |

## Remaining actions, not fields

These are buttons rather than data, so the column test does not apply. Each
still needs its handler read before anything is built.

| Page | Action |
|---|---|
| `Audit`, `BalanceSheet` | Add New, Save Sequence, Add Subpoint |
| `support_ticket` | View Image, reply Send |
| `Defaulter` | select-all + message content (bulk SMS) |
| `recent_activity`, `Admin_Dashboard` | date-range filter |
| `receipt_search_form` | Verify & Proceed |

Column-only candidates (grid headers with no textual match) are label
differences — "Owner Name" vs "Owner" — and are the lowest-value group to chase.
