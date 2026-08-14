import { BrandMark, Glyph } from '@/components/AuthLayout.jsx';

/*
 * The sign-in screen's own shell — a full-bleed white page with a red
 * illustrated half on the left and the form on the right. There is no outer
 * frame and no card: the page itself is the design.
 *
 * The red half's right edge is straight. The circles are what break it: two
 * overhang the seam onto the white, and one more sits low on the right of the
 * form column, so the artwork reads as one composition laid over the page
 * rather than a panel with decoration boxed inside it.
 *
 * AuthSplitLayout still dresses register / forgot-password / the setup wizards
 * and this deliberately does not replace it — those forms are long and need a
 * plain two-column page, and they stay on the app's blue.
 *
 * This screen alone is red: the artwork below and the .login-* / .auth-showcase-*
 * rules in index.css read --login-accent, scoped to .auth-showcase-page. The
 * app's --accent / --accent-strong are untouched and still blue everywhere else.
 */

/*
 * Sizes are in `vw` so the composition keeps its proportions on a wide monitor
 * instead of the spheres shrinking into a corner, and each is clamped so it
 * cannot collapse on a small laptop or run away on an ultrawide.
 *
 * `blur` separates the backdrop wash from the solid spheres in front of it.
 */

/*
 * Laid over the red panel, clipped to nothing — these may overhang the seam.
 *
 * Every sphere is DARKER than the panel behind it, not lighter. The headline
 * sits on top of the big one in white, and a light sphere behind white text
 * leaves it unreadable — the contrast has to come from the artwork going down
 * in luminance, not up.
 */
const PANEL_CIRCLES = [
  // The deep sphere behind the headline, anchored to the top-right of the
  // panel. It is DARKER than the fill and its left arc sweeps in behind
  // "WELCOME", which is what gives the white headline its contrast.
  {
    size: 'clamp(430px, 44vw, 760px)',
    top: '-30%',
    right: '-16%',
    background: 'linear-gradient(150deg, #cf4141 0%, #ad2020 50%, #83160f 100%)',
  },
  // The bottom-left corner shape. In the reference this is a large rounded
  // form cropped hard by the frame's corner, mid-red against the pale
  // corner of the fill — not a small accent dot.
  {
    size: 'clamp(250px, 26vw, 450px)',
    bottom: '-24%',
    left: '-19%',
    background: 'linear-gradient(140deg, #f28080 0%, #dc4a4a 55%, #c23131 100%)',
  },
];

/*
 * Drawn on the unclipped page-level layer, so these cross the seam onto the
 * white — the shapes that break the straight edge in the reference. Anchored
 * with `left` around 50% (the seam) rather than to either column.
 */
const SPILL_CIRCLES = [
  /*
   * The overlapping pair, sitting under the headline in the panel's lower
   * half. These are the reference's signature: two clearly separate discs,
   * the right one riding over the left, both LIGHTER than the panel so they
   * read as discrete circles rather than as shading.
   *
   * The right one crosses the seam onto the white, which is what breaks the
   * curved edge and stops the composition reading as two boxes side by side.
   */
  /*
   * Both are positioned against the SEAM (50% of the frame) rather than against
   * the frame's left edge, so the pair keeps its relationship to the edge it is
   * supposed to break at any width. Anchoring them in vw from the left let them
   * drift entirely onto the red on a wide viewport.
   */
  // The larger, lower-left disc. Sits mostly on the red, its right edge
  // reaching the seam.
  {
    size: 'clamp(190px, 19vw, 330px)',
    bottom: '-12%',
    left: 'calc(50% - clamp(215px, 21.5vw, 375px))',
    background: 'linear-gradient(150deg, #f79b9b 0%, #e85f5f 52%, #d24040 100%)',
  },
  // The upper-right disc, overlapping the first and crossing onto the white.
  // Drawn after it, so it paints on top — the overlap in the reference reads
  // this way round.
  //
  // The hairline ring is what separates the two where they overlap: both are
  // light red on light red, and without an edge the pair merges into one
  // blob rather than reading as a disc in front of a disc.
  {
    size: 'clamp(178px, 17.8vw, 310px)',
    bottom: '10%',
    left: 'calc(50% - clamp(72px, 7vw, 125px))',
    background: 'linear-gradient(150deg, #f38484 0%, #dd4b4b 52%, #c33232 100%)',
    ring: '0 0 0 1px rgba(255,255,255,0.16)',
  },
  // The bottom-right corner. Large and mostly outside the frame — in the
  // reference it fills the whole corner rather than sitting as a small accent.
  {
    size: 'clamp(240px, 25vw, 440px)',
    bottom: '-21%',
    right: '-13%',
    background: 'linear-gradient(140deg, #f28282 0%, #de4646 55%, #be2f2f 100%)',
  },
];

/** One positioned sphere. Shared by both groups so they cannot drift apart. */
function Sphere({ circle }) {
  return (
    <span
      className="pointer-events-none absolute rounded-full"
      aria-hidden="true"
      style={{
        width: circle.size,
        height: circle.size,
        top: circle.top,
        bottom: circle.bottom,
        left: circle.left,
        right: circle.right,
        background: circle.background,
        boxShadow: circle.ring,
        filter: circle.blur ? `blur(${circle.blur}px)` : undefined,
      }}
    />
  );
}

/**
 * Two-column page: the red welcome half and the form.
 *
 * Below `lg` the red half collapses to a header strip above the form — a
 * phone gets the greeting and the mark without scrolling past a hero — and the
 * overhanging spheres are clipped there, since on a narrow screen they would
 * spill across the form instead of across white space.
 */
