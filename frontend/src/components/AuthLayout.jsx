import { Link } from 'react-router-dom';

/*
 * Shared chrome for the signed-out screens — sign in, create account, reset
 * password. All of them render through AuthSplitLayout, so the three are the
 * same page with a different form in the right-hand column rather than three
 * designs that happen to sit behind the same app.
 *
 * Every colour is the app shell's own token — --ink, --accent-strong,
 * --grad-accent, --shell-shadow-lifted, the #c94040 → #e85555 CHS mark — so a
 * theme change in index.css carries here too.
 */

/*
 * The three groups the sidebar itself opens with — Property Master, Finance &
 * billing and Reports & Analytics (AppLayout's NAV) — named and described the
 * same way here, so the panel previews the menu rather than pitching some other
 * product.
 */
const HIGHLIGHTS = [
  {
    title: 'Property Master',
    body: 'Buildings, wings, flats, parking and amenities in one register.',
    icon: <path d="M4 20V7l7-4 7 4v13M9 20v-5h6v5M8 10h.01M12 10h.01M16 10h.01" />,
  },
  {
    title: 'Finance & billing',
    body: 'Maintenance bills, receipts, PDC reminders, ledger and cashbook.',
    icon: (
      <path d="M4 4h12a2 2 0 0 1 2 2v13l-3-2-3 2-3-2-3 2V6a2 2 0 0 1 2-2Zm2 5h8M6 13h5" />
    ),
  },
  {
    title: 'Reports & Analytics',
    body: 'Balance sheet, income & expenditure and audit answers on demand.',
    icon: <path d="M4 19h16M7 16V9m5 7V5m5 11v-4" />,
  },
];

/** A stroke-only glyph, sized to the 20px slot the panel and footer use. */
export function Glyph({ children, size = 20, className = '' }) {
  return (
    <svg
      className={className}
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.75"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      {children}
    </svg>
  );
}

/**
 * The CHS HUB mark, at Site.Master's gradient, radius and layered shadow — the
 * same object the topbar carries once you are signed in.
 */
export function BrandMark({ size = 48 }) {
  return (
    <span
      className="flex shrink-0 items-center justify-center"
      style={{
        width: size,
        height: size,
        background: 'linear-gradient(135deg, #c94040 0%, #e85555 100%)',
        borderRadius: '12px',
        boxShadow:
          '0 2px 8px rgba(201,64,64,0.3), 0 8px 20px -8px rgba(201,64,64,0.5), inset 0 1px 0 rgba(255,255,255,0.28)',
      }}
      aria-hidden="true"
    >
      <span
        className="block text-center text-white"
        style={{
          fontSize: size <= 40 ? '10px' : '11px',
          fontWeight: 800,
          lineHeight: 1.1,
          letterSpacing: '0.5px',
          fontFamily: 'Arial, sans-serif',
        }}
      >
        CHS
        <br />
        HUB
      </span>
    </span>
  );
}

/**
 * The single primary action on a signed-out page. --grad-accent is the
 * dashboard's own accent wash, so this button is filled with the same blue the
 * tiles are; only the height and radius are raised off .btn's compact
 * table-toolbar geometry, because this is the one action on the page.
 */
export function AuthSubmit({ busy, busyLabel, disabled = false, children }) {
  return (
    <button
      type="submit"
      className="btn-primary w-full"
      style={{
        background: 'var(--grad-accent)',
        borderColor: 'var(--accent-strong)',
        borderRadius: '8px',
        padding: '11px 16px',
        fontSize: '0.9375rem',
        fontWeight: 600,
        boxShadow: '0 4px 12px -2px rgba(78,115,223,0.4)',
      }}
      disabled={busy || disabled}
    >
      {busy ? (
        <>
          {/* Spinner rather than only a label swap: on a slow link the text
              alone leaves the button looking merely disabled. */}
          <svg className="h-4 w-4 animate-spin" viewBox="0 0 24 24" fill="none" aria-hidden="true">
            <circle cx="12" cy="12" r="9" stroke="currentColor" strokeWidth="2.5" opacity="0.3" />
            <path
              d="M21 12a9 9 0 0 0-9-9"
              stroke="currentColor"
              strokeWidth="2.5"
              strokeLinecap="round"
            />
          </svg>
          {busyLabel}
        </>
      ) : (
        children
      )}
    </button>
  );
}

/**
 * Two-column shell: a branded panel carrying the product story, and the form.
 *
 * Below `lg` the panel collapses to a compact header strip above the form, so a
 * phone gets the mark and the form without scrolling past a hero.
 *
 * `wide` widens the form column for the registration form, which has twice as
 * many fields as the sign-in one.
 */
