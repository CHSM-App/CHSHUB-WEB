import { BrandWordmark, ChsHubMark, Glyph } from '@/components/AuthLayout.jsx';
/*
 * The JPEG rather than the source Building_image.png beside it: this is a
 * photograph, so PNG buys it nothing — no transparency, no flat colour to
 * compress — and costs 2.1MB against 236KB on the one screen every user meets
 * before they have any reason to wait.
 */
import buildingPhoto from '@/assets/society-building.jpg';

/*
 * The signed-out shell — a framed page split into a showcase half and a form
 * half.
 *
 * Left: a photograph of a society at dusk, bled to the panel's edges and washed
 * out towards the left so the headline and the capability cards have something
 * to sit on. A red strip carrying three proof points closes the panel off along
 * the bottom.
 *
 * Right: the form in its own lifted white card on a pale field, with a red
 * quarter-round in the top-right corner of the page behind it — the only two
 * pieces of brand colour on that side, so the eye lands on the card first.
 *
 * All three signed-out screens render through here — sign in, create account
 * and reset password — so they are one page with a different form in the right
 * column rather than three designs behind the same app. `wide` gives the
 * registration form the extra column width its seven boxes need.
 *
 * AuthSplitLayout remains for the setup wizards, which run inside a signed-in
 * session and are not part of this set.
 *
 * Every red here reads --login-accent / --login-accent-deep, scoped to
 * .auth-showcase-page in index.css, so this screen's deeper reds stay off the
 * app's --accent everywhere else.
 */

/*
 * The capability cards. These are the sidebar's own top-level groups, so the
 * panel previews the menu rather than pitching some other product. Each carries
 * a line of explanation under its title — a bare label says what a section is
 * called but not what it does.
 */
const CAPABILITIES = [
  {
    title: 'Resident Management',
    body: 'Manage residents, owners and tenant details',
    icon: <path d="M9 11a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7ZM2 20a7 7 0 0 1 14 0M17.5 11.5a3 3 0 1 0 0-6M18 20a6.5 6.5 0 0 0-2-4.7" />,
  },
  {
    title: 'Maintenance & Billing',
    body: 'Generate bills, collect payments and manage dues',
    icon: <path d="M6 3h9l4 4v14a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1ZM14 3v5h5M9 13h6M9 17h4" />,
  },
  {
    title: 'Notices & Alerts',
    body: 'Send important notices and real-time alerts',
    icon: <path d="M18 8a6 6 0 0 0-12 0c0 6-2 7-2 7h16s-2-1-2-7M13.7 20a2 2 0 0 1-3.4 0" />,
  },
  {
    title: 'Reports & Analytics',
    body: 'View insightful reports and society analytics',
    icon: <path d="M4 20h16M7.5 20V11M12 20V5M16.5 20v-6" />,
  },
];

/*
 * The proof strip along the foot of the panel — three points read in a glance
 * while the eye is already on its way to the form.
 */
const TRUST_POINTS = [
  {
    title: 'Instant Receipts',
    body: 'Record a payment and print the receipt on the spot',
    icon: <path d="M6 3h12a1 1 0 0 1 1 1v17l-3-2-3 2-3-2-3 2V4a1 1 0 0 1 1-1ZM9 8h6M9 12h6" />,
  },
  {
    title: 'Dues on Track',
    body: 'Defaulters and post-dated cheques never slip through',
    icon: <path d="M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18ZM12 8v5M12 16h.01" />,
  },
  {
    title: 'Start in Minutes',
    body: 'Import your existing flats and owners from Excel',
    icon: <path d="M12 3v12M8 11l4 4 4-4M4 19h16" />,
  },
];

/**
 * Two-column page: the showcase panel and the form card.
 *
 * Below `lg` the showcase collapses to a compact branded header above the form
 * — a phone gets the mark and the headline without scrolling past a hero.
 */
