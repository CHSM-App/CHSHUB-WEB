import { useEffect, useState } from 'react';
import { buildings, flats, residents, wings } from '@/api/masters';
import { parkingPlaces } from '@/api/modules';
import { api } from '@/api/client';
import { ErrorNotice } from '@/components/ui.jsx';
import { SelectField } from '@/components/FormControls.jsx';
import { useToast } from '@/components/Toast.jsx';

/**
 * Bulk import from a spreadsheet — society_search.aspx's "Import Data" modal.
 *
 * The legacy page parsed the workbook server-side with ClosedXML and wrote rows
 * through the same business layer the screens use. Here the workbook is parsed
 * in the browser and each row goes through the ordinary REST endpoint, so an
 * import cannot bypass the validation a manual entry would face.
 *
 * Column letters follow the legacy sheets exactly, so spreadsheets the society
 * already uses keep working.
 */

const BUILDING_COLUMNS = [
  ['A', 'Name', 'name'],
  ['B', 'Email', 'email'],
  ['C', 'Print name', 'printName'],
  ['D', 'Floors', 'floors'],
  ['F', 'Registration number', 'registrationNo'],
];

const MEMBER_COLUMNS = [
  ['A', 'Name', 'name'],
  ['B', 'Designation', 'designation'],
  ['C', 'Contact number', 'contactNo'],
  ['D', 'Email', 'email'],
];

const OWNER_COLUMNS = [
  ['A', 'Building', 'building'],
  ['B', 'Wing', 'wing'],
  ['C', 'Flat number', 'flatNo'],
  ['D', 'Usage', 'usage'],
  ['E', 'Bedrooms', 'bedroom'],
  ['F', 'Sq ft', 'sqFt'],
  ['G', 'Terrace sq ft', 'terraceSqFt'],
  ['H', 'Intercom', 'intercomNo'],
  ['I', 'Flat type', 'flatType'],
  ['J', 'Possession date', 'possessionDate'],
  ['K', 'Owner name', 'name'],
  ['L', 'Mobile', 'mobile'],
  ['M', 'Alternate mobile', 'altMobile'],
  ['N', 'Email', 'email'],
  ['O', 'Marital status', 'married'],
  ['P', 'Date of birth', 'dob'],
  ['Q', 'Occupation', 'occupation'],
  ['R', 'Monthly income', 'monthlyIncome'],
  ['S', 'Office address', 'officeAddress'],
  ['U', 'Office telephone', 'officeTel'],
  ['X', 'Agreement date', 'agreementDate'],
  ['Y', 'Agreement from', 'agreementFrom'],
  ['Z', 'Agreement to', 'agreementTo'],
  ['AB', 'Type (Own/Rent)', 'type'],
];

/**
 * park_place_search.aspx reads its sheet by HEADER NAME rather than by column
 * letter (`row["Parking Number"]`), so this one is matched on the header row.
 */
const PARKING_COLUMNS = [
  ['Parking Number', 'parkingNo'],
  ['Park For', 'parkFor'],
];

const IMPORT_TYPES = [
  { value: 'building', label: 'Building', columns: BUILDING_COLUMNS },
  { value: 'society_member', label: 'Society Member', columns: MEMBER_COLUMNS },
  { value: 'owner', label: 'Owner', columns: OWNER_COLUMNS },
  { value: 'parking', label: 'Parking Place', headerColumns: PARKING_COLUMNS },
];

/** Only the first few columns are worth previewing for the wide owner sheet. */
const PREVIEW_LIMIT = 6;

/**
 * Blob.arrayBuffer() is missing on older Safari and in jsdom, so fall back to
 * FileReader rather than failing the whole import.
 */
function readAsArrayBuffer(file) {
  if (typeof file.arrayBuffer === 'function') return file.arrayBuffer();
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result);
    reader.onerror = () => reject(reader.error ?? new Error('Could not read the file'));
    reader.readAsArrayBuffer(file);
  });
}

