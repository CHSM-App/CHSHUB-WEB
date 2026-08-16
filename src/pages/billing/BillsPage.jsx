import { useEffect, useMemo, useRef, useState } from 'react';
import { bills, generation } from '@/api/billing';
import { accountSettings } from '@/api/settings';
import { residents } from '@/api/masters';
import {
  ConfirmDialog,
  EmptyState,
  ErrorNotice,
  Field,
  InfoNotice,
  Modal,
  Spinner,
} from '@/components/ui.jsx';
import ExportToolbar from '@/components/ExportToolbar.jsx';
import { useToast } from '@/components/Toast.jsx';
import useSortedRows from '@/components/useSortedRows.js';
import { SortableHead, SortControl } from '@/components/SortableHead.jsx';

// The New Maintenance modal's own fields. Bill period is how many months the
// add-on charges are spread over — txt_period on the legacy form; the date is
// today's, as bind_date() filled it.
const newAddOn = () => ({ date: new Date().toISOString().slice(0, 10), duePeriodMonths: 1 });

// The fields behind maintenance_search.aspx's settings modal. They feed
// gen_bill and sp_new_maintenance, so a change here lands on the next run.
const EMPTY_SETTINGS = {
  ratePerSqFt: '',
  twoWheelerRate: '',
  fourWheelerRate: '',
  autoBillGeneration: false,
  billGenerationDay: 1,
  billDuePeriodDays: 0,
  interestRate: 0,
};

const settingsToForm = (s) => ({
  ratePerSqFt: s?.rate_per_sqfeet ?? '',
  twoWheelerRate: s?.two_wheeler_rate ?? '',
  fourWheelerRate: s?.four_wheeler_rate ?? '',
  autoBillGeneration: Boolean(s?.auto_bill_generation),
  billGenerationDay: s?.bill_gen_date ?? 1,
  billDuePeriodDays: s?.bill_due_period ?? 0,
  interestRate: s?.interest_rate ?? 0,
});

const money = (v) => Number(v ?? 0).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
/**
 * dd-MM-yyyy, as the legacy bill printed it.
 *
 * Not toLocaleDateString(): that follows the browser's locale, so a bill dated
 * 1 February rendered "2/1/2026" on a US-English browser — which an Indian
 * reader takes for 2 January. A bill is a demand for money; its dates cannot
 * depend on who opens it.
 */
const day = (v) => {
  if (!v) return '—';
  const d = new Date(v);
  const pad = (n) => String(n).padStart(2, '0');
  return `${pad(d.getDate())}-${pad(d.getMonth() + 1)}-${d.getFullYear()}`;
};

const RUN_EXPORT_COLUMNS = [
  { key: 'bill_id', label: 'Bill no.' },
  { key: 'month_name', label: 'Month' },
  { key: 'year', label: 'Year' },
  { key: 'bill_type_label', label: 'Type' },
  { key: 'gen_date', label: 'Bill date', exportValue: (r) => day(r.gen_date) },
  { key: 'due_date', label: 'Due date', exportValue: (r) => day(r.due_date) },
  { key: 'Status', label: 'Status' },
];

/*
 * The on-screen columns for the bill-runs list.
 *
 * Period reads "August 2026" but orders by the run's generation date: sorting
 * the label itself would file April before August and split a year across the
 * list. The two dates likewise order by timestamp rather than by the dd-mm-yyyy
 * text, which would otherwise sort every 1st of the month together.
 */
const RUN_COLUMNS = [
  { key: 'bill_id', label: 'Bill no.', sortValue: (r) => Number(r.bill_id ?? 0) },
  {
    key: 'period',
    label: 'Period',
    sortValue: (r) => (r.gen_date ? new Date(r.gen_date).getTime() : null),
  },
  { key: 'bill_type_label', label: 'Type' },
  {
    key: 'gen_date',
    label: 'Generated',
    sortValue: (r) => (r.gen_date ? new Date(r.gen_date).getTime() : null),
  },
  {
    key: 'due_date',
    label: 'Due',
    sortValue: (r) => (r.due_date ? new Date(r.due_date).getTime() : null),
  },
  { key: 'Status', label: 'Status' },
];

/**
 * Rupees in words, for the line the legacy bill closed with.
 *
 * Indian numbering: thousand, lakh, crore — not the western thousand/million.
 * Paise get their own clause when non-zero, as NumberToWords() did: a bill of
 * 1,765.38 reads "... Sixty Five Rupees and Thirty Eight Paise Only", not
 * "... Sixty Five Rupees Only" — dropping them understated every bill whose
 * charges divided unevenly across flats, which is most of them.
 */
