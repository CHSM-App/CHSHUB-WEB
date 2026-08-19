import { useEffect, useState } from 'react';

/**
 * True while the browser is preparing a printed page.
 *
 * `print` is a CSS media, so a stylesheet can hide things — but it cannot make
 * a component render rows it decided not to render. Paging is exactly that
 * case, so the state has to reach JavaScript.
 */
export function usePrinting() {
  const [printing, setPrinting] = useState(false);

  useEffect(() => {
    const mql = window.matchMedia?.('print');
    const onChange = (e) => setPrinting(e.matches);

    // Safari and older browsers fire the window events but not the media query.
    const before = () => setPrinting(true);
    const after = () => setPrinting(false);

    mql?.addEventListener?.('change', onChange);
    window.addEventListener('beforeprint', before);
    window.addEventListener('afterprint', after);
    return () => {
      mql?.removeEventListener?.('change', onChange);
      window.removeEventListener('beforeprint', before);
      window.removeEventListener('afterprint', after);
    };
  }, []);

  return printing;
}

/**
 * The page numbers to show for `pageCount` pages while sitting on `page`.
 *
 * A society with 800 flats is 32 pages, and a button per page overflows the
 * card long before that. So the list is windowed: the first and last page are
 * always reachable, the current page keeps a neighbour either side, and the
 * gaps collapse to an ellipsis. Entries are page indexes; `'…'` is a gap.
 *
 * The window is a fixed 7 slots wide, so the pager does not resize as the user
 * moves through the pages.
 */
export function pageItems(page, pageCount) {
  if (pageCount <= 7) return Array.from({ length: pageCount }, (_, i) => i);

  // Near either end the run of pages is contiguous, so an ellipsis there would
  // hide nothing — only the far side collapses.
  if (page <= 3) return [0, 1, 2, 3, 4, '…', pageCount - 1];
  if (page >= pageCount - 4)
    return [0, '…', pageCount - 5, pageCount - 4, pageCount - 3, pageCount - 2, pageCount - 1];

  return [0, '…', page - 1, page, page + 1, '…', pageCount - 1];
}

/**
 * Paging state for a list of `total` rows.
 *
 * Returns the current page clamped into range, so a search that shortens the
 * list cannot strand the view past the end — it lands on the new last page
 * instead of showing an empty table.
 */
export function usePaging(total, pageSize) {
  const [page, setPage] = useState(0);

  /*
   * Printing a paged list would put 25 of 200 records on paper and silently
   * drop the rest, so the whole set is rendered while the print dialog is open
   * — `printing` collapses the list to a single page.
   */
  const printing = usePrinting();

  const pageCount = printing ? 1 : Math.max(1, Math.ceil(total / pageSize));
  const safePage = Math.min(page, pageCount - 1);

  // Searching jumps back to the first page: the rows are a different set, so
  // holding position at page 4 of the old list means nothing in the new one.
  useEffect(() => {
    setPage(0);
  }, [total]);

  const first = printing ? 0 : safePage * pageSize;

  return {
    page: safePage,
    setPage,
    pageCount,
    first,
    // How many rows the caller should slice — the whole list while printing.
    size: printing ? total : pageSize,
    // One past the last row shown, for the "1–25 of 200" range text.
    last: printing ? total : Math.min(first + pageSize, total),
  };
}

/**
 * The shared list pager — numbered pages between Previous and Next.
 *
 * Holding Next through a 30-page member list is not how anyone reads it, so
 * every page is one click away. Renders nothing when everything fits on a
 * single page.
 */
export default function Pager({ page, pageCount, first, last, total, onPage }) {
  if (pageCount <= 1) return null;

  return (
    <div className="flex flex-wrap items-center justify-between gap-2 border-t border-slate-200 px-4 py-2 text-sm print:hidden">
      <span className="text-slate-500">
        {first + 1}–{last} of {total}
      </span>
      <nav className="flex shrink-0 items-center gap-2" aria-label="Pagination">
        <button
          type="button"
          className="btn-secondary px-3 py-1 text-xs"
          onClick={() => onPage(Math.max(0, page - 1))}
          disabled={page === 0}
        >
          Previous
        </button>
        {/*
          Numbered pages, so a long list can be reached in one click rather than
          by holding Next. Hidden below `sm`, where the card view is already
          narrow — Previous/Next carry the phone.
        */}
        <div className="hidden items-center gap-1 sm:flex">
          {pageItems(page, pageCount).map((item, i) =>
            item === '…' ? (
              <span key={`gap-${i}`} className="px-1 text-slate-400" aria-hidden="true">
                …
              </span>
            ) : (
              <button
                key={item}
                type="button"
                // The current page is a state, not an action: it reads as
                // selected and is marked for a screen reader.
                className={`min-w-[1.75rem] rounded px-2 py-1 text-xs ${
                  item === page
                    ? 'bg-slate-800 font-medium text-white'
                    : 'text-slate-600 hover:bg-slate-100'
                }`}
                aria-label={`Page ${item + 1}`}
                aria-current={item === page ? 'page' : undefined}
                onClick={() => onPage(item)}
              >
                {item + 1}
              </button>
            ),
          )}
        </div>
        <button
          type="button"
          className="btn-secondary px-3 py-1 text-xs"
          onClick={() => onPage(Math.min(pageCount - 1, page + 1))}
          disabled={page >= pageCount - 1}
        >
          Next
        </button>
      </nav>
    </div>
  );
}