export default function AuthShowcaseLayout({
  heading,
  tagline,
  title,
  subtitle,
  footer,
  children,
  // The registration form carries seven boxes to sign-in's two. Without this
  // it would either run far down the page in a 370px column or need its own
  // layout — which is the split this page set out to remove.
  wide = false,
}) {
  return (
    /* Two nested elements, not one: the outer is the field the page sits on
       (its padding is the margin around the artwork) and .auth-showcase-frame
       inside it is the rounded, clipped stage everything is drawn on. */
    <div className="auth-showcase-page relative min-h-screen">
      <div className="auth-showcase-frame">
        {/* --------------------------------------------------------------- */}
        {/* Showcase half                                                    */}
        {/* --------------------------------------------------------------- */}
        <section className="auth-showcase-half">
          {/* The photograph, as its own layer rather than the section's
              background: the wash that fades it out under the text is a second
              layer over this one, and one element cannot carry both. */}
          <div
            className="auth-showcase-photo"
            style={{ backgroundImage: `url(${buildingPhoto})` }}
            aria-hidden="true"
          />
          {/* The wash. White at the left running to clear at the right, so the
              headline sits on near-white and the building stays untouched on
              the side where nothing is written over it. */}
          <div className="auth-showcase-wash" aria-hidden="true" />

          <div className="auth-showcase-copy">
            <BrandWordmark />

            <h2 className="auth-showcase-heading">
              {heading}
              <span className="auth-showcase-heading__line">{tagline}</span>
            </h2>

            {/* The short rule under the headline — the reference's, and what
                separates the claim from the explanation without a gap wide
                enough to break the block in two. */}
            <span className="auth-showcase-rule" aria-hidden="true" />

            <p className="auth-showcase-lede">
              A complete solution to manage your society efficiently and
              transparently.
            </p>

            <ul className="auth-showcase-features">
              {CAPABILITIES.map((item) => (
                <li key={item.title} className="auth-showcase-feature">
                  <span className="auth-showcase-feature__icon" aria-hidden="true">
                    <Glyph size={19}>{item.icon}</Glyph>
                  </span>
                  <span className="auth-showcase-feature__text">
                    <span className="auth-showcase-feature__title">{item.title}</span>
                    <span className="auth-showcase-feature__body">{item.body}</span>
                  </span>
                </li>
              ))}
            </ul>
          </div>

          {/* The red strip across the foot of the panel. */}
          <ul className="auth-showcase-trust">
            {TRUST_POINTS.map((point) => (
              <li key={point.title}>
                <span className="auth-showcase-trust__icon" aria-hidden="true">
                  <Glyph size={18}>{point.icon}</Glyph>
                </span>
                <span className="auth-showcase-trust__text">
                  <span className="auth-showcase-trust__title">{point.title}</span>
                  <span className="auth-showcase-trust__body">{point.body}</span>
                </span>
              </li>
            ))}
          </ul>
        </section>

        {/* --------------------------------------------------------------- */}
        {/* Form half                                                        */}
        {/* --------------------------------------------------------------- */}
        {/* `justify-center` on a column axis rather than `items-center`: a form
            taller than the viewport centred the other way overflows in BOTH
            directions and its first field scrolls out of reach above the top. */}
        <section className="auth-showcase-form">
          {/* The dotted field at the bottom-left of this column — the only
              piece of furniture on the form side, and the reference's. */}
          <span className="auth-showcase-dots" aria-hidden="true" />

          <div className={`auth-showcase-card${wide ? ' auth-showcase-card--wide' : ''}`}>
            <div className="auth-showcase-card__head">
              {/* The mark in its own tinted disc, as in the reference — the
                  logo reads as a badge above the form rather than as a tile
                  stuck to its top edge.

                  The CHS HUB tile rather than BuildingMark: this is the badge
                  directly above the sign-in box, so it should be the mark the
                  app itself wears in the topbar. The building glyph stays on
                  the showcase panel beside it. */}
              <span className="auth-showcase-card__badge">
                <ChsHubMark />
              </span>
              <h1 className="auth-showcase-title">{title}</h1>
              {subtitle ? <p className="auth-showcase-subtitle">{subtitle}</p> : null}
            </div>

            {children}

            {footer ? <p className="auth-showcase-footer">{footer}</p> : null}
          </div>

          <div className="auth-showcase-legal">
            <p className="auth-showcase-legal__copy">
              © {new Date().getFullYear()} Society Management System. All rights reserved.
            </p>
          </div>
        </section>
      </div>
    </div>
  );
}
