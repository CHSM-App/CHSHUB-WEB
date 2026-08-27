import { useEffect, useMemo, useState } from 'react';
import { buildings as buildingsApi, flats, wings as wingsApi } from '@/api/masters';
import useCrudResource from './useCrudResource';
import { ConfirmDialog, EmptyState, ErrorNotice, Field, Modal, Spinner, FormErrorSummary } from '@/components/ui.jsx';
import {
  countErrors,
  validateFields,
  focusFirstInvalid,
} from '@/components/formValidation.js';
import useSortedRows from '@/components/useSortedRows.js';
import { SortableHead, SortControl } from '@/components/SortableHead.jsx';
import Pager, { usePaging } from '@/components/Pager.jsx';

/*
 * Flat numbers are text but read as numbers — the comparison is numeric-aware,
 * so A-9 lands before A-101 rather than after it. The two measures sort as
 * numbers so a blank sq. ft. doesn't order between two figures.
 */
const COLUMNS = [
  { key: 'flat_no', label: 'Flat no.' },
  { key: 'build_wing', label: 'Building / wing' },
  { key: 'flat_type', label: 'Type' },
  { key: 'bed', label: 'Bedrooms', sortValue: (r) => (r.bed == null || r.bed === '' ? null : Number(r.bed)) },
  { key: 'sq_ft', label: 'Sq. ft.', sortValue: (r) => (r.sq_ft == null || r.sq_ft === '' ? null : Number(r.sq_ft)) },
];

/*
 * buildingId is not sent to the API — a flat is stored against its wing, and the
 * wing already implies the building. It lives in the form only to drive the wing
 * cascade.
 */
const EMPTY = {
  buildingId: '',
  wingId: '',
  flatNo: '',
  flatTypeId: '',
  bedroomId: '',
  usageId: '',
  sqFt: '',
  terraceSqFt: '',
  intercomNo: '',
};

const toForm = (row) => ({
  wingId: row.wing_id ?? '',
  flatNo: row.flat_no ?? '',
  flatTypeId: row.flat_type_id ?? '',
  bedroomId: row.bed_id ?? '',
  usageId: row.usage_id ?? '',
  sqFt: row.sq_ft ?? '',
  terraceSqFt: row.terrace_sq_ft ?? '',
  intercomNo: row.intercom_no ?? '',
});

/* What Submit insists on, in the shape validateFields expects. */
const FLAT_FIELDS = [
  { name: 'buildingId', label: 'Building', type: 'select', required: true },
  { name: 'wingId', label: 'Wing', type: 'select', required: true },
  { name: 'flatNo', label: 'Flat number', required: true },
  { name: 'bedroomId', label: 'Bedrooms', type: 'select', required: true },
  { name: 'usageId', label: 'Usage', type: 'select', required: true },
];

