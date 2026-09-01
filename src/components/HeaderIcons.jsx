import { useCallback, useEffect, useRef, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { community } from '@/api/modules';
import { useAuth } from '@/auth/AuthContext.jsx';

/**
 * The three header icons Site.Master rendered to the left of the profile menu:
 * a Polls link, a Notifications bell with its alerts dropdown, and a Messages
 * link with an unread count.
 *
 * A village account sees the bell alone. Polls and Messages both reach for
 * flats and app accounts, which a village has neither of, so they would sit
 * empty however long anyone waited — see the notes at each.
 *
 * Counts refresh on an interval, as the legacy page's asp:Timer did.
 */
const POLL_INTERVAL_MS = 60000;

export default function HeaderIcons() {
  const navigate = useNavigate();
  const { villageId } = useAuth();
  /*
   * Polls are a society feature: they run against flats and their owners, and
   * a village has neither. The link offered a village account a page it could
   * only find empty, so it is not shown to one.
   */
  const isVillage = Boolean(villageId);
  const [alerts, setAlerts] = useState([]);
  const [unread, setUnread] = useState(0);
  const [open, setOpen] = useState(false);
  const timerRef = useRef(null);

  const refresh = useCallback(async () => {
    // Each count is independent: one failing endpoint should not blank the
    // other badge, so they settle separately rather than in one try/catch.
    // The message count is not asked for on a village account, which has no
    // envelope to put it on — it would be a request a minute for a number
    // nothing displays.
    const [notif, msg] = await Promise.allSettled([
      community.notifications(),
      isVillage ? Promise.resolve({ unread: 0 }) : community.messagesCount(),
    ]);
    if (notif.status === 'fulfilled') setAlerts(notif.value.items ?? []);
    if (msg.status === 'fulfilled') setUnread(Number(msg.value.unread) || 0);
  }, [isVillage]);

  useEffect(() => {
    refresh();
    timerRef.current = setInterval(refresh, POLL_INTERVAL_MS);
    return () => clearInterval(timerRef.current);
  }, [refresh]);

  /*
   * Alerts open the screen they are about.
   *
   * Every alert used to go to the helpdesk, whatever it was: the legacy
   * Redirect went to support_ticket.aspx because tickets were the only thing
   * that raised one. Now that NOC requests do too, a committee member tapping
   * "New NOC request" landed on a list of complaints.
   *
   * notification_type is what the notification was filed under. Anything not
   * listed here still falls back to the helpdesk, which is where the older
   * rows point.
   */
  const alertTarget = (row) =>
    ({ noc: '/community/noc' })[String(row.notification_type ?? '').toLowerCase()] ??
    '/community/helpdesk';

  const openAlert = async (row) => {
    setOpen(false);
    const id = Number(row.notify_status_id);
    setAlerts((prev) => prev.filter((a) => Number(a.notify_status_id) !== id));
    try {
      await community.markNotificationSeen(id);
    } catch {
      // Marking it read is best-effort: it reappears on the next refresh.
    }
    navigate(alertTarget(row));
  };

  return (
    <div className="flex items-center gap-1.5 sm:gap-2">
      {/* Polls drops away on the narrowest screens, where the society-name pill
          and the profile button already compete for the row — and entirely for
          a village, which has no polls to link to. */}
      {isVillage ? null : (
        <span className="hidden sm:inline-flex">
          <IconLink to="/community/polls" label="Polls" icon={<PollIcon />} />
        </span>
      )}

      <div className="relative">
        <IconButton
          label="Notifications"
          icon={<BellIcon />}
          count={alerts.length}
          expanded={open}
          onClick={() => setOpen((v) => !v)}
        />

        {open ? (
          <>
            <div className="fixed inset-0 z-40" onClick={() => setOpen(false)} aria-hidden="true" />
            {/*
              On a phone the panel is pinned to the viewport rather than hung
              off the bell.

              `absolute right-0` anchors it to the button, and the button sits
              inset from the screen edge by the messages icon and the profile
              control beside it — roughly 110px on a 360px handset. A 328px
              panel measured leftward from there starts about 78px off the left
              of the screen, so the alert titles and the whole left edge of the
              panel were cut off. Clamping the width alone could not fix that:
              the overflow came from where the panel was anchored, not from how
              wide it was.

              `fixed` with both insets set makes the viewport the containing
              block, so the panel spans the screen with an even 12px margin
              whatever the button's position. From `sm` up there is room to
              hang it off the bell as before.
            */}
            <div
              role="menu"
              className="fixed inset-x-3 top-[68px] z-50 overflow-hidden bg-white sm:absolute sm:inset-x-auto sm:right-0 sm:top-auto sm:mt-2 sm:w-[340px]"
              style={{
                borderRadius: 14,
                boxShadow: '0 12px 32px rgba(120,126,138,0.22)',
                border: '1px solid rgba(17,24,39,0.06)',
              }}
            >
              <h6
                className="flex items-center justify-between px-4 py-3 text-xs font-bold uppercase tracking-wide text-white"
                style={{ background: 'linear-gradient(120deg, #1f2937 0%, #b91c1c 100%)' }}
              >
                Alerts Center
                {alerts.length ? (
                  <span
                    className="rounded-full px-2 py-0.5 text-[10px] font-bold"
                    style={{ background: 'rgba(255,255,255,0.22)' }}
                  >
                    {alerts.length}
                  </span>
                ) : null}
              </h6>

              {/* 60vh of a phone screen leaves the list scrollable well clear
                  of the bottom of the window, with the header above it. */}
              <div className="overscroll-contain overflow-y-auto" style={{ maxHeight: 'min(440px, 60vh)' }}>
              {alerts.length === 0 ? (
                <p className="px-4 py-6 text-center text-sm text-slate-500">No Notification Found</p>
              ) : (
                alerts.map((row) => (
                  <button
                    key={row.notify_status_id}
                    type="button"
                    role="menuitem"
                    className="flex w-full items-start gap-3 border-b border-slate-100 px-4 py-3 text-left last:border-b-0 hover:bg-slate-50"
                    onClick={() => openAlert(row)}
                  >
                    {/* The legacy row used img/bell.png at 25x28 beside the
                        text; the artwork carries its own blue circle. */}
                    <span className="mt-0.5 shrink-0" aria-hidden="true">
                      <BellIcon size={26} />
                    </span>
                    <span className="min-w-0 flex-1">
                      <span className="flex items-baseline justify-between gap-2">
                        <span className="truncate text-xs font-semibold text-slate-500">{row.title}</span>
                        {/* Pre-formatted by GetRelativeTime in the procedure —
                            "5 minutes ago" when recent, a date once it ages. */}
                        <span className="shrink-0 text-xs" style={{ color: '#bcbed0' }}>
                          {row.timestamp}
                        </span>
                      </span>
                      {/* A notification can carry a reference number or a URL
                          with no break opportunity in it. Without this the row
                          sets its own width and the panel scrolls sideways. */}
                      <span className="break-anywhere mt-0.5 block text-sm text-slate-800">{row.body}</span>
                    </span>
                  </button>
                ))
              )}
              </div>
            </div>
          </>
        ) : null}
      </div>

      {/*
        Messages are between the office and residents' phones: owner_Messages
        is keyed by flat_id, and its recipients are owner_master rows — the app
        accounts. A village's residents live in house_owner and have no app, so
        a message could never reach one and the envelope would sit empty for
        good. Restore this when a village app exists, against houses rather
        than flats.

        Notifications stay: sp_dashboard's Notification branch is scoped by
        tenant, so a village account gets its own once there are any.
      */}
      {isVillage ? null : (
        <IconLink to="/community/messages" label="Messages" icon={<MailIcon />} count={unread} />
      )}
    </div>
  );
}

/**
 * Shared pill hit area, so the three icons line up and react alike: a soft
 * tinted circle that deepens and lifts on hover, and stays lit while its
 * dropdown is open.
 */
const BTN_CLASS =
  'relative flex h-10 w-10 items-center justify-center rounded-xl transition-all duration-200 ' +
  'hover:-translate-y-0.5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#e08585] ' +
  'focus-visible:ring-offset-2';

// The artwork is already solid blue, so the resting tile stays transparent and
// only a soft grey wash appears under it on hover — a blue tint behind a blue
// glyph would flatten it.
const restStyle = { background: 'transparent' };
const activeStyle = { background: '#eef2f9' };

function IconLink({ to, label, icon, count = 0 }) {
  const [hover, setHover] = useState(false);
  return (
    <Link
      to={to}
      className={BTN_CLASS}
      style={hover ? activeStyle : restStyle}
      title={label}
      aria-label={count ? `${label} (${count} unread)` : label}
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
    >
      {icon}
      <Badge count={count} />
    </Link>
  );
}

function IconButton({ label, icon, count = 0, expanded, onClick }) {
  const [hover, setHover] = useState(false);
  return (
    <button
      type="button"
      className={BTN_CLASS}
      style={hover || expanded ? activeStyle : restStyle}
      title={label}
      aria-label={count ? `${label} (${count} unread)` : label}
      aria-haspopup="menu"
      aria-expanded={expanded}
      onClick={onClick}
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
    >
      {icon}
      <Badge count={count} />
    </button>
  );
}

/**
 * .custom-badge.badge-red — capped at 99+, as get_notificatoin() did.
 *
 * The soft halo behind it is a plain sibling span rather than an animation:
 * a pulsing badge in a sticky header draws the eye away from the page on every
 * screen, and this still reads as "new" without the movement.
 */
function Badge({ count }) {
  if (!count) return null;
  const wide = count > 9;
  return (
    <span
      className="absolute flex items-center justify-center rounded-full px-1 text-white"
      style={{
        top: -3,
        right: -3,
        minWidth: wide ? 21 : 18,
        height: 18,
        fontSize: 10,
        fontWeight: 800,
        lineHeight: 1,
        background: 'linear-gradient(135deg, #ff4757, #e8303f)',
        border: '2px solid #fff',
        boxShadow: '0 2px 6px rgba(232,48,63,0.45)',
      }}
    >
      {count > 99 ? '99+' : count}
    </span>
  );
}

/*
 * The exact artwork Site.Master used — img/temp/bell.png, email.png and
 * poll.png, copied to public/icons. They are solid blue glyphs, not outlines,
 * so they are rendered as images rather than redrawn as SVG paths: any redraw
 * would be an approximation of a picture we already have.
 *
 * Rendered at 26px to match the legacy width="26px".
 */
function Png({ src, size = 26 }) {
  return <img src={src} width={size} height={size} alt="" aria-hidden="true" className="object-contain" />;
}

const BellIcon = ({ size }) => <Png src="/icons/bell.png" size={size} />;
const MailIcon = ({ size }) => <Png src="/icons/email.png" size={size} />;
const PollIcon = ({ size }) => <Png src="/icons/poll.png" size={size} />;