export function AuthSplitLayout({ title, subtitle, footer, children, wide = false }) {
  return (
    <div className="grid min-h-screen lg:grid-cols-[1.05fr_1fr]">
      {/* --------------------------------------------------------------- */}
      {/* Brand panel                                                      */}
      {/* --------------------------------------------------------------- */}
      <section
        className="relative flex flex-col justify-between overflow-hidden px-6 py-8 text-white sm:px-10 lg:px-14 lg:py-12"
        style={{
          background:
            'linear-gradient(150deg, #041e4d 0%, #012970 40%, #10367f 72%, #1d4ed8 100%)',
        }}
      >
        {/*
          Two soft radial blooms plus a hairline grid, in one absolutely
          positioned layer behind the content — the flat gradient above picks up
          some depth without any image being fetched.
        */}
        <div
          className="pointer-events-none absolute inset-0"
          aria-hidden="true"
          style={{
            backgroundImage:
              'radial-gradient(680px circle at 8% 6%, rgba(93,143,239,0.38), transparent 58%),' +
              'radial-gradient(520px circle at 92% 88%, rgba(201,64,64,0.28), transparent 60%),' +
              'linear-gradient(rgba(255,255,255,0.05) 1px, transparent 1px),' +
              'linear-gradient(90deg, rgba(255,255,255,0.05) 1px, transparent 1px)',
            backgroundSize: 'auto, auto, 56px 56px, 56px 56px',
          }}
        />

        <div className="relative flex items-center gap-3">
          <BrandMark />
          <div>
            <p className="text-base font-bold leading-tight">CHS HUB</p>
            <p className="text-xs" style={{ color: 'rgba(255,255,255,0.65)' }}>
              Society Management Suite
            </p>
          </div>
        </div>

        {/* The pitch is what a phone does not need — it would push the form
            below the fold — so it is hidden there and the panel collapses to
            the mark plus the footer line. */}
        <div className="relative mt-10 hidden max-w-md lg:block">
          <h2 className="text-4xl font-bold leading-[1.15] tracking-tight">
            Run your society,
            <br />
            not your spreadsheets.
          </h2>
          <p className="mt-4 text-[15px] leading-relaxed" style={{ color: 'rgba(255,255,255,0.72)' }}>
            Billing, members, facilities and accounts for your co-operative housing
            society — in one place, for the whole committee.
          </p>

          <ul className="mt-9 space-y-5">
            {HIGHLIGHTS.map((item) => (
              <li key={item.title} className="flex gap-4">
                <span
                  className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl"
                  style={{
                    background: 'rgba(255,255,255,0.12)',
                    border: '1px solid rgba(255,255,255,0.18)',
                  }}
                >
                  <Glyph>{item.icon}</Glyph>
                </span>
                <div>
                  <p className="text-sm font-semibold">{item.title}</p>
                  <p className="text-[13px]" style={{ color: 'rgba(255,255,255,0.62)' }}>
                    {item.body}
                  </p>
                </div>
              </li>
            ))}
          </ul>
        </div>

        <p className="relative mt-8 text-xs lg:mt-0" style={{ color: 'rgba(255,255,255,0.5)' }}>
          Copyright © chsHub.co.in
        </p>
      </section>

      {/* --------------------------------------------------------------- */}
      {/* Form column                                                      */}
      {/* --------------------------------------------------------------- */}
      <section
        className="flex items-center justify-center px-4 py-10 sm:px-8"
        style={{
          backgroundColor: 'var(--page-tint-b)',
          backgroundImage:
            'linear-gradient(180deg, var(--page-tint-a) 0%, var(--page-tint-b) 420px)',
        }}
      >
        <div className={`w-full ${wide ? 'max-w-[520px]' : 'max-w-[400px]'}`}>
          {/* PageHeader's shape — bold title in --ink over a slate-500 subtitle
              — so the first thing read here is typeset the same way as the
              first thing on every screen after signing in. */}
          <header className="mb-4">
            <h1 className="text-xl font-bold tracking-tight" style={{ color: 'var(--ink)' }}>
              {title}
            </h1>
            {subtitle ? <p className="mt-0.5 text-sm text-slate-500">{subtitle}</p> : null}
          </header>

          {/*
            .card's white surface, hairline and 12px radius, lifted onto the
            shell's stronger elevation — this is the one card on the page, so it
            floats rather than rests. The gradient top rule is StatCard's, inset
            inside the border and clipped by overflow-hidden the same way.
          */}
          <div
            className="card relative overflow-hidden"
            style={{ boxShadow: 'var(--shell-shadow-lifted)' }}
          >
            <span
              className="absolute inset-x-0 top-0 h-1"
              style={{ background: 'linear-gradient(90deg, #6f8ff5, #4e73df)' }}
              aria-hidden="true"
            />
            <div className="p-6 pt-[calc(1.5rem+2px)] sm:p-7 sm:pt-[calc(1.75rem+2px)]">
              {children}
            </div>
          </div>

          {footer ? (
            <p className="mt-6 text-center text-sm" style={{ color: 'var(--ink-muted)' }}>
              {footer}
            </p>
          ) : null}

          <p
            className="mt-6 flex items-center justify-center gap-1.5 text-xs"
            style={{ color: '#8b94a5' }}
          >
            <Glyph size={14}>
              <path d="M12 3 5 6v5c0 4.4 2.9 8.4 7 9.5 4.1-1.1 7-5.1 7-9.5V6l-7-3Z" />
            </Glyph>
            Your session is encrypted and private.
          </p>
        </div>
      </section>
    </div>
  );
}

/** Link styled as the accent, used in the layout's footer slot. */
export function AuthLink({ to, children }) {
  return (
    <Link to={to} className="font-semibold hover:underline" style={{ color: 'var(--accent-strong)' }}>
      {children}
    </Link>
  );
}
