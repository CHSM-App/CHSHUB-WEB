import GenericCrudPage from '../GenericCrudPage.jsx';
import { village } from '@/api/modules';

/*
 * Government schemes a village runs.
 *
 * The dashboard's "Add Government Scheme" tile used to open Announcements: a
 * scheme was posted as a notice, which is how the legacy page did it. A notice
 * cannot hold what a scheme is actually asked about at the counter — who
 * qualifies, what they get, whether applications have closed, and the GR it
 * comes from — so schemes have a record of their own.
 */

const money = (v) =>
  v == null || v === ''
    ? '—'
    : Number(v).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });

const day = (v) => (v ? new Date(v).toLocaleDateString() : '—');

/*
 * Whether applications are open. Worked out by the SP rather than here, so the
 * list, any export and anything added later all say the same thing.
 */
const STATUS_TONE = {
  Open: { bg: '#ecfdf5', color: '#065f46' },
  Upcoming: { bg: '#eff6ff', color: '#1e40af' },
  Closed: { bg: '#f8fafc', color: '#64748b' },
};

function StatusPill({ value }) {
  const tone = STATUS_TONE[value] ?? STATUS_TONE.Closed;
  return (
    <span
      className="inline-block rounded-full px-2.5 py-0.5 text-xs font-semibold"
      style={{ background: tone.bg, color: tone.color }}
    >
      {value ?? '—'}
    </span>
  );
}

export default function VillageSchemesPage() {
  return (
    <GenericCrudPage
      title="Government schemes"
      subtitle="Schemes the village runs, and who can apply"
      resource={{
        list: village.schemes,
        create: village.createScheme,
        update: village.updateScheme,
        remove: village.removeScheme,
      }}
      idKey="scheme_id"
      // sp_village_scheme takes no search parameter, so the term narrows the
      // loaded rows here — the same convention as the other village screens.
      filterRow={(r, term) =>
        [r.name, r.eligibility, r.gr_number, r.benefit_details]
          .join(' ')
          .toLowerCase()
          .includes(term)
      }
      columns={[
        { key: 'name', label: 'Scheme' },
        { key: 'eligibility', label: 'Who can apply' },
        {
          key: 'benefit_amount',
          label: 'Benefit',
          // A scheme may pay money, give something in kind, or both, so the
          // column shows whichever it has rather than assuming a figure.
          format: (v, row) =>
            [v == null ? null : `₹${money(v)}`, row.benefit_details].filter(Boolean).join(' — ') || '—',
          exportValue: (row) =>
            [row.benefit_amount == null ? null : money(row.benefit_amount), row.benefit_details]
              .filter(Boolean)
              .join(' — '),
        },
        { key: 'apply_until', label: 'Apply by', format: day },
        {
          key: 'status',
          label: 'Status',
          format: (v) => <StatusPill value={v} />,
          exportValue: (row) => row.status ?? '',
        },
        { key: 'gr_number', label: 'GR No.' },
      ]}
      /*
       * Only the name is required. A scheme is often announced before its
       * details are settled, and a half-filled record is more useful than
       * refusing to save one at all.
       */
      fields={[
        { name: 'name', label: 'Scheme name', required: true, span: 2 },
        { name: 'description', label: 'What the scheme is', type: 'textarea', span: 2 },
        {
          name: 'eligibility',
          label: 'Who can apply',
          type: 'textarea',
          span: 2,
          hint: 'In your own words — "BPL households", "farmers with under 2 hectares".',
        },
        { name: 'benefitAmount', label: 'Amount (₹)', type: 'number', step: '0.01' },
        {
          name: 'benefitDetails',
          label: 'Other benefit',
          hint: 'For a scheme that gives something other than money.',
        },
        { name: 'applyFrom', label: 'Applications open', type: 'date' },
        { name: 'applyUntil', label: 'Applications close', type: 'date' },
        { name: 'grNumber', label: 'GR number' },
        { name: 'grDate', label: 'GR date', type: 'date' },
      ]}
      toForm={(r) => ({
        name: r.name ?? '',
        description: r.description ?? '',
        eligibility: r.eligibility ?? '',
        benefitAmount: r.benefit_amount ?? '',
        benefitDetails: r.benefit_details ?? '',
        applyFrom: r.apply_from ? String(r.apply_from).slice(0, 10) : '',
        applyUntil: r.apply_until ? String(r.apply_until).slice(0, 10) : '',
        grNumber: r.gr_number ?? '',
        grDate: r.gr_date ? String(r.gr_date).slice(0, 10) : '',
      })}
      deleteLabel="Remove"
      deleteMessage={(r) =>
        `Remove ${r.name}? It stops being listed, but the record is kept — residents ask about schemes that have closed.`
      }
      emptyHint="Schemes added here are listed with who can apply and by when."
    />
  );
}