export default function FlatsPage() {
  const [buildingFilter, setBuildingFilter] = useState('');
  const [wingFilter, setWingFilter] = useState('');
  /*
   * Both filters go to the API rather than being applied here: the flats route
   * accepts buildingId and wingId, so picking a building alone still narrows
   * the list to every flat under it, across all its wings.
   */
  const params = useMemo(
    () => ({ buildingId: buildingFilter || undefined, wingId: wingFilter || undefined }),
    [buildingFilter, wingFilter],
  );

  const { items, loading, error, saving, create, update, remove, refresh, setError } =
    useCrudResource(flats, { params });

  const { sorted, sort, toggleSort } = useSortedRows(items, COLUMNS);

  const paging = usePaging(sorted.length, 25);
  const visible = sorted.slice(paging.first, paging.first + paging.size);

  const [lookups, setLookups] = useState({ wings: [], flatTypes: [], usages: [], bedrooms: [] });
  const [buildingOptions, setBuildingOptions] = useState([]);
  /*
   * The wing list from flats.lookups() is `sp_flat_master @operation='Fill_list'`,
   * which selects only wing_id and a joined name — it carries no build_id, so it
   * cannot say which building a wing belongs to. The wing master endpoint does
   * return build_id, so the cascade reads its wings instead.
   */
  const [wingOptions, setWingOptions] = useState([]);
  const [editing, setEditing] = useState(null);
  const [confirming, setConfirming] = useState(null);
  // name -> message, for the fields the last submit found empty.
  const [fieldErrors, setFieldErrors] = useState({});

  useEffect(() => {
    let cancelled = false;
    flats
      .lookups()
      .then((data) => {
        if (!cancelled) setLookups(data);
      })
      .catch(() => {});
    return () => {
      cancelled = true;
    };
  }, []);

  // Buildings and wings feed both the filter row and the form's cascade.
  useEffect(() => {
    let cancelled = false;
    Promise.all([
      buildingsApi.list().catch(() => null),
      wingsApi.list().catch(() => null),
    ]).then(([buildingData, wingData]) => {
      if (cancelled) return;
      setBuildingOptions(buildingData?.items ?? []);
      setWingOptions(wingData?.items ?? []);
    });
    return () => {
      cancelled = true;
    };
  }, []);

  /** Wings under one building, or all of them when no building is chosen. */
  const wingsForBuilding = (buildingId) =>
    buildingId ? wingOptions.filter((w) => String(w.build_id) === String(buildingId)) : wingOptions;

  const filterWings = useMemo(
    () => wingsForBuilding(buildingFilter),
    // wingsForBuilding is a pure read of wingOptions.
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [buildingFilter, wingOptions],
  );

  /*
   * Changing the building clears a wing that no longer belongs to it, so the
   * two filters can never disagree and strand the list on zero rows.
   */
  const onBuildingFilter = (e) => {
    const { value } = e.target;
    setBuildingFilter(value);
    setWingFilter((prev) =>
      prev && !wingsForBuilding(value).some((w) => String(w.wing_id) === String(prev)) ? '' : prev,
    );
  };

  /** The building a wing sits under, for opening the form on an existing flat. */
  const buildingOfWing = (wingId) =>
    wingOptions.find((w) => String(w.wing_id) === String(wingId))?.build_id ?? '';

  const openCreate = () =>
    setEditing({
      id: null,
      form: { ...EMPTY, buildingId: buildingFilter || '', wingId: wingFilter || '' },
    });

  const openEdit = (row) =>
    setEditing({
      id: row.flat_id,
      form: { ...toForm(row), buildingId: row.build_id ?? buildingOfWing(row.wing_id) },
    });

  const closeForm = () => {
    setEditing(null);
    setError(null);
  };

  // Read e.target.value eagerly — see ResidentsPage for the full explanation.
  const setField = (key) => (e) => {
    const { value } = e.target;
    setFieldErrors((prev) => (prev[key] ? { ...prev, [key]: undefined } : prev));
    setEditing((prev) => ({ ...prev, form: { ...prev.form, [key]: value } }));
  };

  /*
   * Picking a building drops a wing belonging to a different one, so the saved
   * wingId can never contradict the building shown above it.
   */
  const setBuildingField = (e) => {
    const { value } = e.target;
    setFieldErrors((prev) => (prev.buildingId ? { ...prev, buildingId: undefined } : prev));
    setEditing((prev) => {
      const keepWing =
        prev.form.wingId &&
        wingsForBuilding(value).some((w) => String(w.wing_id) === String(prev.form.wingId));
      return { ...prev, form: { ...prev.form, buildingId: value, wingId: keepWing ? prev.form.wingId : '' } };
    });
  };

  const onSubmit = async (event) => {
    event.preventDefault();

    // The form carries noValidate, so nothing enforced the asterisks — an
    // empty save wrote a blank row. Same pass as every other screen.
    const missing = validateFields(FLAT_FIELDS, editing.form);
    setFieldErrors(missing);
    if (Object.keys(missing).length) {
      focusFirstInvalid(FLAT_FIELDS, missing);
      return;
    }
    const f = editing.form;
    const body = {
      wingId: Number(f.wingId),
      flatNo: f.flatNo,
      flatTypeId: Number(f.flatTypeId),
      bedroomId: Number(f.bedroomId),
      usageId: Number(f.usageId),
      sqFt: f.sqFt,
      terraceSqFt: f.terraceSqFt,
      intercomNo: f.intercomNo,
    };
    try {
      if (editing.id) await update(editing.id, body);
      else await create(body);
      setEditing(null);
    } catch {
      // Rendered in the modal.
    }
  };

  const onDelete = async () => {
    try {
      await remove(confirming.flat_id);
    } finally {
      setConfirming(null);
    }
  };

  return (
    <section>
      <header className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-lg font-semibold text-slate-800">Flats</h1>
          <p className="text-sm text-slate-500">{items.length} record(s)</p>
        </div>
        <div className="flex flex-wrap gap-2">
          <select
            className="field-input w-44"
            value={buildingFilter}
            onChange={onBuildingFilter}
            aria-label="Filter by building"
          >
            <option value="">All buildings</option>
            {buildingOptions.map((b) => (
              <option key={b.build_id} value={b.build_id}>
                {b.name}
              </option>
            ))}
          </select>
          <select
            className="field-input w-44"
            value={wingFilter}
            onChange={(e) => setWingFilter(e.target.value)}
            aria-label="Filter by wing"
          >
            {/* Named for the building in play, so an empty pick is not read as
                "no filter" when a building is already narrowing the list. */}
            <option value="">{buildingFilter ? 'All wings in building' : 'All wings'}</option>
            {filterWings.map((w) => (
              <option key={w.wing_id} value={w.wing_id}>
                {/* Every building names its wings A, B, C — so with no building
                    chosen the list is several identical-looking entries. The
                    building disambiguates them; once one is picked it is
                    already stated above, and the wing alone reads cleaner. */}
                {buildingFilter ? w.w_name : `${w.name} ${w.w_name}`}
              </option>
            ))}
          </select>
          <button type="button" className="btn-primary" onClick={openCreate}>
            Add flat
          </button>
        </div>
      </header>

      {!editing && <ErrorNotice error={error} onRetry={refresh} />}

      <div className="card mt-3 overflow-hidden">
        {loading ? (
          <Spinner />
        ) : items.length === 0 ? (
          <EmptyState title="No flats found" hint="Flats belong to a wing — add one to get started." />
        ) : (
          <>
          <SortControl columns={COLUMNS} sort={sort} onSort={toggleSort} className="px-4 pb-2 pt-3" />
          <div className="overflow-x-auto">
            <table className="min-w-full stacked-table">
              <thead>
                <tr>
                  {/* Row number, as every other list carries. */}
                  <th className="table-head w-px whitespace-nowrap">No.</th>
                  {COLUMNS.map((c) => (
                    <SortableHead key={c.key} column={c} sort={sort} onSort={toggleSort} />
                  ))}
                  <th className="table-head sr-only">Actions</th>
                </tr>
              </thead>
              <tbody>
                {visible.map((row, i) => (
                  <tr key={row.flat_id} className="hover:bg-slate-50">
                    {/* Counts from the row's place in the whole list, so page 2
                        carries on rather than restarting at 1. */}
                    <td className="table-cell w-px whitespace-nowrap text-slate-500" data-label="No.">
                      {paging.first + i + 1}
                    </td>
                    <td className="table-cell font-medium text-slate-800" data-label="Flat no.">{row.flat_no}</td>
                    <td className="table-cell" data-label="Building / wing">{row.build_wing}</td>
                    <td className="table-cell" data-label="Type">{row.flat_type}</td>
                    <td className="table-cell" data-label="Bedrooms">{row.bed}</td>
                    <td className="table-cell" data-label="Sq. ft.">{row.sq_ft || '—'}</td>
                    <td className="table-cell whitespace-nowrap text-right" data-actions="">
                      <button type="button" className="btn-secondary mr-2" onClick={() => openEdit(row)}>
                        Edit
                      </button>
                      <button type="button" className="btn-danger" onClick={() => setConfirming(row)}>
                        Delete
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <Pager
            page={paging.page}
            pageCount={paging.pageCount}
            first={paging.first}
            last={paging.last}
            total={sorted.length}
            onPage={paging.setPage}
          />
          </>
        )}
      </div>

      <Modal
        open={Boolean(editing)}
        title={editing?.id ? 'Edit flat' : 'Add flat'}
        onClose={closeForm}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={closeForm} disabled={saving}>
              Cancel
            </button>
            <button type="submit" form="flat-form" className="btn-primary" disabled={saving}>
              {saving ? 'Saving…' : 'Save'}
            </button>
          </>
        }
      >
        {editing ? (
          <form id="flat-form" onSubmit={onSubmit} className="grid gap-4 sm:grid-cols-2" noValidate>
            <FormErrorSummary count={countErrors(fieldErrors)} />
            <Field label="Building" required name="buildingId" error={fieldErrors.buildingId}>
              <select
                className="field-input"
                value={editing.form.buildingId}
                onChange={setBuildingField}
                required
              >
                <option value="">Select a building…</option>
                {buildingOptions.map((b) => (
                  <option key={b.build_id} value={b.build_id}>
                    {b.name}
                  </option>
                ))}
              </select>
            </Field>

            <Field
              label="Wing"
              required
              name="wingId"
              error={fieldErrors.wingId}
              hint={editing.form.buildingId ? undefined : 'Choose a building first'}
            >
              <select
                className="field-input"
                value={editing.form.wingId}
                onChange={setField('wingId')}
                disabled={!editing.form.buildingId}
                required
              >
                <option value="">
                  {editing.form.buildingId ? 'Select a wing…' : 'Select a building first…'}
                </option>
                {wingsForBuilding(editing.form.buildingId).map((w) => (
                  <option key={w.wing_id} value={w.wing_id}>
                    {w.w_name}
                  </option>
                ))}
              </select>
            </Field>
            <Field label="Flat number" required name="flatNo" error={fieldErrors.flatNo}>
              <input className="field-input" value={editing.form.flatNo} onChange={setField('flatNo')} required />
            </Field>

            <Field
              label="Flat type"
              required
              // The update path in sp_flat_master never writes flat_type_id, so
              // the API rejects a change. Disable rather than let it fail on save.
              hint={editing.id ? 'Flat type cannot be changed after creation' : undefined}
            >
              <select
                className="field-input"
                value={editing.form.flatTypeId}
                onChange={setField('flatTypeId')}
                disabled={Boolean(editing.id)}
                required
              >
                <option value="">Select…</option>
                {lookups.flatTypes.map((t) => (
                  <option key={t.flat_type_id} value={t.flat_type_id}>
                    {t.flat_type}
                  </option>
                ))}
              </select>
            </Field>

            <Field label="Bedrooms" required name="bedroomId" error={fieldErrors.bedroomId}>
              <select
                className="field-input"
                value={editing.form.bedroomId}
                onChange={setField('bedroomId')}
                required
              >
                <option value="">Select…</option>
                {lookups.bedrooms.map((b) => (
                  <option key={b.bed_id} value={b.bed_id}>
                    {b.bed}
                  </option>
                ))}
              </select>
            </Field>

            <Field label="Usage" required name="usageId" error={fieldErrors.usageId}>
              <select className="field-input" value={editing.form.usageId} onChange={setField('usageId')} required>
                <option value="">Select…</option>
                {lookups.usages.map((u) => (
                  <option key={u.usage_id} value={u.usage_id}>
                    {u.usage}
                  </option>
                ))}
              </select>
            </Field>

            <Field label="Carpet area (sq. ft.)">
              <input className="field-input" value={editing.form.sqFt} onChange={setField('sqFt')} />
            </Field>
            <Field label="Terrace area (sq. ft.)">
              <input className="field-input" value={editing.form.terraceSqFt} onChange={setField('terraceSqFt')} />
            </Field>
            <Field label="Intercom number">
              <input className="field-input" value={editing.form.intercomNo} onChange={setField('intercomNo')} />
            </Field>

            <div className="sm:col-span-2">
              <ErrorNotice error={error} />
            </div>
          </form>
        ) : null}
      </Modal>

      <ConfirmDialog
        open={Boolean(confirming)}
        title="Delete flat"
        message={`Delete flat "${confirming?.flat_no}"? Any assigned owner must be removed first.`}
        onConfirm={onDelete}
        onCancel={() => setConfirming(null)}
        busy={saving}
      />
    </section>
  );
}