/** "AB" -> 27. Column letters, not indexes, are what the legacy sheets use. */
function columnIndex(letters) {
  return [...letters].reduce((n, c) => n * 26 + (c.charCodeAt(0) - 64), 0) - 1;
}

/** Excel serial dates arrive as numbers; text dates as-is. */
function toIsoDate(value) {
  const s = String(value ?? '').trim();
  if (!s) return '';
  if (/^\d+(\.\d+)?$/.test(s)) {
    // Excel's epoch is 1899-12-30 (accounting for its 1900 leap-year bug).
    const d = new Date(Date.UTC(1899, 11, 30) + Number(s) * 86400000);
    return Number.isNaN(d.getTime()) ? '' : d.toISOString().slice(0, 10);
  }
  const d = new Date(s);
  return Number.isNaN(d.getTime()) ? '' : d.toISOString().slice(0, 10);
}

/**
 * Marital status is the one lookup where the sheet and the table disagree: the
 * legacy sheet used Married / Not Married / Single / Widow, but `married` only
 * holds `married` and `unmarried`. Anything that is not "married" is treated as
 * unmarried, which is how those four legacy values collapse.
 */
function maritalId(list, value) {
  const v = String(value ?? '').trim().toLowerCase();
  if (!v) return 0;
  const wanted = v === 'married' ? 'married' : 'unmarried';
  const hit = list.find((x) => String(x.married_name ?? '').trim().toLowerCase() === wanted);
  return hit ? Number(hit.married_id) : 0;
}

/** Case-insensitive name -> id from a lookup list. */
function idByName(list, nameKey, idKey, wanted) {
  const w = String(wanted ?? '').trim().toLowerCase();
  if (!w) return 0;
  const hit = list.find((x) => String(x[nameKey] ?? '').trim().toLowerCase() === w);
  return hit ? Number(hit[idKey]) : 0;
}