export default function AuthShowcaseLayout({ heading, tagline, title, subtitle, footer, children }) {
  return (
    /* Two nested elements, not one: the outer is the white frame (its padding
       is the margin of white around the artwork), and .auth-showcase-frame
       inside it is the rounded, clipped stage everything is drawn on. The clip
       has to be on the inner one — it is what rounds the artwork's corners,
       and it also stops the overhanging spheres from widening the document
       into a horizontal scroll while still letting them cross the seam. */
    <div className="auth-showcase-page relative min-h-screen">
     <div className="auth-showcase-frame">
      {/* ----------------------------------------------------------------- */}
      {/* Welcome half                                                       */}
      {/* ----------------------------------------------------------------- */}
      {/* The red fill comes from .auth-showcase-half in index.css rather than
          an inline style: the sphere layer has to sit between that fill and
          this element's text, which needs the two on separate stacking levels. */}
      {/* The right padding is far larger than the left from `lg`: the panel
          overhangs its column and its right edge is a bulge, so text laid out
          against the element's own box would run under the curve and get
          clipped. The extra inset keeps every line inside the narrowest part
          of the red. */}
      <section className="auth-showcase-half relative px-7 py-9 text-white max-lg:overflow-hidden sm:px-10 lg:flex lg:flex-col lg:py-12 lg:pl-16 lg:pr-[26%]">
        {/* Hidden below lg: on a phone the halves stack, so a sphere crossing
            the seam would land on the form rather than on white space. */}
        <div className="auth-showcase-art hidden lg:block" aria-hidden="true">
          {PANEL_CIRCLES.map((circle, index) => (
            <Sphere key={index} circle={circle} />
          ))}
        </div>

        {/* The mark stays above the greeting so the panel is identifiably this
            product and not a stock illustration. */}
        <div className="relative flex items-center gap-3">
          <BrandMark size={40} />
          <div>
            <p className="text-sm font-bold leading-tight">CHS HUB</p>
            <p className="text-[11px]" style={{ color: 'rgba(255,255,255,0.7)' }}>
              Society Management Suite
            </p>
          </div>
        </div>

        {/* Vertically centred against the half, not stacked under the mark —
            the reference puts the headline across the sphere's middle. */}
        <div className="relative mt-9 lg:mt-0 lg:flex lg:flex-1 lg:flex-col lg:justify-center">
          {/* Colour set explicitly rather than inherited: this sits on the
              artwork, and it must stay white whatever the spheres do. */}
          {/* Sized in vw between clamps from `lg`: in the reference "WELCOME"
              spans most of the panel's width, and a fixed rem size would leave
              it stranded in the middle of a wide column. */}
          <h2
            className="text-[2.4rem] font-extrabold uppercase leading-none tracking-tight sm:text-[3.2rem] lg:text-[clamp(2.6rem,4.6vw,4.4rem)]"
            style={{ color: '#fff' }}
          >
            {heading}
          </h2>
          <p
            className="mt-3 text-base font-bold uppercase tracking-[0.04em] sm:text-xl lg:text-[clamp(0.95rem,1.35vw,1.35rem)]"
            style={{ color: '#fff' }}
          >
            {tagline}
          </p>
          <p
            className="mt-5 hidden max-w-[21rem] text-[12px] leading-[1.75] lg:block"
            style={{ color: 'rgba(255,255,255,0.72)' }}
          >
            Billing, members, facilities and accounts for your co-operative housing
            society — in one place, for the whole committee.
          </p>
        </div>

        <p className="relative mt-9 text-xs lg:mt-0" style={{ color: 'rgba(255,255,255,0.55)' }}>
          Copyright © chsHub.co.in
        </p>
      </section>

      {/*
        The unclipped artwork, between the two halves in document order: it
        paints over the red half and under the form, which is what lets these
        spheres cross the seam while the half's own edge stays straight.
        Hidden below lg, where the halves stack and a crossing sphere would
        land on the form instead of on white space.
      */}
      <div className="auth-showcase-spill hidden lg:block" aria-hidden="true">
        {SPILL_CIRCLES.map((circle, index) => (
          <Sphere key={index} circle={circle} />
        ))}
      </div>

      {/* ----------------------------------------------------------------- */}
      {/* Form half                                                          */}
      {/* ----------------------------------------------------------------- */}
      {/* No background of its own — the frame under it is already white, and a
          fill here would paint over the spheres that cross the seam. It is
          `relative` so it still stacks above the spill layer, keeping the form
          itself clear of the artwork. */}
      <section className="relative z-[2] flex items-center justify-center px-6 py-10 max-lg:overflow-hidden sm:px-10 lg:px-14">

        {/* Capped and centred: on a wide monitor a form tracking the column
            width would stretch the inputs far past a comfortable line. */}
        <div className="relative w-full max-w-[370px]">
          <h1
            className="text-[1.9rem] font-extrabold leading-tight tracking-tight sm:text-[2.3rem]"
            style={{ color: '#12233f' }}
          >
            {title}
          </h1>
          {subtitle ? <p className="mt-1.5 text-[12px] text-slate-500">{subtitle}</p> : null}

          <div className="mt-5">{children}</div>

          {footer ? (
            <p className="mt-5 text-[12.5px]" style={{ color: 'var(--ink-muted)' }}>
              {footer}
            </p>
          ) : null}

          <p className="mt-3 flex items-center gap-1.5 text-[11px]" style={{ color: '#8b94a5' }}>
            <Glyph size={13}>
              <path d="M12 3 5 6v5c0 4.4 2.9 8.4 7 9.5 4.1-1.1 7-5.1 7-9.5V6l-7-3Z" />
            </Glyph>
            Your session is encrypted and private.
          </p>
        </div>
      </section>
     </div>
    </div>
  );
}