function amountInWords(value) {
  const amount = Number(value) || 0;
  const n = Math.floor(amount);
  const paise = Math.round((amount - n) * 100);
  if (n === 0 && paise === 0) return 'Zero Rupees Only';

  const ones = [
    '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten',
    'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen',
    'Eighteen', 'Nineteen',
  ];
  const tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];

  const under100 = (x) =>
    x < 20 ? ones[x] : `${tens[Math.floor(x / 10)]}${x % 10 ? ' ' + ones[x % 10] : ''}`;
  const under1000 = (x) =>
    `${x >= 100 ? `${ones[Math.floor(x / 100)]} Hundred${x % 100 ? ' ' : ''}` : ''}${
      x % 100 ? under100(x % 100) : ''
    }`;

  const spell = (whole) => {
    if (whole === 0) return 'Zero';
    const parts = [];
    const crore = Math.floor(whole / 10000000);
    const lakh = Math.floor((whole % 10000000) / 100000);
    const thousand = Math.floor((whole % 100000) / 1000);
    const rest = whole % 1000;

    if (crore) parts.push(`${under1000(crore)} Crore`);
    if (lakh) parts.push(`${under1000(lakh)} Lakh`);
    if (thousand) parts.push(`${under1000(thousand)} Thousand`);
    if (rest) parts.push(under1000(rest));
    return parts.join(' ');
  };

  const words = `${spell(n)} Rupees`;
  return paise > 0 ? `${words} and ${spell(paise)} Paise Only` : `${words} Only`;
}