export default function ExcelImport({ onDone, defaultType = 'building' }) {
  const [type, setType] = useState(defaultType);
  const [rows, setRows] = useState(null);
  const [busy, setBusy] = useState(false);
  const [progress, setProgress] = useState(null);
  const [error, setError] = useState(null);
  const [result, setResult] = useState(null);
  const toast = useToast();
  const [lookups, setLookups] = useState(null);

  const selected = IMPORT_TYPES.find((t) => t.value === type);

  // Designations and flat lookups are resolved by NAME from the database rather
  // than hardcoded. The legacy helpers (getRole/getUsage/getBed/getType) mapped
  // names to fixed numbers, and getRole was wrong: it mapped "President" to 1,
  // which is `admin` in UserType, and "Vice President" to 5, which is the
  // village role `Sarpanch`.
  useEffect(() => {
    let cancelled = false;
    Promise.all([
      api.get('/masters/member-types').catch(() => ({ items: [] })),
      flats.lookups().catch(() => ({})),
      residents.lookups().catch(() => ({})),
    ])
      .then(([memberTypes, flatLookups, ownerLookups]) => {
        if (cancelled) return;
        setLookups({
          memberTypes: memberTypes.items ?? [],
          wings: flatLookups.wings ?? [],
          flatTypes: flatLookups.flatTypes ?? [],
          usages: flatLookups.usages ?? [],
          bedrooms: flatLookups.bedrooms ?? [],
          marital: ownerLookups.marital ?? [],
        });
      })
      .catch(() => !cancelled && setLookups({}));
    return () => {
      cancelled = true;
    };
  }, []);

  const readFile = async (file) => {
    setError(null);
    setResult(null);
    setRows(null);
    if (!file) return;
    try {
      // xlsx is large and only needed once a file is chosen.
      const XLSX = await import('xlsx');
      const data = await readAsArrayBuffer(file);
      const wb = XLSX.read(data, { type: 'array' });
      const sheet = wb.Sheets[wb.SheetNames[0]];
      // header:1 gives raw rows so the legacy column letters still line up.
      const grid = XLSX.utils.sheet_to_json(sheet, { header: 1, blankrows: false });

      // Row 1 is the header; the legacy loop started at row 2.
      const header = (grid[0] ?? []).map((h) => String(h ?? '').trim().toLowerCase());
      const firstKey = selected.headerColumns
        ? selected.headerColumns[0][1]
        : selected.columns[0][2];

      const parsed = grid
        .slice(1)
        .map((r, i) => {
          const row = { __row: i + 2 };
          if (selected.headerColumns) {
            // Matched by header text, as park_place_search.aspx does.
            for (const [name, key] of selected.headerColumns) {
              const at = header.indexOf(name.toLowerCase());
              row[key] = at === -1 ? '' : String(r[at] ?? '').trim();
            }
          } else {
            for (const [letter, , key] of selected.columns) {
              row[key] = String(r[columnIndex(letter)] ?? '').trim();
            }
          }
          return row;
        })
        // The legacy import skipped any row whose first column was empty.
        .filter((r) => r[firstKey]);

      if (selected.headerColumns && !parsed.length && grid.length > 1) {
        const wanted = selected.headerColumns.map(([n]) => `"${n}"`).join(', ');
        throw new Error(`no rows matched. The header row must contain ${wanted}`);
      }

      setRows(parsed);
    } catch (err) {
      setError(new Error(`Could not read the spreadsheet: ${err.message}`));
    }
  };

  /** One building row. */
  const importBuilding = (r) =>
    buildings.create({
      name: r.name,
      email: r.email,
      printName: r.printName,
      floors: Number(r.floors) || 0,
      registrationNo: r.registrationNo,
    });

  /**
   * One parking place. "Park For" is the ddl_park_for value: 0 Bike, 1 Car.
   * A sheet may carry either the code or the word, so both are accepted.
   */
  const importParking = (r) => {
    const raw = String(r.parkFor ?? '').trim().toLowerCase();
    let parkFor;
    if (raw === '0' || raw === 'bike') parkFor = 0;
    else if (raw === '1' || raw === 'car') parkFor = 1;
    else throw new Error(`"Park For" must be 0/Bike or 1/Car, got "${r.parkFor}"`);

    return parkingPlaces.create({ parkingNo: r.parkingNo, parkFor });
  };

  /** One committee member — the API also creates their login, as legacy did. */
  const importMember = (r) => {
    const userTypeId = idByName(lookups.memberTypes, 'UserTypeName', 'UserTypeId', r.designation);
    if (!userTypeId) {
      throw new Error(
        `Unknown designation "${r.designation}". Expected one of: ` +
          lookups.memberTypes.map((t) => t.UserTypeName).join(', '),
      );
    }
    return api.post('/masters/members', {
      name: r.name,
      contactNo: r.contactNo,
      email: r.email,
      userTypeId,
    });
  };

  /**
   * One owner row. Mirrors the legacy sequence: find the building by name, add
   * the wing if it is new, add the flat if it is new, then add the owner.
   */
  const importOwner = async (r, cache) => {
    if (!cache.buildings) {
      cache.buildings = (await buildings.list()).items ?? [];
    }
    const buildId = idByName(cache.buildings, 'name', 'build_id', r.building);
    if (!buildId) throw new Error(`No building named "${r.building}"`);

    // Wing names in the lookup are "<building><wing>", which is how
    // sp_flat_master/Fill_list returns them.
    const wingLabel = `${r.building}${r.wing}`;
    let wingId = idByName(cache.wings ?? lookups.wings, 'name', 'wing_id', wingLabel);
    if (!wingId) {
      await wings.create({ buildId, name: r.wing });
      cache.wings = (await flats.lookups()).wings ?? [];
      wingId = idByName(cache.wings, 'name', 'wing_id', wingLabel);
      if (!wingId) throw new Error(`Could not create wing "${r.wing}"`);
    }

    const flatTypeId = idByName(lookups.flatTypes, 'flat_type', 'flat_type_id', r.flatType) || 1;

    // Only create the flat when this wing does not already have that number.
    const existing = (await flats.list({ wingId })).items ?? [];
    let flat = existing.find(
      (f) => String(f.flat_no ?? '').trim().toLowerCase() === r.flatNo.toLowerCase(),
    );
    if (!flat) {
      await flats.create({
        wingId,
        flatNo: r.flatNo,
        flatTypeId,
        usageId: idByName(lookups.usages, 'usage', 'usage_id', r.usage) || 1,
        bedroomId: idByName(lookups.bedrooms, 'bed', 'bed_id', r.bedroom) || 1,
        sqFt: r.sqFt,
        terraceSqFt: r.terraceSqFt,
        intercomNo: r.intercomNo,
      });
      const fresh = (await flats.list({ wingId })).items ?? [];
      flat = fresh.find(
        (f) => String(f.flat_no ?? '').trim().toLowerCase() === r.flatNo.toLowerCase(),
      );
      if (!flat) throw new Error(`Could not create flat "${r.flatNo}"`);
    }

    const isRent = String(r.type ?? '').trim().toLowerCase() === 'rent';
    return residents.create({
      wingId,
      flatId: Number(flat.flat_id),
      flatTypeId,
      name: r.name,
      mobile: r.mobile,
      altMobile: r.altMobile,
      email: r.email,
      // The sheet says "Married"/"Not Married"/"Single"/"Widow"; the table holds
      // only married/unmarried, so anything that is not "married" maps to
      // unmarried rather than being dropped.
      marriedId: maritalId(lookups.marital, r.married),
      dob: toIsoDate(r.dob),
      occupation: r.occupation,
      monthlyIncome: r.monthlyIncome,
      officeAddress: r.officeAddress,
      officeTel: r.officeTel,
      possessionDate: toIsoDate(r.possessionDate),
      type: isRent ? 'Rent' : 'Own',
      ...(isRent
        ? {
            agreementDate: toIsoDate(r.agreementDate),
            agreementFrom: toIsoDate(r.agreementFrom),
            agreementTo: toIsoDate(r.agreementTo),
          }
        : {}),
    });
  };

  const runImport = async () => {
    setBusy(true);
    setError(null);
    const imported = [];
    const failed = [];
    const cache = {};

    for (const [i, r] of rows.entries()) {
      setProgress({ done: i, total: rows.length });
      try {
        if (type === 'building') await importBuilding(r);
        else if (type === 'society_member') await importMember(r);
        else if (type === 'parking') await importParking(r);
        else await importOwner(r, cache);
        imported.push(r);
      } catch (err) {
        // Keep going: one bad row should not abandon the rest, and the legacy
        // import skipped duplicates rather than stopping.
        failed.push({
          row: r.__row,
          name: r.name || r.building || '',
          message: err?.message ?? String(err),
        });
      }
    }

    setProgress(null);
    setResult({ imported: imported.length, failed });
    setBusy(false);

    /*
     * One summary, not one per row — a hundred-row sheet would otherwise bury
     * the screen. Partial success is the normal outcome here (the import skips
     * duplicates rather than stopping), so a run with failures is reported as
     * a warning-ish info rather than a flat error.
     */
    if (failed.length && !imported.length) {
      toast.error(`Nothing was imported — all ${failed.length} row(s) failed. See the list below.`);
    } else if (failed.length) {
      toast.info(
        `${imported.length} row(s) imported, ${failed.length} skipped. See the list below.`,
        { title: 'Import finished' },
      );
    } else {
      toast.success(`${imported.length} row(s) imported successfully.`, { title: 'Import complete' });
    }
  };

  // Normalise both column shapes to [label, key] so the preview and the hint
  // do not have to care whether the sheet is matched by letter or by header.
  const allColumns = selected.headerColumns
    ? selected.headerColumns.map(([name, key]) => [name, key])
    : selected.columns.map(([letter, label, key]) => [`${letter} ${label}`, key]);
  const previewColumns = allColumns.slice(0, PREVIEW_LIMIT);

  return (
    <div className="space-y-4">
      <SelectField
        label="Import type"
        name="importType"
        placeholder=""
        options={IMPORT_TYPES.map((t) => ({ value: t.value, label: t.label }))}
        value={type}
        onChange={(e) => {
          setType(e.target.value);
          setRows(null);
          setResult(null);
        }}
      />

      <div>
        <label className="field-label" htmlFor="import-file">
          Spreadsheet (.xlsx / .xls / .csv)
        </label>
        <input
          id="import-file"
          type="file"
          accept=".xlsx,.xls,.csv"
          className="field-input"
          onChange={(e) => readFile(e.target.files?.[0])}
        />
        <p className="mt-1 text-xs" style={{ color: '#6b7280' }}>
          {selected.headerColumns
            ? 'Matched by header name. Required headers: '
            : 'Row 1 is treated as a header. Columns: '}
          {allColumns.map(([label]) => label).join(' · ')}
        </p>
      </div>

      {type === 'society_member' ? (
        <p className="rounded border p-3 text-xs" style={{ borderColor: '#e3e6f0', color: '#6b7280' }}>
          Each imported member also gets a login, as in the previous system: the
          username is their email (or contact number when no email is given) and
          the password is their contact number. Ask them to change it after the
          first sign-in.
        </p>
      ) : null}

      {rows ? (
        <div>
          <p className="mb-2 text-sm" style={{ color: '#012970' }}>
            <strong>{rows.length}</strong> row(s) ready to import.
          </p>
          <div className="max-h-56 overflow-auto rounded border" style={{ borderColor: '#e3e6f0' }}>
            <table className="min-w-full">
              <thead>
                <tr>
                  <th className="table-head">Row</th>
                  {previewColumns.map(([label, key]) => (
                    <th key={key} className="table-head">
                      {label}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {rows.slice(0, 50).map((r) => (
                  <tr key={r.__row}>
                    <td className="table-cell">{r.__row}</td>
                    {previewColumns.map(([, key]) => (
                      <td key={key} className="table-cell">
                        {r[key] || '—'}
                      </td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          {rows.length > 50 ? (
            <p className="mt-1 text-xs" style={{ color: '#6b7280' }}>
              Showing the first 50; all {rows.length} will be imported.
            </p>
          ) : null}
        </div>
      ) : null}

      {progress ? (
        <p className="text-sm" style={{ color: '#012970' }}>
          Importing {progress.done + 1} of {progress.total}…
        </p>
      ) : null}

      {result ? (
        <div className="rounded border p-3 text-sm" style={{ borderColor: '#e3e6f0' }}>
          <p style={{ color: '#1cc88a' }}>
            Imported {result.imported} {selected.label.toLowerCase()} record(s).
          </p>
          {result.failed.length ? (
            <>
              <p className="mt-2" style={{ color: '#e74a3b' }}>
                {result.failed.length} row(s) were skipped:
              </p>
              <ul className="mt-1 space-y-0.5">
                {result.failed.map((f) => (
                  <li key={f.row} className="text-xs" style={{ color: '#6b7280' }}>
                    Row {f.row} ({f.name}): {f.message}
                  </li>
                ))}
              </ul>
            </>
          ) : null}
        </div>
      ) : null}

      <ErrorNotice error={error} />

      <div className="flex justify-end gap-2">
        <button type="button" className="btn-secondary" onClick={onDone}>
          Close
        </button>
        <button
          type="button"
          className="btn-primary"
          disabled={busy || !rows?.length || !lookups}
          onClick={runImport}
        >
          {busy ? 'Importing…' : `Import ${rows?.length ?? 0} row(s)`}
        </button>
      </div>
    </div>
  );
}
