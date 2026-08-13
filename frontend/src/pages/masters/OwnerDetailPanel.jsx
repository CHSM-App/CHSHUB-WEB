import { useCallback, useEffect, useState } from 'react';
import { ownerExtras } from '@/api/ownerExtras';
import { family as familyApi } from '@/api/masters';
import { ConfirmDialog, EmptyState, ErrorNotice, Modal, Spinner } from '@/components/ui.jsx';
import { CheckboxField, FileUploadField, SelectField, Tabs, TextField } from '@/components/FormControls.jsx';
import { useToast } from '@/components/Toast.jsx';
import { validateFields, focusFirstInvalid } from '@/components/formValidation.js';

const money = (v) =>
  v == null ? '—' : Number(v).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });

/*
 * What the panel's two add-forms insist on, in the shape validateFields
 * expects. Both carry asterisks that nothing enforced, so an empty Add filed a
 * blank family member or a vehicle with no number.
 */
const FAMILY_FIELDS = [
  { name: 'name', label: 'Name', required: true },
  { name: 'relation', label: 'Relation', required: true },
  // Optional, but format-checked once filled — the add-row renders a contact
  // box that no rule covered.
  { name: 'contact', label: 'Contact', phone: true, digits: true, maxLength: 10 },
];
const VEHICLE_FIELDS = [{ name: 'vehicleNo', label: 'Vehicle number', required: true }];

const TABS = [
  { id: 'family', label: 'Family' },
  { id: 'hobbies', label: 'Hobbies' },
  { id: 'work', label: 'Area of work' },
  { id: 'vehicles', label: 'Vehicles' },
  { id: 'documents', label: 'Documents' },
  { id: 'dues', label: 'Dues' },
  { id: 'privacy', label: 'Privacy & alerts' },
];

/**
 * Everything owner_search.aspx showed beneath the main owner form: the family
 * grid, the four repeaters (hobbies, work, vehicles, documents), the dues
 * summary and the privacy/notification toggles.
 */
