import { useMemo, useState } from 'react';
import { Link, NavLink, Outlet, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '@/auth/AuthContext.jsx';

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
          { to: '/reports/profit-loss', label: 'Annual income & expenditure' },
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
        items: [
          { to: '/dashboard', label: 'Dashboard' },
          { to: '/village/residents', label: 'Village Residents' },
          { to: '/village/payments', label: 'Tax Payments' },
          { to: '/community/notices', label: 'Announcements' },
          { to: '/village/staff', label: 'Staff Management' },
          { to: '/village/history', label: 'History' },
        ],
      },
    ],
  },
];

/**
 * Inline SVGs standing in for the legacy Font Awesome glyphs. Drawn here rather
 * than pulled from a CDN — the app must not depend on an external host.
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

  // Hide the Village section for society-only accounts.
  const sections = NAV.filter((g) => !g.villageOnly || Boolean(villageId));

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

  const handleLogout = async () => {
    // Site.Master guarded this with a confirm; keep it so a stray click on the
    // menu does not end the session.
    if (!window.confirm('Are you sure you want to log out?')) return;
    setMenuOpen(false);
    await logout();
    navigate('/login', { replace: true });
  };

  return (
    <div className="min-h-screen">
      {/*
        Sticky white topbar with the CHS HUB mark on the left and the signed-in
        user on the right — the arrangement Site.Master used.
      */}
      <header
        className="sticky top-0 z-50 flex items-center justify-between bg-white"
        style={{ padding: '12px 24px', boxShadow: '0 4px 12px rgba(0,0,0,0.08)' }}
      >
        <div className="flex items-center gap-4">
          <button
            type="button"
            className="rounded p-2 text-lg leading-none lg:hidden"
            aria-label="Toggle navigation"
            aria-expanded={navOpen}
            onClick={() => setNavOpen((v) => !v)}
          >
            ☰
          </button>

          {/* .chs-logo — red gradient, 12px radius (Site.Master:498). */}
          <div
            className="shrink-0"
            style={{
              background: 'linear-gradient(135deg, #c94040 0%, #e85555 100%)',
              borderRadius: '12px',
              padding: '8px 12px',
              boxShadow: '0 2px 8px rgba(201, 64, 64, 0.3)',
            }}
          >
            <div
              className="text-center text-white"
              style={{
                fontWeight: 800,
                fontSize: '12px',
                lineHeight: 1.1,
                letterSpacing: '0.5px',
                fontFamily: 'Arial, sans-serif',
              }}
            >
              CHS
              <br />
              HUB
            </div>
          </div>

          {/* .society-name-pill — white rounded pill (Site.Master). */}
          <div
            className="min-w-0"
            style={{
              background: 'white',
              borderRadius: '20px',
              padding: '10px 24px',
              boxShadow: '0 2px 8px rgba(0, 0, 0, 0.06)',
              maxWidth: '420px',
              border: '1px solid #0000ff1f',
            }}
          >
            <p className="truncate text-sm font-semibold" style={{ color: '#012970' }}>
              {user?.society_name || user?.village_name || 'Society Management'}
            </p>
          </div>
        </div>

        {/* Profile dropdown — Profile / Settings / Log Out, as Site.Master had. */}
        <div className="relative">
          <button
            type="button"
            className="flex items-center gap-2 rounded-full py-1 pl-1 pr-4"
            style={{ border: '1px solid #0000ff1f', boxShadow: '0 2px 8px rgba(0,0,0,0.06)' }}
            aria-expanded={menuOpen}
            aria-haspopup="menu"
            onClick={() => setMenuOpen((v) => !v)}
          >
            <span
              className="flex h-8 w-8 items-center justify-center rounded-full text-xs font-bold text-white"
              style={{ background: 'linear-gradient(135deg, #1d4ed8, #2563eb)' }}
              aria-hidden="true"
            >
              {(user?.name || '?').trim().charAt(0).toUpperCase()}
            </span>
            <span className="hidden text-sm font-medium sm:inline" style={{ color: '#012970' }}>
              Hello, {user?.name}
            </span>
          </button>

          {menuOpen ? (
            <>
              {/* Click-away layer, so the menu closes like the Bootstrap one. */}
              <div className="fixed inset-0 z-40" onClick={() => setMenuOpen(false)} aria-hidden="true" />
              <div
                role="menu"
                className="absolute right-0 z-50 mt-2 bg-white py-1"
                style={{ width: 200, borderRadius: 12, boxShadow: '0 0.5rem 1rem rgba(0,0,0,.15)' }}
              >
                <Link
                  to="/settings/society"
                  role="menuitem"
                  className="block px-4 py-2 text-sm hover:bg-slate-50"
                  style={{ color: '#012970' }}
                  onClick={() => setMenuOpen(false)}
                >
                  Profile
                </Link>
                <Link
                  to="/settings/accounts"
                  role="menuitem"
                  className="block px-4 py-2 text-sm hover:bg-slate-50"
                  style={{ color: '#012970' }}
                  onClick={() => setMenuOpen(false)}
                >
                  Settings
                </Link>
                <div className="my-1 border-t" style={{ borderColor: '#e5e7eb' }} />
                <button
                  type="button"
                  role="menuitem"
                  className="block w-full px-4 py-2 text-left text-sm hover:bg-slate-50"
                  style={{ color: '#012970' }}
                  onClick={handleLogout}
                >
                  Log Out
                </button>
              </div>
            </>
          ) : null}
        </div>
      </header>

      <div className="lg:flex lg:items-start lg:gap-2">
        {/*
          Legacy sidebar: a white rounded card floating on the page background,
          not a full-height rail — ul#accordionSidebar in site_master_style.css.
        */}
        <aside
          className={`${navOpen ? 'block' : 'hidden'} lg:block lg:shrink-0`}
          style={{ padding: '8px' }}
        >
          <nav
            className="overflow-y-auto rounded-xl bg-white lg:w-[260px] lg:h-[85vh] lg:sticky lg:top-[84px]"
            style={{ padding: '16px', boxShadow: 'rgba(0, 0, 0, 0.15) 1.95px 1.95px 4px' }}
          >
            {/* Dashboard sits above the first heading, as in Site.Master. */}
            <NavLink to="/dashboard" className={linkClass} onClick={() => setNavOpen(false)}>
              <Icon name="home" />
              <span className="ml-3">Dashboard</span>
            </NavLink>

            {sections.map((section, si) => (
              <div key={section.section ?? `village-${si}`}>
                <hr className="my-3 border-t" style={{ borderColor: '#e5e7eb' }} />
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
                        <span className="ml-3 flex-1 text-left">{group.label}</span>
                        <span
                          className="text-xs transition-transform"
                          style={{ transform: isOpen ? 'rotate(180deg)' : 'none' }}
                          aria-hidden="true"
                        >
                          ▾
                        </span>
                      </button>

                      {isOpen ? (
                        <div className="collapse-inner">
                          {group.heading ? (
                            <h6 className="mb-1 mt-2 text-xs font-semibold" style={{ color: '#6b7280' }}>
                              {group.heading}
                            </h6>
                          ) : null}
                          {group.items.map((item) => (
                            <NavLink
                              key={`${group.label}-${item.to}`}
                              to={item.to}
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

        <main className="min-w-0 flex-1 p-4 lg:p-6">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
