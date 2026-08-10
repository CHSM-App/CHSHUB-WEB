import { useEffect, useState } from 'react';
import { reports } from '@/api/modules';

/**
 * Standard letterhead for a printed / exported report.
 *
 * The legacy pages each rolled their own: printshop.aspx handed a DataTable to
 * an RDLC that carried no heading at all, while ownerwise_maintenance.aspx
 * built one by hand inside a 700-line jsPDF routine and a second time inside
 * its print-window writer. The two never quite matched.
 *
 * Rendering it as a real DOM node instead means the same markup is what the
 * user sees, what the browser prints, and what the PDF captures.
 *
 * `print:block` — hidden on screen, shown on paper. The screen already has the
 * page header and filter form for context; paper has neither.
 */

/** Society details, fetched once and shared by every report on the page. */
export function useSocietyInfo() {
  const [info, setInfo] = useState(null);
  useEffect(() => {
    let cancelled = false;
    reports
      .societyInfo()
      .then((d) => !cancelled && setInfo(d.info ?? d ?? null))
      .catch(() => !cancelled && setInfo(null));
    return () => {
      cancelled = true;
    };
  }, []);
  return info;
}

/** Address parts joined with ", ", empty ones dropped. */
export const societyAddress = (info) =>
  [
    info?.off_address1,
    info?.off_address2,
    info?.city,
    info?.division,
    info?.district,
    info?.state,
    info?.pincode,
  ]
    .map((p) => (p == null ? '' : String(p).trim()))
    .filter(Boolean)
    .join(', ');

/**
 * Mirrors what tableToPdf draws: a centred title over an indigo rule, then the
 * run criteria in a tinted box with a left accent bar. Keeping the two in step
 * means the printed page and the downloaded PDF look like the same document.
 *
 * @param title    report name, e.g. "Ownerwise Maintenance Bill Report"
 * @param info     society record from useSocietyInfo(); only used when
 *                 `letterhead` is set — the legacy print view showed none
 * @param filters  [{ label, value }] — the criteria the report was run with
 * @param screen   also show on screen (default false: print and PDF only)
 */
export default function ReportHeader({
  title,
  info,
  filters = [],
  screen = false,
  letterhead = false,
  // Each legacy report carried its own accent: ownerwise_maintenance.aspx used
  // indigo, v_profite_loss.aspx a darker navy. Passing it keeps the heading in
  // step with the table beneath it.
  accent = '#667eea',
}) {
  const address = societyAddress(info);
  const shown = filters.filter((f) => f && f.value !== '' && f.value != null);

  return (
    <div className={`${screen ? 'block' : 'hidden print:block'} mb-4`}>
      {letterhead ? (
        <div className="pb-2 text-center">
          <h2 className="text-base font-bold text-slate-900">{info?.name ?? 'Society'}</h2>
          {address ? <p className="text-[11px] text-slate-700">{address}</p> : null}
          {info?.registration_no ? (
            <p className="text-[11px] text-slate-700">Reg. No: {info.registration_no}</p>
          ) : null}
        </div>
      ) : null}

      <h3
        className="pb-2 text-center text-xl font-bold text-slate-700"
        style={{ borderBottom: `2px solid ${accent}` }}
      >
        {title}
      </h3>

      {shown.length ? (
        <div
          className="mt-4 bg-slate-50 px-4 py-3 text-[13px]"
          style={{ borderLeft: `4px solid ${accent}` }}
        >
          {shown.map((f) => (
            <div key={f.label} className="flex gap-2 leading-6">
              <span className="min-w-[110px] font-bold text-slate-800">{f.label}:</span>
              <span className="text-slate-600">{f.value}</span>
            </div>
          ))}
        </div>
      ) : null}
    </div>
  );
}

/**
 * Closing line for a printed report — when it was produced.
 *
 * The legacy print window wrote a centred "Generated on: …" above a rule, in
 * the en-IN long form (10 Aug 2026, 05:52 pm); both are kept.
 */
export function ReportFooter({ screen = false }) {
  const when = new Date()
    .toLocaleString('en-IN', {
      day: 'numeric',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      hour12: true,
    })
    .replace(/\bAM\b/, 'am')
    .replace(/\bPM\b/, 'pm');

  return (
    <div
      className={`${screen ? 'block' : 'hidden print:block'} mt-6 border-t border-slate-200 pt-3 text-center text-[11px] text-slate-500`}
    >
      Generated on: {when}
    </div>
  );
}