export default function OwnerDetailPanel({ resident, onClose }) {
  const [tab, setTab] = useState('family');
  const [data, setData] = useState({});
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);
  const toast = useToast();
  // name -> message, for the fields the last Add found empty.
  const [fieldErrors, setFieldErrors] = useState({});
  const [confirming, setConfirming] = useState(null);

  // Add-row inputs, one per tab.
  // occupation and dob mirror owner_search.aspx's txt_f_occu / txt_f_dob.
  const [familyForm, setFamilyForm] = useState({
    name: '',
    relation: '',
    contact: '',
    occupation: '',
    dob: '',
  });
  const [hobby, setHobby] = useState('');
  const [workArea, setWorkArea] = useState('');
  const [vehicle, setVehicle] = useState({ vehicleNo: '', vehicleType: '0', modelName: '' });
  const [docForm, setDocForm] = useState({ docName: '', docPath: '' });
  const [privacy, setPrivacy] = useState({ maskPhone: false, maskEmail: false, shareGate: false });

  const ownerId = resident?.owner_id;
  const flatId = resident?.flat_id;

  const load = useCallback(async () => {
    if (!ownerId) return;
    setLoading(true);
    setError(null);
    try {
      const [fam, hob, work, veh, docs, dues] = await Promise.all([
        familyApi.list(ownerId).catch(() => ({ items: [] })),
        ownerExtras.hobbies(ownerId).catch(() => ({ items: [] })),
        ownerExtras.workAreas(ownerId).catch(() => ({ items: [] })),
        flatId ? ownerExtras.vehicles(flatId).catch(() => ({ items: [] })) : { items: [] },
        flatId ? ownerExtras.documents(flatId).catch(() => ({ items: [] })) : { items: [] },
        flatId ? ownerExtras.dues(flatId).catch(() => ({ items: [] })) : { items: [] },
      ]);
      setData({
        family: fam.items ?? [],
        hobbies: hob.items ?? [],
        work: work.items ?? [],
        vehicles: veh.items ?? [],
        documents: docs.items ?? [],
        dues: dues.items ?? [],
      });
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  }, [ownerId, flatId]);

  useEffect(() => {
    if (resident) {
      setTab('family');
      setPrivacy({
        maskPhone: Boolean(resident.mask_phone),
        maskEmail: Boolean(resident.mask_email),
        shareGate: Boolean(resident.share_gate),
      });
      load();
    }
  }, [resident, load]);

  /**
   * Run a mutation, then refresh the panel.
   *
   * `done` is what the toast says on success — "Vehicle added", "Hobbies
   * saved". Every path through this panel used to succeed in silence, which on
   * a tabbed dialog is especially confusing: the list redraws behind the tab
   * you are on and nothing tells you the write landed.
   */
  const mutate = async (fn, done) => {
    setBusy(true);
    setError(null);
    try {
      await fn();
      await load();
      if (done) toast.success(done, { title: 'Saved' });
      return true;
    } catch (err) {
      setError(err);
      toast.error(err?.message ?? 'The change could not be saved. Please try again.');
      return false;
    } finally {
      setBusy(false);
    }
  };

  const rows = data[tab === 'work' ? 'work' : tab] ?? [];

  const tabsWithCounts = TABS.map((t) => ({
    ...t,
    count: ['family', 'hobbies', 'work', 'vehicles', 'documents'].includes(t.id)
      ? (data[t.id] ?? []).length
      : undefined,
  }));

  return (
    <>
      <Modal
        open={Boolean(resident)}
        title={`${resident?.name ?? ''} — ${resident?.Unit ?? ''}`}
        onClose={onClose}
        footer={
          <button type="button" className="btn-secondary" onClick={onClose}>
            Close
          </button>
        }
      >
        <Tabs tabs={tabsWithCounts} active={tab} onChange={setTab} className="mb-4" />
        <ErrorNotice error={error} />

        {loading ? (
          <Spinner />
        ) : (
          <div className="min-h-[14rem]">
            {tab === 'family' ? (
              <>
                {rows.length === 0 ? (
                  <EmptyState title="No family members recorded" />
                ) : (
                  /* Six columns inside a dialog — the narrowest place a table
                     appears. Scrolls rather than crushing the columns. */
                  <div className="overflow-x-auto">
                  <table className="min-w-full stacked-table">
                    <thead>
                      <tr>
                        <th className="table-head">Name</th>
                        <th className="table-head">Relation</th>
                        <th className="table-head">Occupation</th>
                        <th className="table-head">Date of birth</th>
                        <th className="table-head">Contact</th>
                        <th className="table-head sr-only">Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {rows.map((r) => (
                        <tr key={r.o_ex_id}>
                          <td className="table-cell font-medium text-slate-800" data-label="Name">{r.f_name}</td>
                          <td className="table-cell" data-label="Relation">{r.relation || '—'}</td>
                          <td className="table-cell" data-label="Occupation">{r.f_occu || '—'}</td>
                          <td className="table-cell" data-label="Date of birth">
                            {r.f_dob ? new Date(r.f_dob).toLocaleDateString() : '—'}
                          </td>
                          <td className="table-cell" data-label="Contact">{r.contactNo || '—'}</td>
                          <td className="table-cell text-right" data-actions="">
                            <button
                              type="button"
                              className="btn-danger"
                              onClick={() =>
                                setConfirming({
                                  title: 'Remove family member',
                                  message: `Remove ${r.f_name}?`,
                                  run: () => familyApi.remove(r.o_ex_id, ownerId),
                                  done: 'Family member removed.',
                                })
                              }
                            >
                              Remove
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                  </div>
                )}
                <form
                  className="mt-4 grid gap-3 border-t border-slate-200 pt-4 sm:grid-cols-3 lg:grid-cols-6"
                  onSubmit={async (e) => {
                    e.preventDefault();
                    const missing = validateFields(FAMILY_FIELDS, familyForm);
                    setFieldErrors(missing);
                    if (Object.keys(missing).length) {
                      focusFirstInvalid(FAMILY_FIELDS, missing);
                      return;
                    }
                    if (
                      await mutate(
                        () => familyApi.create({ ownerId, ...familyForm }),
                        'Family member added.',
                      )
                    ) {
                      setFamilyForm({ name: '', relation: '', contact: '', occupation: '', dob: '' });
                    }
                  }}
                >
                  <TextField
                    label="Name"
                    name="fname"
                    required
                    error={fieldErrors.name}
                    value={familyForm.name}
                    onChange={(e) => {
                      const { value } = e.target;
                      setFamilyForm((p) => ({ ...p, name: value }));
                      setFieldErrors((p) => (p.name ? { ...p, name: undefined } : p));
                    }}
                  />
                  <TextField
                    label="Relation"
                    name="frel"
                    required
                    error={fieldErrors.relation}
                    value={familyForm.relation}
                    onChange={(e) => {
                      const { value } = e.target;
                      setFamilyForm((p) => ({ ...p, relation: value }));
                      setFieldErrors((p) => (p.relation ? { ...p, relation: undefined } : p));
                    }}
                  />
                  <TextField
                    label="Occupation"
                    name="foccu"
                    value={familyForm.occupation}
                    onChange={(e) => setFamilyForm((p) => ({ ...p, occupation: e.target.value }))}
                  />
                  <TextField
                    label="Date of birth"
                    name="fdob"
                    type="date"
                    max={new Date().toISOString().slice(0, 10)}
                    value={familyForm.dob}
                    onChange={(e) => setFamilyForm((p) => ({ ...p, dob: e.target.value }))}
                  />
                  <TextField
                    label="Contact"
                    name="fcon"
                    value={familyForm.contact}
                    onChange={(e) => setFamilyForm((p) => ({ ...p, contact: e.target.value }))}
                  />
                  <div className="flex items-end">
                    <button
                      type="submit"
                      className="btn-primary w-full"
                      disabled={busy || !familyForm.name || !familyForm.relation}
                    >
                      Add
                    </button>
                  </div>
                </form>
              </>
            ) : null}

            {tab === 'hobbies' || tab === 'work' ? (
              <>
                {rows.length === 0 ? (
                  <EmptyState title={`No ${tab === 'hobbies' ? 'hobbies' : 'areas of work'} recorded`} />
                ) : (
                  <ul className="flex flex-wrap gap-2">
                    {rows.map((r, i) => (
                      <li
                        key={i}
                        className="rounded-full bg-slate-100 px-3 py-1 text-sm text-slate-700"
                      >
                        {r.hobby ?? r.area_of_work}
                      </li>
                    ))}
                  </ul>
                )}
                <form
                  className="mt-4 flex flex-wrap items-end gap-3 border-t border-slate-200 pt-4"
                  onSubmit={async (e) => {
                    e.preventDefault();
                    const isHobby = tab === 'hobbies';
                    /*
                     * Trimmed before it is sent, not just before it is tested:
                     * the Add button only checks for a falsy value, so a box
                     * holding spaces enabled it and filed "   " as a hobby.
                     */
                    const entry = (isHobby ? hobby : workArea).trim();
                    if (!entry) return;
                    const ok = await mutate(
                      () =>
                        isHobby
                          ? ownerExtras.addHobby({ ownerId, hobby: entry })
                          : ownerExtras.addWorkArea({ ownerId, areaOfWork: entry }),
                      isHobby ? 'Hobby added.' : 'Area of work added.',
                    );
                    if (ok) (isHobby ? setHobby : setWorkArea)('');
                  }}
                >
                  <TextField
                    label={tab === 'hobbies' ? 'Hobby' : 'Area of work'}
                    name="extra"
                    className="w-64"
                    value={tab === 'hobbies' ? hobby : workArea}
                    onChange={(e) => (tab === 'hobbies' ? setHobby : setWorkArea)(e.target.value)}
                  />
                  <button
                    type="submit"
                    className="btn-primary"
                    disabled={busy || !(tab === 'hobbies' ? hobby : workArea).trim()}
                  >
                    Add
                  </button>
                  {rows.length ? (
                    <button
                      type="button"
                      className="btn-secondary"
                      disabled={busy}
                      onClick={() =>
                        setConfirming({
                          title: 'Clear all',
                          message:
                            'The stored procedure removes every entry for this person, not one row. Continue?',
                          run: () =>
                            tab === 'hobbies'
                              ? ownerExtras.clearHobbies(ownerId)
                              : ownerExtras.clearWorkAreas(ownerId),
                          done: tab === 'hobbies' ? 'All hobbies cleared.' : 'All work areas cleared.',
                        })
                      }
                    >
                      Clear all
                    </button>
                  ) : null}
                </form>
              </>
            ) : null}

            {tab === 'vehicles' ? (
              <>
                {rows.length === 0 ? (
                  <EmptyState title="No vehicles recorded" />
                ) : (
                  <div className="overflow-x-auto">
                  <table className="min-w-full stacked-table">
                    <thead>
                      <tr>
                        <th className="table-head">Vehicle no.</th>
                        <th className="table-head">Model</th>
                        <th className="table-head">Type</th>
                        <th className="table-head">Parking</th>
                        <th className="table-head sr-only">Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {rows.map((r) => (
                        <tr key={r.vehicle_id}>
                          <td className="table-cell font-medium text-slate-800" data-label="Vehicle no.">{r.vehicle_no}</td>
                          <td className="table-cell" data-label="Model">{r.model_name || '—'}</td>
                          <td className="table-cell" data-label="Type">
                            {Number(r.vehicle_type) === 0 ? 'Two-wheeler' : 'Four-wheeler'}
                          </td>
                          <td className="table-cell" data-label="Parking">{r.parking_status || 'Not allotted'}</td>
                          <td className="table-cell text-right" data-actions="">
                            <button
                              type="button"
                              className="btn-danger"
                              onClick={() =>
                                setConfirming({
                                  title: 'Remove vehicle',
                                  message: `Remove ${r.vehicle_no}?`,
                                  run: () => ownerExtras.removeVehicle(r.vehicle_id),
                                  done: 'Vehicle removed.',
                                })
                              }
                            >
                              Remove
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                  </div>
                )}
                <form
                  className="mt-4 grid gap-3 border-t border-slate-200 pt-4 sm:grid-cols-4"
                  onSubmit={async (e) => {
                    e.preventDefault();
                    const missing = validateFields(VEHICLE_FIELDS, vehicle);
                    setFieldErrors(missing);
                    if (Object.keys(missing).length) {
                      focusFirstInvalid(VEHICLE_FIELDS, missing);
                      return;
                    }
                    if (
                      await mutate(
                        () =>
                          ownerExtras.addVehicle({
                            flatId,
                            vehicleNo: vehicle.vehicleNo,
                            vehicleType: Number(vehicle.vehicleType),
                            modelName: vehicle.modelName,
                          }),
                        'Vehicle added.',
                      )
                    ) {
                      setVehicle({ vehicleNo: '', vehicleType: '0', modelName: '' });
                    }
                  }}
                >
                  <TextField
                    label="Vehicle number"
                    name="vno"
                    required
                    error={fieldErrors.vehicleNo}
                    value={vehicle.vehicleNo}
                    onChange={(e) => {
                      const { value } = e.target;
                      setVehicle((p) => ({ ...p, vehicleNo: value }));
                      setFieldErrors((p) => (p.vehicleNo ? { ...p, vehicleNo: undefined } : p));
                    }}
                  />
                  <TextField
                    label="Model"
                    name="vmodel"
                    value={vehicle.modelName}
                    onChange={(e) => setVehicle((p) => ({ ...p, modelName: e.target.value }))}
                  />
                  <SelectField
                    label="Type"
                    name="vtype"
                    placeholder=""
                    options={[
                      { value: '0', label: 'Two-wheeler' },
                      { value: '1', label: 'Four-wheeler' },
                    ]}
                    value={vehicle.vehicleType}
                    onChange={(e) => setVehicle((p) => ({ ...p, vehicleType: e.target.value }))}
                  />
                  <div className="flex items-end">
                    <button type="submit" className="btn-primary w-full" disabled={busy || !vehicle.vehicleNo}>
                      Add
                    </button>
                  </div>
                </form>
              </>
            ) : null}

            {tab === 'documents' ? (
              <>
                {rows.length === 0 ? (
                  <EmptyState title="No documents uploaded" />
                ) : (
                  <div className="overflow-x-auto">
                  <table className="min-w-full stacked-table">
                    <thead>
                      <tr>
                        <th className="table-head">Document</th>
                        <th className="table-head">Type</th>
                        <th className="table-head">Uploaded</th>
                        <th className="table-head sr-only">Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {rows.map((r, i) => (
                        <tr key={`${r.document_id}-${i}`}>
                          <td className="table-cell font-medium text-slate-800" data-label="Document">{r.doc_name}</td>
                          <td className="table-cell" data-label="Type">{r.doc_type || '—'}</td>
                          <td className="table-cell" data-label="Uploaded">
                            {r.upload_date ? new Date(r.upload_date).toLocaleDateString() : '—'}
                          </td>
                          <td className="table-cell text-right" data-actions="">
                            {/* document_id 0 means the row comes from an
                                owner_master column, not owner_documents. */}
                            {Number(r.document_id) > 0 ? (
                              <button
                                type="button"
                                className="btn-danger"
                                onClick={() =>
                                  setConfirming({
                                    title: 'Remove document',
                                    message: `Remove ${r.doc_name}?`,
                                    run: () => ownerExtras.removeDocument(r.document_id),
                                    done: 'Document removed.',
                                  })
                                }
                              >
                                Remove
                              </button>
                            ) : (
                              <span className="text-xs text-slate-400">From owner record</span>
                            )}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                  </div>
                )}
                <div className="mt-4 grid gap-3 border-t border-slate-200 pt-4 sm:grid-cols-2">
                  <TextField
                    label="Document name"
                    name="docname"
                    value={docForm.docName}
                    onChange={(e) => setDocForm((p) => ({ ...p, docName: e.target.value }))}
                  />
                  <FileUploadField
                    label="Upload file"
                    category="owner-documents"
                    hint="JPEG, PNG or PDF, up to 10 MB"
                    onUploaded={async (f) => {
                      if (!f) return;
                      await mutate(
                        () =>
                          ownerExtras.recordDocument({
                            flatId,
                            docName: docForm.docName || f.originalName,
                            docPath: f.path,
                          }),
                        'Document uploaded.',
                      );
                      setDocForm({ docName: '', docPath: '' });
                    }}
                  />
                </div>
              </>
            ) : null}

            {tab === 'dues' ? (
              rows.length === 0 ? (
                <EmptyState title="No outstanding dues" />
              ) : (
                <div className="overflow-x-auto">
                <table className="min-w-full stacked-table">
                  <thead>
                    <tr>
                      <th className="table-head">Month</th>
                      <th className="table-head">Year</th>
                      <th className="table-head text-right">Amount</th>
                      <th className="table-head text-right">Interest</th>
                      <th className="table-head text-right">Total</th>
                    </tr>
                  </thead>
                  <tbody>
                    {rows.map((r, i) => (
                      <tr key={i}>
                        <td className="table-cell font-medium text-slate-800" data-label="Month">{r.month}</td>
                        <td className="table-cell" data-label="Year">{r.year}</td>
                        <td className="table-cell text-right" data-label="Amount">{money(r.amt_forward)}</td>
                        <td className="table-cell text-right" data-label="Interest">{money(r.tax_interest_amt)}</td>
                        <td className="table-cell text-right font-medium" data-label="Total">{money(r.total)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
                </div>
              )
            ) : null}

            {tab === 'privacy' ? (
              <div className="space-y-4">
                <div className="space-y-3">
                  <CheckboxField
                    label="Hide phone number from other residents"
                    checked={privacy.maskPhone}
                    onChange={(e) => setPrivacy((p) => ({ ...p, maskPhone: e.target.checked }))}
                  />
                  <CheckboxField
                    label="Hide email address from other residents"
                    checked={privacy.maskEmail}
                    onChange={(e) => setPrivacy((p) => ({ ...p, maskEmail: e.target.checked }))}
                  />
                  <CheckboxField
                    label="Share details with the gate"
                    checked={privacy.shareGate}
                    onChange={(e) => setPrivacy((p) => ({ ...p, shareGate: e.target.checked }))}
                  />
                </div>
                <div className="flex flex-wrap gap-2 border-t border-slate-200 pt-4">
                  <button
                    type="button"
                    className="btn-primary"
                    disabled={busy}
                    onClick={() =>
                      mutate(
                        () => ownerExtras.saveSettings(ownerId, privacy),
                        'Privacy settings saved.',
                      )
                    }
                  >
                    Save privacy settings
                  </button>
                  <button
                    type="button"
                    className="btn-secondary"
                    disabled={busy}
                    onClick={() =>
                      setConfirming({
                        title: 'Deactivate login',
                        message: `Deactivate app access for ${resident?.name}? Their record is kept.`,
                        run: () => ownerExtras.deactivate(ownerId, { kind: 'owner' }),
                        done: 'App access deactivated.',
                      })
                    }
                  >
                    Deactivate app login
                  </button>
                </div>
              </div>
            ) : null}
          </div>
        )}
      </Modal>

      <ConfirmDialog
        open={Boolean(confirming)}
        title={confirming?.title}
        message={confirming?.message}
        confirmLabel="Confirm"
        busy={busy}
        onCancel={() => setConfirming(null)}
        onConfirm={async () => {
          // Each confirmable action supplies its own past-tense line, since
          // "Saved" reads oddly for a removal or a deactivation.
          await mutate(confirming.run, confirming.done);
          setConfirming(null);
        }}
      />
    </>
  );
}
