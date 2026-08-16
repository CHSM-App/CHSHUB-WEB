import { useEffect, useLayoutEffect, useMemo, useRef, useState } from 'react';
import { Link, NavLink, Outlet, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '@/auth/AuthContext.jsx';
import ProfileDialog from '@/pages/auth/ProfileDialog.jsx';
import HeaderIcons from '@/components/HeaderIcons.jsx';
import { ConfirmDialog } from '@/components/ui.jsx';

/*
 * Navigation reproduces Site.Master's accordion exactly — the same two
 * headings (Interface / ADDONS), the same groups in the same order, the same
 * labels and the same Font Awesome icons. Menu items map to the React route
 * that replaced each .aspx page.
 *
 * Entries the legacy markup had commented out are left out here too, so the
 * menu matches what users actually see today. Screens that exist but were not
 * on the legacy menu are reachable by URL and from their parent screens.
 */
const NAV = [
  {
    section: 'Interface',
    groups: [
      {
        label: 'Property Master',
        icon: 'building',
        heading: 'Properties:',
        items: [
          { to: '/settings/society', label: 'Society Master' },
          { to: '/masters/buildings', label: 'Buildings' },
          { to: '/masters/wings', label: 'Wing Master' },
          { to: '/masters/flats', label: 'Flat Master' },
          { to: '/masters/tenants', label: 'Rental Master' },
          { to: '/settings/charges', label: 'Maintenance Charges Master' },
          { to: '/community/facilities', label: 'amenity Master' },
          { to: '/masters/parking-places', label: 'Parking Place Master' },
        ],
      },
      {
        label: 'People & Staff Master',
        icon: 'users',
        heading: 'Masters:',
        items: [
          { to: '/masters/members', label: 'Committee Member Master' },
          { to: '/masters/owners', label: 'Owner Master' },
          { to: '/community/visitors', label: 'Visitor Master' },
          { to: '/masters/staff', label: 'Staff Master' },
        ],
      },
      {
        label: 'Service & facility',
        icon: 'tools',
        heading: 'Services:',
        items: [
          { to: '/masters/parking-allotment', label: 'Parking Allotment' },
          { to: '/community/facility-bookings', label: 'Facility Booking' },
          { to: '/masters/contacts', label: 'Assistant|Technician|Supplier' },
          { to: '/masters/car-pooling', label: 'Car Polling' },
          { to: '/community/events', label: 'Event Master' },
          { to: '/community/notices', label: 'Notice Master' },
        ],
      },
      {
        label: 'Society Management',
        icon: 'city',
        heading: 'Management:',
        items: [
          { to: '/community/documents', label: 'Upload Documents' },
          { to: '/accounts/shop-maintenance', label: 'Shop Maintenance' },
          { to: '/community/meetings', label: 'Meeting Master' },
          { to: '/masters/inventory', label: 'Inventory' },
        ],
      },
      {
        label: 'vendor management',
        icon: 'bag',
        heading: 'Management:',
        items: [
          { to: '/accounts/vendors', label: 'Add Vendor' },
          { to: '/accounts/vendor-bills', label: 'Vendor Bill/Approvals' },
        ],
      },
    ],
  },
  {
    section: 'ADDONS',
    groups: [
      {
        label: 'Finance & billing',
        icon: 'coins',
        items: [
          { to: '/masters/loans', label: 'Loan & Lien' },
          { to: '/billing/pdc', label: 'PDC Reminder' },
          { to: '/billing/pdc/clearing', label: 'PDC Clearing' },
          { to: '/accounts/ledger', label: 'Ledger' },
          { to: '/accounts/cashbook', label: 'Cashbook' },
        ],
      },
      {
        label: 'Credit & Debit',
        icon: 'money',
        items: [
          { to: '/billing/bills', label: 'Maintenance' },
          { to: '/billing/receipts', label: 'Maintenance Receipt' },
          { to: '/accounts/other-credits', label: 'Other Credits' },
          { to: '/reports/audit', label: 'Audit Q&A' },
        ],
      },
      {
        label: 'Reports & Analytics',
        icon: 'chart',
        items: [
          // Was pointing at the data-entry page, which Society Management
          // already links to. printshop.aspx is the report this section meant.
          { to: '/reports/shop-maintenance', label: 'Shop Maintenance' },
          { to: '/reports/owner-ledger', label: 'Ownerwise Maintenance' },
          // v_profite_loss.aspx. This label used to point at /reports/profit-loss,
          // a date-range report the legacy app did not have.
          { to: '/reports/income-expense', label: 'Annual income & expenditure' },
          { to: '/reports/balance-sheet', label: 'Balance Sheet' },
        ],
      },
      {
        label: 'Others',
        icon: 'cogs',
        items: [
          { to: '/community/suggestions', label: 'Suggestion' },
          // Rates and bill-generation settings. Routed all along, but nothing
          // in the menu reached it.
          { to: '/settings/accounts', label: 'Billing Settings' },
          { to: '/settings/terms', label: 'Terms & Conditions' },
        ],
      },
    ],
  },
  {
    section: null, // village panel sat outside the two headings
    villageOnly: true,
    groups: [
      {
        label: 'Village',
        icon: 'file',
        heading: 'Village Management',
        /*
         * Ordered by the work, not by when each screen was built: a house is
         * recorded, its charges are set, the period's bills are raised, and
         * then payment is taken against them. Charges and Generate Bills sat
         * after Tax Payments, which put the last step before the two that
         * produce what it collects.
         *
         * Announcements and Staff Management have nothing to do with billing,
         * so they follow it rather than interrupting it, and Settings sits
         * last as it does elsewhere in the app.
         */
        items: [
          // Dashboard is not repeated here: the rail already carries it above
          // the first heading, for both kinds of account.
          { to: '/village/residents', label: 'Village Residents' },
          { to: '/village/house-charges', label: 'Charges' },
          { to: '/village/bill-run', label: 'Generate Bills' },
          { to: '/village/payments', label: 'Tax Payments' },
          { to: '/village/reports', label: 'Reports' },
          { to: '/village/history', label: 'History' },
          { to: '/community/notices', label: 'Announcements' },
          { to: '/village/schemes', label: 'Government Schemes' },
          { to: '/village/staff', label: 'Staff Management' },
          { to: '/village/settings', label: 'Settings' },
        ],
      },
    ],
  },
];

/**
 * Inline SVGs standing in for the legacy Font Awesome glyphs. Drawn here rather
 * than pulled from a CDN — the app must not depend on an external host.
 */
/*
 * Sidebar glyphs, one per Font Awesome icon Site.Master used. Drawn as inline
 * SVG rather than pulling in Font Awesome: the legacy pages loaded the whole
 * kit for nine icons, and these inherit the surrounding text colour.
 *
 *   home     fa-home            Dashboard        (Site.Master:956)
 *   building fa-building        Property Master        :968
 *   users    fa-users           People & Staff Master  :988
 *   tools    fa-tools           Service & facility     :1007
 *   city     fa-city            Society Management     :1027
 *   bag      fa-shopping-bag    Vendor management      :1049
 *   coins    fa-coins           Finance & billing      :1069
 *   money    fa-money-bill-alt  Credit & Debit         :1087
 *   chart    fa-chart-line      Reports & Analytics    :1111
 *   cogs     fa-cogs            Others                 :1129
 *   file     fa-file-alt        Village                :1161
 *
 * Not mapped: fa-tachometer-alt (:1145) sat on an "Admin Dashboard" item that
 * has no route in this app yet.
 */
const ICONS = {
  home: 'M3 10.5 12 3l9 7.5M5.5 9.5V20h13V9.5',
  building: 'M4 21V4h10v17M14 21V9h6v12M7 8h2M7 12h2M7 16h2M17 12h1M17 16h1',
  users: 'M8 11a3 3 0 1 0 0-6 3 3 0 0 0 0 6ZM2 20a6 6 0 0 1 12 0M17 11a3 3 0 1 0 0-6M16 20h6a5 5 0 0 0-4-4.9',
  tools: 'm14.5 5.5 4 4M3 21l6.5-6.5M17 3l4 4-3 3-4-4 3-3ZM9.5 14.5 3 21',
  city: 'M3 21V8l6-3v16M9 21V11l6-3v13M15 21v-9l6-2v11M6 12h1M6 16h1M12 14h1M12 18h1M18 15h1',
  bag: 'M6 7h12l1 13H5L6 7ZM9 7V5a3 3 0 0 1 6 0v2',
  coins: 'M12 8c4.4 0 8-1.1 8-2.5S16.4 3 12 3 4 4.1 4 5.5 7.6 8 12 8ZM4 5.5v13C4 19.9 7.6 21 12 21s8-1.1 8-2.5v-13M4 12c0 1.4 3.6 2.5 8 2.5s8-1.1 8-2.5',
  money: 'M2 6h20v12H2zM12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6ZM6 9v.01M18 15v.01',
  chart: 'M3 3v18h18M7 15l4-5 3 3 5-7',
  cogs: 'M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6Zm8-3a8 8 0 0 0-.2-1.7l2-1.5-2-3.4-2.3 1a8 8 0 0 0-3-1.7L14 2h-4l-.5 2.7a8 8 0 0 0-3 1.7l-2.3-1-2 3.4 2 1.5a8 8 0 0 0 0 3.4l-2 1.5 2 3.4 2.3-1a8 8 0 0 0 3 1.7L10 22h4l.5-2.7a8 8 0 0 0 3-1.7l2.3 1 2-3.4-2-1.5c.13-.55.2-1.12.2-1.7Z',
  file: 'M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8l-5-5ZM14 3v5h5M9 13h6M9 17h6',
  // The three in the header dropdown — fa-user, fa-cogs and fa-sign-out-alt
  // on the legacy Site.Master.
  user: 'M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8ZM4 21a8 8 0 0 1 16 0',
  logout: 'M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9',
};

function Icon({ name }) {
  const d = ICONS[name] ?? ICONS.file;
  return (
    <svg
      viewBox="0 0 24 24"
      width="16"
      height="16"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.8"
      strokeLinecap="round"
      strokeLinejoin="round"
      className="shrink-0"
      aria-hidden="true"
    >
      <path d={d} />
    </svg>
  );
}

// .sidebar-item / .collapse-inner a are defined in index.css, lifted from the
// legacy site_master_style.css so the nav matches the WebForms app.
const linkClass = ({ isActive }) => `sidebar-item${isActive ? ' active' : ''}`;
/*
 * Menu links carry `end`, so a link is active only on its own page.
 *
 * NavLink matches by path prefix by default, which lights up a parent route
 * whenever a child is open. The menu has one such pair — PDC Reminder
 * (/billing/pdc) sits above PDC Clearing (/billing/pdc/clearing) — and opening
 * Clearing marked both rows current, each with the rail dot .collapse-inner
 * a.active draws. Nothing in this menu is a section landing page that should
 * stay lit while a child is open, so exact matching is right for all of it.
 */
const subLinkClass = ({ isActive }) => (isActive ? 'active' : undefined);

export default function AppLayout() {
  const { user, logout, villageId } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  // Mobile drawer. The legacy topbar had the same toggle (#sidebarToggleTop).
  const [navOpen, setNavOpen] = useState(false);
  // Accordion: data-parent="#accordionSidebar" meant only one group open.
  const [openGroup, setOpenGroup] = useState(null);
  const [menuOpen, setMenuOpen] = useState(false);
  // The Profile dialog, opened from the header dropdown as Site.Master did.
  const [profileOpen, setProfileOpen] = useState(false);
  // The log-out confirmation. `signingOut` keeps the dialog's buttons disabled
  // while the token is being revoked, so a second click cannot fire it twice.
  const [logoutOpen, setLogoutOpen] = useState(false);
  const [signingOut, setSigningOut] = useState(false);

  /*
   * The two menus are mutually exclusive, as they were in the legacy shell:
   *
   *   society.Visible = Session["user_type"] == "Society";
   *   village.Visible = Session["user_type"] == "Village";      (Site.Master.cs:40)
   *
   * A village account has no buildings, wings, flats or maintenance billing, so
   * showing it the society menu offers a screenful of links that lead to empty
   * or society-scoped pages — several of which the API refuses outright,
   * because their routes sit behind requireSociety.
   */
  const isVillage = Boolean(villageId);
  const sections = NAV.filter((g) => Boolean(g.villageOnly) === isVillage);

  // Open whichever group owns the current route, so a deep link or a reload
  // lands with the right menu expanded rather than everything collapsed.
  const activeGroup = useMemo(() => {
    for (const section of sections) {
      for (const group of section.groups) {
        if (group.items.some((i) => i.to === location.pathname)) return group.label;
      }
    }
    return null;
  }, [location.pathname, sections]);

  const expanded = openGroup ?? activeGroup;

  // The sidebar scrolls on its own, so clicking a menu item must not throw the
  // user back to the top of the menu: navigating re-renders the nav and the
  // accordion changes its content height, both of which reset scrollTop.
  // Record the position as the user scrolls, then put it back before paint.
  const navRef = useRef(null);
  const navScroll = useRef(0);

  /*
   * Publish the topbar's REAL height as --topbar-h.
   *
   * The sidebar sticks under the topbar and sizes itself against it. Both used
   * hardcoded pixels (top: 84px, height: calc(100vh - 100px)), which are only
   * correct at one zoom level and one font size: the bar's actual height moves
   * with browser zoom, with a longer society name wrapping the pill, and with
   * the OS text-size setting. When it did, the rail either floated away from
   * the bar or was pinned shorter than its own menu and grew a second scrollbar
   * inside the page's — the "sidebar scrolls on its own" case.
   *
   * A ResizeObserver keeps the variable in step with whatever the bar actually
   * measures, so the two can never drift again.
   */
  const topbarRef = useRef(null);

  useLayoutEffect(() => {
    const el = topbarRef.current;
    if (!el) return undefined;
    const apply = () => {
      document.documentElement.style.setProperty(
        '--topbar-h',
        `${Math.round(el.getBoundingClientRect().height)}px`,
      );
    };
    apply();
    if (typeof ResizeObserver === 'undefined') return undefined;
    const ro = new ResizeObserver(apply);
    ro.observe(el);
    return () => ro.disconnect();
  }, []);

  useLayoutEffect(() => {
    const el = navRef.current;
    if (el) el.scrollTop = navScroll.current;
  });

  // Keep the item you just clicked in view. If the route's group was collapsed,
  // expanding it can push the active link below the fold.
  useEffect(() => {
    const el = navRef.current;
    if (!el) return;
    const active = el.querySelector('.sidebar-item.active, .collapse-inner a.active');
    if (!active) return;
    const top = active.offsetTop;
    const bottom = top + active.offsetHeight;
    if (top < el.scrollTop || bottom > el.scrollTop + el.clientHeight) {
      active.scrollIntoView({ block: 'nearest' });
    }
  }, [location.pathname, expanded]);

  // Site.Master guarded this with a confirm; keep the guard so a stray click on
  // the menu does not end the session — but as the app's own dialog rather than
  // window.confirm, whose browser-chrome styling ignores the theme and reads as
  // a page from a different site.
  const handleLogout = () => {
    setMenuOpen(false);
    setLogoutOpen(true);
  };

  const confirmLogout = async () => {
    setSigningOut(true);
    try {
      await logout();
      navigate('/login', { replace: true });
    } finally {
      // The route change unmounts this shell, so in the success path nothing
      // reads these again; they matter when logout throws and the dialog has
      // to become usable once more.
      setSigningOut(false);
      setLogoutOpen(false);
    }
  };

  /*
   * No `overflow-x` on the shell below.
   *
   * An element that clips overflow becomes the scroll container for its
   * descendants, and a sticky box positions against its nearest scrolling
   * ancestor. Clipping here made this div that ancestor for both the topbar
   * and the sidebar rail — and because it is only as tall as its content,
   * neither had anything to stick to and both scrolled away with the page.
   *
   * The page-level clip lives on <html> in index.css, where the viewport stays
   * the scroller and sticky keeps working. `min-w-0` is what actually stops
   * the content forcing the shell wide, and it needs no clipping.
   */
  return (
    <div className="flex min-h-screen w-full min-w-0 flex-col">
      {/*
        Sticky white topbar with the CHS HUB mark on the left and the signed-in
        user on the right — the arrangement Site.Master used.
      */}
      {/* app-topbar marks this as shell rather than page content, so printing
          drops it — a report should start at its own title, not the CHS HUB
          mark and account icons. */}
      {/* Frosted rather than solid white: the page tint shows through faintly as
          content scrolls under it, which is what tells the eye the bar is a
          layer above the page instead of part of it. */}
      <header
        ref={topbarRef}
        className="app-topbar sticky top-0 z-50 flex items-center justify-between gap-2 px-3 py-3 sm:px-6"
        style={{
          background: 'rgba(255,255,255,0.85)',
          backdropFilter: 'saturate(180%) blur(12px)',
          WebkitBackdropFilter: 'saturate(180%) blur(12px)',
          borderBottom: '1px solid var(--shell-line)',
          /* Downward-only: the topbar spans the full width, so it has no left
             or right edge to mould — a symmetric pair would put a light rim
             against the viewport edge and read as a seam. */
          boxShadow: '0 4px 12px rgba(174,179,189,0.28), inset 0 1px 0 rgba(255,255,255,0.9)',
        }}
      >
        {/* min-w-0 lets this cluster shrink; without it the pill's text sets a
            floor that pushed the account controls off a narrow screen. */}
        <div className="flex min-w-0 items-center gap-2 sm:gap-4">
          <button
            type="button"
            className="-ml-1 flex h-11 w-11 shrink-0 items-center justify-center rounded text-lg leading-none lg:hidden"
            aria-label="Toggle navigation"
            aria-expanded={navOpen}
            onClick={() => setNavOpen((v) => !v)}
          >
            ☰
          </button>

          {/* .chs-logo — red gradient, 12px radius (Site.Master:498). Links
              home, which the legacy static div did not, but every other app
              puts the mark to that use. */}
          <Link
            to="/"
            className="chs-logo shrink-0"
            aria-label="CHS HUB — go to dashboard"
            style={{
              background: 'linear-gradient(135deg, #e31b23 0%, #e31b23 100%)',
              borderRadius: '12px',
              // Two shadows plus an inset highlight: the mark reads as a solid
              // object catching light rather than a flat red rectangle.
              boxShadow:
                '0 2px 8px rgba(201,64,64,0.3), 0 8px 20px -8px rgba(201,64,64,0.5), inset 0 1px 0 rgba(255,255,255,0.28)',
            }}
          >
            <span
              className="logo-text block text-center text-white"
              style={{
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
          </Link>

          {/* .society-name-pill — white rounded pill (Site.Master), moulded out
              of the topbar and carrying a building glyph so it reads as "which
              society am I in" rather than as an unlabelled piece of text. */}
          <div
            className="society-name-pill flex min-w-0 items-center gap-2"
            style={{
              background: '#fff',
              borderRadius: '20px',
              boxShadow:
                '-3px -3px 8px rgba(255,255,255,0.9), 3px 3px 9px rgba(174,179,189,0.32)',
              border: '1px solid rgba(17,24,39,0.04)',
            }}
          >
            <span className="shrink-0" style={{ color: '#b91c1c' }} aria-hidden="true">
              <Icon name="building" />
            </span>
            <p className="society-name-text truncate font-semibold" style={{ color: '#1f2937' }}>
              {user?.society_name || user?.village_name || 'Society Management'}
            </p>
          </div>
        </div>

        <div className="flex shrink-0 items-center gap-1 sm:gap-2">
          {/* Polls, alerts bell and messages — the icon row Site.Master placed
              immediately left of the profile menu. */}
          <HeaderIcons />

          {/* Profile dropdown — Profile / Settings / Log Out, as Site.Master had. */}
          <div className="relative">
          <button
            type="button"
            className="flex items-center gap-2 rounded-full py-1 pl-1 pr-4 transition-shadow"
            style={{
              border: '1px solid rgba(17,24,39,0.04)',
              background: '#fff',
              boxShadow:
                '-3px -3px 8px rgba(255,255,255,0.9), 3px 3px 9px rgba(174,179,189,0.32)',
            }}
            aria-expanded={menuOpen}
            aria-haspopup="menu"
            onClick={() => setMenuOpen((v) => !v)}
          >
            <span
              className="flex h-8 w-8 items-center justify-center rounded-full text-xs font-bold text-white"
              style={{
                background: 'linear-gradient(135deg, #b91c1c, #e31b23)',
                boxShadow: '0 2px 6px rgba(168, 42, 42,0.4), inset 0 1px 0 rgba(255,255,255,0.25)',
              }}
              aria-hidden="true"
            >
              {(user?.name || '?').trim().charAt(0).toUpperCase()}
            </span>
            <span className="hidden text-sm font-medium sm:inline" style={{ color: '#1f2937' }}>
              Hello, {user?.name}
            </span>
          </button>

          {menuOpen ? (
            <>
              {/* Click-away layer, so the menu closes like the Bootstrap one. */}
              <div className="fixed inset-0 z-40" onClick={() => setMenuOpen(false)} aria-hidden="true" />
              <div
                role="menu"
                className="absolute right-0 z-50 mt-2 overflow-hidden bg-white py-1"
                style={{
                  // Clamped the way HeaderIcons clamps its panels, so a
                  // right-anchored menu cannot spill past a narrow viewport.
                  width: 'min(200px, calc(100vw - 2rem))',
                  borderRadius: 14,
                  border: '1px solid rgba(17,24,39,0.06)',
                  // Matched to the alerts dropdown in HeaderIcons, so the two
                  // panels hanging off the same row read as one component.
                  boxShadow: '0 12px 32px rgba(120,126,138,0.22)',
                }}
              >
                {/* Each item carries the icon its Site.Master counterpart had:
                    fa-user, fa-cogs and fa-sign-out-alt, muted to match. */}
                <button
                  type="button"
                  role="menuitem"
                  className="flex w-full items-center gap-2.5 px-4 py-2 text-left text-sm hover:bg-slate-50"
                  style={{ color: '#1f2937' }}
                  onClick={() => {
                    setMenuOpen(false);
                    setProfileOpen(true);
                  }}
                >
                  <span className="text-slate-400">
                    <Icon name="user" />
                  </span>
                  Profile
                </button>
                {/*
                  Settings means a different page for each kind of account.
                  /settings/accounts is the society's billing settings, and a
                  village has no rows behind it — the API refuses it — so this
                  sent a village account to a page that could only error.
                */}
                <Link
                  to={isVillage ? '/village/settings' : '/settings/accounts'}
                  role="menuitem"
                  className="flex items-center gap-2.5 px-4 py-2 text-sm hover:bg-slate-50"
                  style={{ color: '#1f2937' }}
                  onClick={() => setMenuOpen(false)}
                >
                  <span className="text-slate-400">
                    <Icon name="cogs" />
                  </span>
                  Settings
                </Link>
                <div className="my-1 border-t" style={{ borderColor: '#e5e7eb' }} />
                <button
                  type="button"
                  role="menuitem"
                  className="flex w-full items-center gap-2.5 px-4 py-2 text-left text-sm hover:bg-slate-50"
                  style={{ color: '#1f2937' }}
                  onClick={handleLogout}
                >
                  <span className="text-slate-400">
                    <Icon name="logout" />
                  </span>
                  Log Out
                </button>
              </div>
            </>
          ) : null}
          </div>
        </div>
      </header>

      {/*
        min-w-0 on the row and w-full on the shell.

        A flex item's minimum width defaults to its content, so the widest
        thing on the page — the dashboard chart — set a floor for this row,
        the row set one for the shell, and the shell grew past the viewport.
        The page clips horizontal overflow, so that surplus did not show up as
        a scrollbar: it showed up as content that started at the left edge and
        ran off the right, leaving a white gutter the topbar did not have.
      */}
      <div className="w-full min-w-0 flex-1 lg:flex lg:items-start lg:gap-2">
        {/*
          Legacy sidebar: a white rounded card floating on the page background,
          not a full-height rail — ul#accordionSidebar in site_master_style.css.
        */}
        {/*
          `sticky` has to sit on the <aside>, not on the <nav> inside it: a
          sticky box can never travel outside its parent's box, and the <aside>
          is only as tall as its own content, so a sticky <nav> would scroll
          away with it. The <aside> is a child of the page, which is what
          scrolls, so pinning it here is what actually holds the rail in place.
        */}
        {/*
          Backdrop for the mobile drawer. The rail is in normal flow on a
          phone, so an open menu pushed the page down and the only way back
          was to find the ☰ again — every other drawer on a phone closes when
          you tap beside it. Desktop never sees this: the rail is permanent
          there, so the layer is hidden from `lg` up.
        */}
        {navOpen ? (
          <div
            className="fixed inset-0 z-30 bg-slate-900/40 lg:hidden"
            onClick={() => setNavOpen(false)}
            aria-hidden="true"
          />
        ) : null}

        {/*
          On a phone the rail is an overlay pinned under the topbar, not a
          block in the flow. In the flow it pushed the page content down by
          its full height, so opening the menu on a short screen scrolled the
          page away from whatever the user was looking at.
        */}
        <aside
          className={`${
            navOpen
              ? 'fixed inset-y-0 left-0 top-[var(--topbar-h)] z-40 w-[min(82vw,300px)] overflow-y-auto overscroll-contain'
              : 'hidden'
          } app-sidebar-rail lg:fixed lg:bottom-0 lg:left-0 lg:top-[var(--topbar-h)] lg:z-30 lg:flex lg:w-[276px] lg:flex-col lg:overflow-visible`}
          style={{ padding: '8px' }}
        >
          {/*
            The rail is a fixed-height card, as `ul#accordionSidebar` was
            (width 260px, height 85vh in site_master_style.css). Sizing it to
            its contents instead leaves a stub of a card under a short menu —
            a village account has one group, and the rail collapsed to about a
            third of the page beside it.

            It scrolls independently of the page, so a long menu gets its own
            scrollbar rather than pushing the page down; overscroll-contain
            stops a scroll that reaches the end of the menu from continuing
            into the page behind it.
          */}
          <nav
            ref={navRef}
            onScroll={(e) => {
              navScroll.current = e.currentTarget.scrollTop;
            }}
            /*
             * `max-h`, not `h`.
             *
             * A fixed `h-[calc(100vh-100px)]` is a height the rail must be,
             * whether or not the menu needs it — so at browser zoom, where the
             * CSS viewport shrinks but the menu does not, the rail was pinned
             * SHORTER than its own contents and grew a second scrollbar inside
             * the page's. That is the "sidebar scrolls on its own" the user hit
             * at 150%: 600px viewport, 500px rail, 533px of menu.
             *
             * A maximum lets it be exactly as tall as the menu when that fits,
             * and only becomes a scroller when the menu genuinely cannot — so
             * the rail can stay stuck under the topbar at every height without
             * ever being forced shorter than its contents.
             *
             * The offsets are computed from --topbar-h rather than the old
             * hardcoded 84/100px, so the rail stays glued under the topbar
             * instead of drifting as the bar's real height changes with zoom.
             */
            /*
             * The subtractions are what the rail must clear to fit in the strip
             * under the sticky topbar: the bar's own height, and the <aside>'s
             * 8px padding top and bottom. Leave any of it out and the rail is
             * taller than the space it is stuck in — at which point sticky has
             * nothing to hold and the menu scrolls off with the page, which is
             * the bug this whole block exists to prevent.
             */
            /*
             * `min-h-0` is the load-bearing part. A flex child's automatic
             * minimum is its content, so without it the nav refuses to be
             * shorter than the whole menu and pushes the <aside> past the
             * bottom of the screen.
             *
             * With it, the fixed <aside> owns the height and the nav shrinks to
             * fit, scrolling internally only when the menu genuinely cannot.
             */
            className="app-sidebar max-lg:min-h-full overscroll-contain rounded-2xl bg-white lg:min-h-0 lg:w-full lg:flex-1 lg:overflow-y-auto"
            style={{
              padding: '14px',
              border: '1px solid var(--shell-line)',
              // Replaces the legacy offset drop shadow, which read as a sticker
              // pasted on the page. A centred ambient shadow lifts the card.
              boxShadow: 'var(--shell-shadow)',
            }}
          >
            {/* Dashboard sits above the first heading, as in Site.Master. */}
            <NavLink to="/dashboard" className={linkClass} onClick={() => setNavOpen(false)}>
              <Icon name="home" />
              <span className="ml-3">Dashboard</span>
            </NavLink>

            {sections.map((section, si) => (
              <div key={section.section ?? `village-${si}`}>
                {/* Fades out at both ends rather than butting into the card
                    padding as a hard grey line. */}
                <hr
                  className="my-3 border-0"
                  style={{
                    height: 1,
                    background: 'linear-gradient(90deg, transparent, #dfe6f2 20%, #dfe6f2 80%, transparent)',
                  }}
                />
                {section.section ? <p className="sidebar-heading">{section.section}</p> : null}

                {section.groups.map((group) => {
                  const isOpen = expanded === group.label;
                  return (
                    <div key={group.label}>
                      <button
                        type="button"
                        className={`sidebar-item w-full${isOpen ? ' active' : ''}`}
                        aria-expanded={isOpen}
                        onClick={() => setOpenGroup(isOpen ? '' : group.label)}
                      >
                        <Icon name={group.icon} />
                        <span className="ml-3 flex-1 text-left capitalize">{group.label}</span>
                        {/* Drawn chevron rather than the ▾ glyph, whose weight
                            and baseline vary by platform font. */}
                        <svg
                          viewBox="0 0 24 24"
                          width="14"
                          height="14"
                          fill="none"
                          stroke="currentColor"
                          strokeWidth="2.4"
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          className="shrink-0 opacity-60 transition-transform duration-200"
                          style={{ transform: isOpen ? 'rotate(180deg)' : 'none' }}
                          aria-hidden="true"
                        >
                          <path d="m6 9 6 6 6-6" />
                        </svg>
                      </button>

                      {isOpen ? (
                        <div className="collapse-inner">
                          {group.heading ? (
                            <h6
                              className="mb-1 mt-1 px-2.5 text-[10px] font-bold uppercase tracking-wide"
                              style={{ color: '#9aa3b2' }}
                            >
                              {group.heading}
                            </h6>
                          ) : null}
                          {group.items.map((item) => (
                            <NavLink
                              key={`${group.label}-${item.to}`}
                              to={item.to}
                              end
                              className={subLinkClass}
                              onClick={() => setNavOpen(false)}
                            >
                              {item.label}
                            </NavLink>
                          ))}
                        </div>
                      ) : null}
                    </div>
                  );
                })}
              </div>
            ))}
          </nav>
        </aside>

        {/* Also no `overflow-x` here: a page that wants a sticky heading of
            its own would lose it for the same reason the shell's rail did.
            min-w-0 and max-w-full already keep the column inside the row. */}
        {/* `lg:ml-[276px]` reserves the column the fixed rail occupies. The
            rail is out of the flow now, so without this the content would run
            underneath it. */}
        <main className="w-full min-w-0 max-w-full flex-1 p-4 lg:ml-[276px] lg:p-6">
          <Outlet />
        </main>
      </div>

      {/*
        Copyright line carried over from Site.Master's .ft-sticky-footer. It
        sits outside the sidebar/content row on purpose — inside it, the footer
        would sit beside the sidebar and shorten the sticky rail's travel.
        The shell is a min-h-screen flex column and the row above grows, so on
        a short page this rests at the bottom of the viewport rather than
        floating up under the content.

        app-topbar's sibling in spirit: this is shell, not page content, so it
        is dropped from print the same way the topbar is.
      */}
      <footer className="mt-auto shrink-0 px-6 py-8 text-center print:hidden">
        <span className="text-xs" style={{ color: '#858796' }}>
          Copyright © chsHub.co.in
        </span>
      </footer>

      <ProfileDialog open={profileOpen} onClose={() => setProfileOpen(false)} />

      {/*
        'warning' rather than 'danger': signing out destroys nothing and is
        undone by logging back in, so the red delete treatment would overstate
        it — but it does end the session, which is worth a stop-and-think.
      */}
      <ConfirmDialog
        open={logoutOpen}
        tone="warning"
        title="Log out"
        message="Are you sure you want to log out?"
        confirmLabel="Log Out"
        onConfirm={confirmLogout}
        onCancel={() => setLogoutOpen(false)}
        busy={signingOut}
      />
    </div>
  );
}