/** One flat's bill, in the shape the legacy print modal used. */
function BillSheet({ bill, columns }) {
  const lines = columns
    .map((c) => ({ name: bill[c.nameKey], amount: bill[c.amountKey] }))
    .filter((l) => l.name && l.amount != null);

  const forward = Number(bill.amt_forward || 0);

  /**
   * This run's own charges — the printed lines, added up.
   *
   * Neither stored column can stand in for them. total_amount means different
   * things to the two procedures: gen_bill writes the month's charges alone,
   * while sp_new_maintenance does `@total_amt = @total_amt + @amt_forward +
   * @tax_interest` and folds arrears in, so adding amt_forward below counted
   * the dues twice. `due` is consistent between them but drops as payments
   * settle against the bill — flat 102's February total read 31.49 over lines
   * adding to 996.15 once it had part-paid.
   *
   * The lines are what the resident is being charged, so they are the total.
   */
  const charges = lines.reduce((sum, l) => sum + Number(l.amount || 0), 0);

  const particulars = [
    ['Owner Name', bill.owner_name],
    ['Flat No', bill.flat_no],
    ['Wing Name', bill.w_name],
    ['Bill Date', day(bill.gen_date)],
    ['Area', bill.sq_ft ? `${bill.sq_ft} sq.ft` : '—'],
    ['Due Date', day(bill.due_date)],
  ];

  return (
    <article className="rounded border border-slate-300 p-5 print:break-after-page print:border-0">
      <h3 className="text-center text-base font-bold tracking-wide text-slate-900">
        MAINTENANCE BILL
      </h3>
      <div className="mt-2 text-center">
        <p className="text-sm font-semibold text-slate-800">{bill.society_name}</p>
        {bill.registration_no ? (
          <p className="text-xs text-slate-600">Registration No: {bill.registration_no}</p>
        ) : null}
        {bill.address1 ? <p className="text-xs text-slate-600">{bill.address1}</p> : null}
      </div>

      <table className="mt-4 w-full border border-slate-300 text-sm">
        <tbody>
          {[0, 2, 4].map((i) => (
            <tr key={i}>
              {particulars.slice(i, i + 2).map(([label, value]) => (
                <td key={label} className="border border-slate-300 px-3 py-1.5">
                  <strong>
                    {label}: {value || '—'}
                  </strong>
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>

      {/* Deliberately not `stacked-table`: this is the printed bill, and a bill
          has to keep its charge table on paper whatever the screen width. */}
      <table className="mt-3 w-full border border-slate-300 text-sm">
        <thead>
          <tr className="bg-slate-100">
            <th className="border border-slate-300 px-3 py-1.5 text-left">Sr. No</th>
            <th className="border border-slate-300 px-3 py-1.5 text-left">Nature of Charges</th>
            <th className="border border-slate-300 px-3 py-1.5 text-right">Amount (₹)</th>
          </tr>
        </thead>
        <tbody>
          {lines.length ? (
            lines.map((l, i) => (
              <tr key={l.name}>
                <td className="border border-slate-300 px-3 py-1.5" data-label="Sr. No">{i + 1}</td>
                <td className="border border-slate-300 px-3 py-1.5" data-label="Nature of Charges">{l.name}</td>
                <td className="border border-slate-300 px-3 py-1.5 text-right" data-label="Amount (₹)">
                  ₹ {money(l.amount)}
                </td>
              </tr>
            ))
          ) : (
            <tr>
              <td className="border border-slate-300 px-3 py-3 text-slate-500" colSpan={3}>
                No charge lines on this bill.
              </td>
            </tr>
          )}
        </tbody>
      </table>

      {/* Label left, figure right, with only the row rules drawn — a line
          between the two columns would cut the label off from its amount. */}
      <table className="mt-3 w-full border border-slate-300 text-sm">
        <tbody>
          <tr className="border-b border-slate-300">
            <td className="px-3 py-1.5">
              <strong>Total:</strong>
            </td>
            <td className="px-3 py-1.5 text-right">₹ {money(charges)}</td>
          </tr>
          {/* Hidden only when nothing is owed, as Repeater3_ItemDataBound did:
              "Dues as of ...: 0.00" tells a resident with a clean ledger
              nothing. Any arrears must show — they are usually most of what is
              payable, and a bill listing 153.85 while 15,819.20 stands unpaid
              would leave the society nothing to collect against. */}
          {forward !== 0 ? (
            <tr className="border-b border-slate-300">
              <td className="px-3 py-1.5">
                <strong>Dues as of {day(bill.gen_date)}:</strong>
              </td>
              <td className="px-3 py-1.5 text-right">₹ {money(forward)}</td>
            </tr>
          ) : null}
          <tr className="border-b border-slate-300 bg-[#fdf1f1]">
            <td className="px-3 py-1.5">
              <strong>Grand Total:</strong>
            </td>
            <td className="px-3 py-1.5 text-right">
              <strong>₹ {money(charges + forward)}</strong>
            </td>
          </tr>
          <tr>
            <td className="px-3 py-1.5">
              <strong>Amount in Words:</strong>
            </td>
            {/* The grand total, not the month's charges. Words on a bill exist
                so the payable figure cannot be altered, so they have to name
                what is actually payable. maintenance_search.aspx spelled out
                total_amount because it had no field for the grand total —
                it summed the two inline in the template — which left eight of
                ten bills carrying identical words above quite different
                amounts due. */}
            <td className="px-3 py-1.5 text-right">{amountInWords(charges + forward)}</td>
          </tr>
        </tbody>
      </table>
    </article>
  );
}

/** Bill runs, and the per-flat detail behind each one. */
export default function BillsPage() {
  const [runs, setRuns] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [yearFilter, setYearFilter] = useState('');
  const [search, setSearch] = useState('');
  // Read once so the page knows whether bills generate on a schedule.
  const [societySettings, setSocietySettings] = useState(null);

  const [detail, setDetail] = useState(null); // { run, items, chargeColumns }
  const [detailLoading, setDetailLoading] = useState(false);
  // This month's charge heads — the Nature of Charges panel on the legacy page.
  const [charges, setCharges] = useState(null);

  // "New Maintenance" — the Add modal, which raises an add-on bill run.
  const [addOn, setAddOn] = useState(null);
  const [confirmRegular, setConfirmRegular] = useState(false);
  const [confirmDuplicate, setConfirmDuplicate] = useState(false);
  const [running, setRunning] = useState(false);
  const toast = useToast();
  const [notice, setNotice] = useState(null);

  /**
   * Both lists, because a run changes both: it adds a row here and retires the
   * add-on heads it billed. Reloading only the runs left the Add modal still
   * offering charges the run had just spent.
   */
  const reload = async () => {
    const [data] = await Promise.all([
      bills.list(),
      bills
        .charges()
        .then(setCharges)
        .catch(() => setCharges(null)),
    ]);
    setRuns(data.items ?? []);
  };

  /**
   * gen_bill — the monthly run. It skips a society already billed this month.
   *
   * The skip is a normal outcome, not an error: the API answers 200 with
   * generated:false. Reporting it matters — otherwise the dialog closes, the
   * grid is unchanged, and there is no way to tell "already billed" apart from
   * "the button did nothing".
   */
  const runRegular = async () => {
    setRunning(true);
    setError(null);
    setNotice(null);
    try {
      const result = await generation.runRegular({ confirm: true });
      setConfirmRegular(false);
      await reload();
      setNotice({
        tone: result?.generated ? 'success' : 'info',
        message: result?.generated
          ? `Regular bill generated. Bill #${result.latestRun?.bill_id ?? ''}`.trim()
          : (result?.message ??
            'No bills generated — this month is already billed, or there are no eligible flats.'),
      });
    } catch (err) {
      setError(err);
      // The success banner above is richer than a toast could be, so only the
      // failure is raised here.
      toast.error(err?.message ?? 'The bill run could not be completed. Please try again.');
    } finally {
      setRunning(false);
    }
  };

  /**
   * sp_new_maintenance 'generate' — ad-hoc charges, on top of the monthly bill.
   *
   * The procedure has no duplicate guard of its own: every call raises another
   * set of charges. The API refuses a second run on a day that already has one
   * and answers 409; that is worth asking about rather than swallowing, since
   * the legitimate case — two genuinely separate add-ons in a day — does exist.
   */
  const runAddOn = async (event, { allowDuplicate = false } = {}) => {
    event?.preventDefault();
    setRunning(true);
    setError(null);
    setNotice(null);
    try {
      const result = await generation.runAddOn({
        confirm: true,
        duePeriodMonths: Number(addOn.duePeriodMonths) || 1,
        ...(allowDuplicate ? { allowDuplicate: true } : {}),
      });
      setAddOn(null);
      setConfirmDuplicate(false);
      await reload();
      setNotice({
        tone: result?.generated ? 'success' : 'info',
        message: result?.generated
          ? `Add-on bill generated. Bill #${result.latestRun?.bill_id ?? ''}`.trim()
          : 'No add-on bill generated — there are no active add-on charges, or no eligible flats.',
      });
    } catch (err) {
      // A 409 is not a failure here — it opens the duplicate confirmation.
      if (err?.status === 409 && !allowDuplicate) setConfirmDuplicate(true);
      else {
        setError(err);
        toast.error(err?.message ?? 'The add-on run could not be completed. Please try again.');
      }
    } finally {
      setRunning(false);
    }
  };

  // "Select Customer" — the legacy Email modal's owner picker.
  const [emailPicker, setEmailPicker] = useState(null);

  const openEmail = async () => {
    setEmailPicker({ loading: true, owners: [], selected: [] });
    try {
      const d = await residents.list();
      // Only residents with an address on file can be written to.
      const owners = (d.items ?? []).filter((o) => String(o.email ?? '').trim());
      setEmailPicker({ loading: false, owners, selected: owners.map((o) => o.owner_id) });
    } catch (err) {
      setError(err);
      setEmailPicker(null);
    }
  };

  const toggleRecipient = (ownerId) =>
    setEmailPicker((p) => ({
      ...p,
      selected: p.selected.includes(ownerId)
        ? p.selected.filter((x) => x !== ownerId)
        : [...p.selected, ownerId],
    }));

  /**
   * Hands the selected addresses to the user's mail client.
   *
   * Nothing is sent from here — this application has no mail transport, and
   * the legacy Email button had no handler behind it either. A draft the user
   * sends themselves is honest about that, and keeps the addresses out of a
   * delivery path nobody is monitoring for bounces.
   */
  const composeEmail = () => {
    const chosen = emailPicker.owners.filter((o) => emailPicker.selected.includes(o.owner_id));
    if (!chosen.length) return;

    const to = chosen.map((o) => o.email).join(',');
    const subject = `Maintenance bill — ${new Date().toLocaleDateString()}`;
    // window.open rather than assigning location.href: the page stays put if
    // no mail client is registered, instead of navigating away from the app.
    window.open(
      `mailto:${encodeURIComponent(to)}?subject=${encodeURIComponent(subject)}`,
      '_self',
    );
    setEmailPicker(null);
  };

  // "Regular Maintenance Settings", the modal this page opened.
  const [settings, setSettings] = useState(null);
  const [settingsSaving, setSettingsSaving] = useState(false);
  const [settingsError, setSettingsError] = useState(null);

  const openSettings = async () => {
    setSettingsError(null);
    setSettings({ loading: true, form: { ...EMPTY_SETTINGS } });
    try {
      const d = await accountSettings.get();
      setSettings({ loading: false, form: settingsToForm(d.settings ?? d) });
    } catch (err) {
      setSettingsError(err);
      setSettings({ loading: false, form: { ...EMPTY_SETTINGS } });
    }
  };

  const saveSettings = async (event) => {
    event.preventDefault();
    setSettingsSaving(true);
    setSettingsError(null);
    try {
      const saved = await accountSettings.save(settings.form);
      // Auto generation decides whether the manual button is offered, so the
      // page has to see the new value — otherwise turning it on leaves the
      // button on screen until a reload.
      setSocietySettings(saved?.settings ?? { auto_bill_generation: settings.form.autoBillGeneration });
      setSettings(null);
      toast.success('Billing settings saved successfully.', { title: 'Saved' });
    } catch (err) {
      setSettingsError(err);
      toast.error(err?.message ?? 'The settings could not be saved. Please try again.');
    } finally {
      setSettingsSaving(false);
    }
  };

  const setSettingField = (key) => (e) => {
    const { value, type, checked } = e.target;
    setSettings((p) => ({
      ...p,
      form: { ...p.form, [key]: type === 'checkbox' ? checked : value },
    }));
  };

  /**
   * Open the Add modal on a fresh read of the charge heads.
   *
   * sp_new_maintenance switches an add-on head off once it has billed it, so
   * a set fetched at mount goes stale as soon as a run completes. Reading only
   * at mount left the modal offering heads already spent, and hid a head
   * activated on the Charges page until the whole page was reloaded.
   */
  const openAddOn = () => {
    setAddOn(newAddOn());
    bills
      .charges()
      .then(setCharges)
      .catch(() => setCharges(null));
  };

  useEffect(() => {
    let cancelled = false;
    accountSettings
      .get()
      .then((d) => !cancelled && setSocietySettings(d.settings ?? d))
      .catch(() => {});
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    bills
      .list()
      .then((data) => {
        if (!cancelled) setRuns(data.items ?? []);
      })
      .catch((err) => {
        if (!cancelled) setError(err);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  const years = useMemo(
    () => [...new Set(runs.map((r) => r.year).filter(Boolean))].sort((a, b) => b - a),
    [runs],
  );

  // Year first, then the search box — maintenance_search.aspx filtered the
  // rendered grid rather than re-querying, so the same happens here.
  const visible = useMemo(() => {
    const byYear = yearFilter ? runs.filter((r) => String(r.year) === yearFilter) : runs;
    const term = search.trim().toLowerCase();
    if (!term) return byYear;
    return byYear.filter((r) =>
      [r.bill_id, r.month_name, r.year, r.bill_type_label, r.Status].some((v) =>
        String(v ?? '').toLowerCase().includes(term),
      ),
    );
  }, [runs, yearFilter, search]);

  // Untouched until a heading is clicked, so the API's newest-first order —
  // which interleaves add-on runs with the regular ones — is what shows first.
  const { sorted: sortedRuns, sort, toggleSort } = useSortedRows(visible, RUN_COLUMNS);

  /**
   * gen_bill runs on a schedule when auto generation is on, so the manual
   * button is hidden then — showHideGenerateBillBtn() did the same. Running it
   * by hand as well would bill the society twice in a month.
   */
  const autoGeneration = Boolean(societySettings?.auto_bill_generation);

  // The stack of bill sheets, so the PDF is made from what is on screen
  // rather than rebuilt from the rows a second time.
  const billSheetsRef = useRef(null);
  const [billsPdfBusy, setBillsPdfBusy] = useState(false);

  const downloadBills = async () => {
    const node = billSheetsRef.current;
    if (!node) return;
    setBillsPdfBusy(true);

    // html2canvas captures the box as laid out, so a scrolled container gives
    // only the visible slice — the same way printing did. The cap is lifted
    // for the capture and put back afterwards.
    const { maxHeight, overflow } = node.style;
    node.style.maxHeight = 'none';
    node.style.overflow = 'visible';
    try {
      const { elementsToPdf } = await import('@/lib/pdf');
      const period = [detail?.run?.month_name, detail?.run?.year].filter(Boolean).join('-');
      // One sheet per page: capturing the stack as a single image would cut
      // bills wherever the page happened to end.
      await elementsToPdf(node.children, `maintenance-bills${period ? `-${period}` : ''}`);
    } catch (err) {
      window.alert(`Could not create the PDF: ${err.message}`);
    } finally {
      node.style.maxHeight = maxHeight;
      node.style.overflow = overflow;
      setBillsPdfBusy(false);
    }
  };

  const openDetail = async (run) => {
    setDetailLoading(true);
    setDetail({ run, items: [], chargeColumns: [] });
    try {
      const data = await bills.get(run.bill_id);
      setDetail({ run, items: data.items ?? [], chargeColumns: data.chargeColumns ?? [] });
    } catch (err) {
      setError(err);
      setDetail(null);
    } finally {
      setDetailLoading(false);
    }
  };

  const detailTotal = detail?.items.reduce((sum, r) => sum + Number(r.total_amount || 0), 0) ?? 0;

  // Today plus the bill period, as the legacy form showed beneath the box.
  // Month-end is clamped — 31 Jan plus one month is 28 Feb, not 3 March.
  const addOnDueDate = useMemo(() => {
    const months = Number(addOn?.duePeriodMonths);
    if (!addOn || !Number.isFinite(months) || months < 0) return '';
    const from = new Date(addOn.date);
    if (Number.isNaN(from.getTime())) return '';
    const target = new Date(from.getFullYear(), from.getMonth() + months, 1);
    const lastDay = new Date(target.getFullYear(), target.getMonth() + 1, 0).getDate();
    target.setDate(Math.min(from.getDate(), lastDay));
    return target.toLocaleDateString();
  }, [addOn]);

  return (
    <section>
      <header className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-lg font-semibold text-slate-800">Maintenance bills</h1>
          <p className="text-sm text-slate-500">
            {visible.length === runs.length
              ? `${runs.length} bill run(s)`
              : `${visible.length} of ${runs.length} bill run(s)`}
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <input
            className="field-input w-52"
            placeholder="Search bills…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            aria-label="Search bills"
          />
          <select
            className="field-input w-40"
            value={yearFilter}
            onChange={(e) => setYearFilter(e.target.value)}
            aria-label="Filter by year"
          >
            <option value="">All years</option>
            {years.map((y) => (
              <option key={y} value={String(y)}>
                {y}
              </option>
            ))}
          </select>
          {/* maintenance_search.aspx's row was Add, Print, Download Report,
              Generate regular Bill, Settings. Print and the download live in
              the grid's own toolbar here — repeating them alongside would be
              two buttons for one action. */}
          <button type="button" className="btn-primary" onClick={openAddOn}>
            Add
          </button>
          {/* Hidden while auto generation is on, as showHideGenerateBillBtn()
              did — the scheduled run already raises this month's bill. */}
          {autoGeneration ? null : (
            <button type="button" className="btn-primary" onClick={() => setConfirmRegular(true)}>
              Generate regular bill
            </button>
          )}
          <button type="button" className="btn-primary" onClick={openSettings}>
            Settings
          </button>
        </div>
      </header>

      <ErrorNotice error={error} />
      <InfoNotice
        message={notice?.message}
        tone={notice?.tone}
        onDismiss={() => setNotice(null)}
      />

      <div className="card mt-3 overflow-hidden">
        {loading ? (
          <Spinner />
        ) : visible.length === 0 ? (
          <EmptyState title="No bill runs found" hint="Bills appear here once generated." />
        ) : (
          <>
            <ExportToolbar
              columns={RUN_EXPORT_COLUMNS}
              rows={visible}
              exportName="maintenance-bills"
              exportTitle="Maintenance bills"
            />
            <SortControl
              columns={RUN_COLUMNS}
              sort={sort}
              onSort={toggleSort}
              className="px-4 pb-2"
            />
            <div className="overflow-x-auto">
            <table className="min-w-full stacked-table">
              <thead>
                <tr>
                  {RUN_COLUMNS.map((c) => (
                    <SortableHead key={c.key} column={c} sort={sort} onSort={toggleSort} />
                  ))}
                  <th className="table-head sr-only">Actions</th>
                </tr>
              </thead>
              <tbody>
                {sortedRuns.map((run) => (
                  <tr key={run.bill_id} className="hover:bg-slate-50">
                    <td className="table-cell font-medium text-slate-800" data-label="Bill no.">#{run.bill_id}</td>
                    <td className="table-cell" data-label="Period">
                      {run.month_name} {run.year}
                    </td>
                    {/* Which button raised this run. Three November 2025 rows
                        sat next to each other reading "Bill Generated", one
                        monthly and two ad-hoc, with nothing to tell them apart. */}
                    <td className="table-cell" data-label="Type">
                      {run.bill_type_label ? (
                        <span
                          className={
                            run.bill_type_label === 'Regular'
                              ? 'rounded bg-[#fef2f2] px-2 py-0.5 text-xs font-medium text-[#b91c1c]'
                              : 'rounded bg-amber-50 px-2 py-0.5 text-xs font-medium text-amber-700'
                          }
                        >
                          {run.bill_type_label}
                        </span>
                      ) : (
                        '—'
                      )}
                    </td>
                    <td className="table-cell" data-label="Generated">
                      {day(run.gen_date)}
                    </td>
                    <td className="table-cell" data-label="Due">
                      {day(run.due_date)}
                    </td>
                    <td className="table-cell" data-label="Status">{run.Status || '—'}</td>
                    <td className="table-cell text-right" data-actions="">
                      <button type="button" className="btn-secondary" onClick={() => openDetail(run)}>
                        View flats
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            </div>
          </>
        )}
      </div>

      <Modal
        open={Boolean(detail)}
        title={
          detail ? `Bill #${detail.run.bill_id} — ${detail.run.month_name} ${detail.run.year}` : ''
        }
        onClose={() => setDetail(null)}
        maxWidth="max-w-4xl"
        footer={
          <>
            {detail && !detail.loading ? (
              <>
                <button
                  type="button"
                  className="btn-secondary"
                  onClick={downloadBills}
                  disabled={billsPdfBusy}
                >
                  {billsPdfBusy ? 'Preparing…' : 'Download'}
                </button>
                <button type="button" className="btn-primary" onClick={() => window.print()}>
                  Print
                </button>
              </>
            ) : null}
            <button type="button" className="btn-secondary" onClick={() => setDetail(null)}>
              Close
            </button>
          </>
        }
      >
        {detailLoading ? (
          <Spinner />
        ) : !detail?.items.length ? (
          <EmptyState title="No flats in this bill run" />
        ) : (
          <>
            <p className="mb-3 text-sm text-slate-600 print:hidden">
              {detail.items.length} flat(s) · total {money(detailTotal)}
            </p>
            {/* One printable bill per flat, as the legacy print modal laid them
                out — society header, the flat's particulars, the charge lines,
                then dues carried forward and the grand total. */}
            <div
              ref={billSheetsRef}
              className="max-h-[30rem] space-y-8 overflow-auto print:max-h-none print:overflow-visible"
            >
              {detail.items.map((row) => (
                <BillSheet key={`${row.flat_id}-${row.bill_no}`} bill={row} columns={detail.chargeColumns} />
              ))}
            </div>
          </>
        )}
      </Modal>

      {/* New Maintenance — the Add modal. It lists the month's charge heads
          and raises an add-on run over them, as the legacy modal did. */}
      <Modal
        open={Boolean(addOn)}
        title="New maintenance"
        onClose={() => setAddOn(null)}
        footer={
          <>
            <button
              type="button"
              className="btn-secondary"
              onClick={() => setAddOn(null)}
              disabled={running}
            >
              Cancel
            </button>
            {/* The legacy footer was Generate Bill, Email and Print. */}
            <button type="button" className="btn-secondary" onClick={openEmail}>
              Email
            </button>
            <button type="button" className="btn-secondary" onClick={() => window.print()}>
              Print
            </button>
            <button
              type="submit"
              form="addon-form"
              className="btn-primary"
              disabled={running || !charges?.items?.length}
            >
              {running ? 'Generating…' : 'Generate bill'}
            </button>
          </>
        }
      >
        {addOn ? (
          <form id="addon-form" onSubmit={runAddOn} className="space-y-4">
            <div className="grid gap-4 sm:grid-cols-2">
              {/* Date is today's and read-only, as bind_date() set it — the
                  run is stamped when it happens, not backdated. */}
              <Field label="Date" hint="The day this run is raised.">
                <input className="field-input" value={day(addOn.date)} readOnly />
              </Field>
              {/* The legacy form worked the due date out as the period was
                  typed — today plus that many months — so the effect of the
                  number is visible before the run happens. */}
              <Field
                label="Bill period"
                required
                hint={
                  addOnDueDate ? `Due date: ${addOnDueDate}` : 'In months.'
                }
              >
                <input
                  className="field-input"
                  type="number"
                  min="1"
                  placeholder="Enter in months"
                  value={addOn.duePeriodMonths}
                  onChange={(e) => setAddOn((p) => ({ ...p, duePeriodMonths: e.target.value }))}
                  required
                />
              </Field>
            </div>

            {charges?.items?.length ? (
              <div>
                <h3 className="mb-2 text-sm font-semibold text-slate-800">Nature of charges</h3>
                <div className="overflow-x-auto">
                <table className="min-w-full stacked-table">
                  <thead>
                    <tr>
                      <th className="table-head">Nature of charges</th>
                      <th className="table-head text-right">Amount</th>
                      <th className="table-head text-right">Amount per flat</th>
                    </tr>
                  </thead>
                  <tbody>
                    {charges.items.map((c) => (
                      <tr key={c.charge_id}>
                        <td className="table-cell font-medium text-slate-800" data-label="Nature of charges">{c.charges}</td>
                        <td className="table-cell text-right" data-label="Amount">{money(c.amount)}</td>
                        <td className="table-cell text-right" data-label="Amount per flat">{money(c.amount_per_flat)}</td>
                      </tr>
                    ))}
                  </tbody>
                  <tfoot>
                    <tr className="border-t-2 border-slate-300 bg-[#fdf1f1] font-semibold">
                      <td className="table-cell">Total amount</td>
                      <td className="table-cell text-right">
                        {money(charges.items.reduce((s, c) => s + Number(c.amount || 0), 0))}
                      </td>
                      <td className="table-cell text-right">
                        {money(charges.items.reduce((s, c) => s + Number(c.amount_per_flat || 0), 0))}
                      </td>
                    </tr>
                  </tfoot>
                </table>
                </div>
              </div>
            ) : (
              <div>
                <h3 className="mb-2 text-sm font-semibold text-slate-800">Nature of charges</h3>
                {/* The legacy grid's EmptyDataText, with the reason spelled
                    out — there is nothing to bill until a charge exists. */}
                <p className="rounded border border-slate-200 px-3 py-4 text-sm text-slate-500">
                  No expense for this month. Add charges under Maintenance Charges Master before
                  generating a bill.
                </p>
              </div>
            )}

            {/* sp_new_maintenance has no duplicate guard of its own — every
                call raises another set of charges — so the API refuses a
                second add-on run on the same day. */}
            <p className="text-xs text-slate-500">
              This raises real charges against every flat and cannot be undone from here.
            </p>

            <ErrorNotice error={error} />
          </form>
        ) : null}
      </Modal>

      {/* A second add-on on the same day. sp_new_maintenance would raise the
          charges again without complaint, so the API blocks it and this asks
          whether that is really meant. */}
      <ConfirmDialog
        open={confirmDuplicate}
        title="Another add-on bill today?"
        message="An add-on run has already gone out today. Running it again raises a second set of the same charges against every flat, and cannot be undone from here. Continue?"
        confirmLabel="Generate anyway"
        busy={running}
        onCancel={() => setConfirmDuplicate(false)}
        onConfirm={() => runAddOn(null, { allowDuplicate: true })}
      />

      <ConfirmDialog
        open={confirmRegular}
        title="Generate regular bill"
        message={
          `This raises this month's maintenance for every flat and cannot be undone from here. ` +
          `A society already billed this month is skipped. Continue?`
        }
        confirmLabel="Generate"
        busy={running}
        onCancel={() => setConfirmRegular(false)}
        onConfirm={runRegular}
      />

      {/* Select Customer — the legacy Email modal's picker. */}
      <Modal
        open={Boolean(emailPicker)}
        title="Select customer"
        onClose={() => setEmailPicker(null)}
        footer={
          <>
            <button type="button" className="btn-secondary" onClick={() => setEmailPicker(null)}>
              Close
            </button>
            <button
              type="button"
              className="btn-primary"
              onClick={composeEmail}
              disabled={!emailPicker?.selected?.length}
            >
              Email
            </button>
          </>
        }
      >
        {emailPicker?.loading ? (
          <Spinner />
        ) : !emailPicker?.owners?.length ? (
          <EmptyState
            title="No email addresses on file"
            hint="Add an address against a resident before writing to them."
          />
        ) : emailPicker ? (
          <div className="space-y-2">
            <label className="flex items-center gap-2 border-b border-slate-200 pb-2">
              <input
                type="checkbox"
                className="h-4 w-4 rounded border-slate-300"
                checked={emailPicker.selected.length === emailPicker.owners.length}
                onChange={(e) =>
                  setEmailPicker((p) => ({
                    ...p,
                    selected: e.target.checked ? p.owners.map((o) => o.owner_id) : [],
                  }))
                }
              />
              <span className="text-sm font-medium text-slate-700">Select all</span>
            </label>

            {emailPicker.owners.map((o) => (
              <label key={o.owner_id} className="flex items-center gap-2">
                <input
                  type="checkbox"
                  className="h-4 w-4 rounded border-slate-300"
                  checked={emailPicker.selected.includes(o.owner_id)}
                  onChange={() => toggleRecipient(o.owner_id)}
                />
                <span className="text-sm text-slate-800">
                  {o.name}
                  {o.Unit ? <span className="text-slate-500"> — {o.Unit}</span> : null}
                </span>
              </label>
            ))}

            {/* Said plainly: this opens a draft rather than sending, because
                the application has no mail transport of its own. */}
            <p className="border-t border-slate-200 pt-3 text-xs text-slate-500">
              Opens a draft in your mail app with the selected addresses filled in. Nothing is sent
              from here.
            </p>
          </div>
        ) : null}
      </Modal>

      {/* Regular Maintenance Settings — the legacy modal, field for field. */}
      <Modal
        open={Boolean(settings)}
        title="Regular maintenance settings"
        onClose={() => setSettings(null)}
        footer={
          <>
            <button
              type="button"
              className="btn-secondary"
              onClick={() => setSettings(null)}
              disabled={settingsSaving}
            >
              Cancel
            </button>
            <button
              type="submit"
              form="bill-settings-form"
              className="btn-primary"
              disabled={settingsSaving || settings?.loading}
            >
              {settingsSaving ? 'Saving…' : 'Save'}
            </button>
          </>
        }
      >
        {settings?.loading ? (
          <Spinner />
        ) : settings ? (
          <form id="bill-settings-form" onSubmit={saveSettings} className="grid gap-4 sm:grid-cols-2">
            <Field label="Per sq. ft. rate" required>
              <input
                className="field-input"
                type="number"
                step="0.01"
                value={settings.form.ratePerSqFt}
                onChange={setSettingField('ratePerSqFt')}
                required
              />
            </Field>
            <Field label="2 wheeler rate" required>
              <input
                className="field-input"
                type="number"
                step="0.01"
                value={settings.form.twoWheelerRate}
                onChange={setSettingField('twoWheelerRate')}
                required
              />
            </Field>
            <Field label="4 wheeler rate" required>
              <input
                className="field-input"
                type="number"
                step="0.01"
                value={settings.form.fourWheelerRate}
                onChange={setSettingField('fourWheelerRate')}
                required
              />
            </Field>
            <Field label="Generation day (1–31)" required>
              <input
                className="field-input"
                type="number"
                min="1"
                max="31"
                value={settings.form.billGenerationDay}
                onChange={setSettingField('billGenerationDay')}
                required
              />
            </Field>
            <Field label="Due date period (days)" required>
              <input
                className="field-input"
                type="number"
                min="0"
                value={settings.form.billDuePeriodDays}
                onChange={setSettingField('billDuePeriodDays')}
                required
              />
            </Field>
            {/* gen_bill charges this on arrears at bill time. It was fixed at
                21 inside the procedure with nothing to edit it, so a society
                that had resolved on a lower rate — or none — was stuck paying
                the statutory maximum. 21% is the Act's ceiling, hence the max. */}
            <Field
              label="Interest on arrears (% per year)"
              hint="Charged on unpaid dues each month. 0 to charge none."
            >
              <input
                className="field-input"
                type="number"
                step="0.01"
                min="0"
                max="21"
                value={settings.form.interestRate}
                onChange={setSettingField('interestRate')}
              />
            </Field>
            <label className="flex items-center gap-2 self-end pb-2">
              <input
                type="checkbox"
                className="h-4 w-4 rounded border-slate-300"
                checked={settings.form.autoBillGeneration}
                onChange={setSettingField('autoBillGeneration')}
              />
              <span className="text-sm text-slate-700">Auto maintenance generation</span>
            </label>
            <div className="sm:col-span-2">
              <ErrorNotice error={settingsError} />
            </div>
          </form>
        ) : null}
      </Modal>
    </section>
  );
}
