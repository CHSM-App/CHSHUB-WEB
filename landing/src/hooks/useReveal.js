import { useEffect, useRef, useState } from 'react';

// Reveals an element once it scrolls into view. Respects prefers-reduced-motion
// by starting in the revealed state so nothing is ever hidden without motion.
export function useReveal({ threshold = 0.15, rootMargin = '0px 0px -60px 0px' } = {}) {
  const ref = useRef(null);
  const [shown, setShown] = useState(false);

  useEffect(() => {
    const node = ref.current;
    if (!node) return;

    const reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    if (reduced || typeof IntersectionObserver === 'undefined') {
      setShown(true);
      return;
    }

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            setShown(true);
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold, rootMargin }
    );

    observer.observe(node);

    // Safety net: if the observer never fires (deep-link into an anchor, restored
    // scroll position, a browser that mis-reports intersection) content must never
    // stay invisible. Reveal it anyway shortly after mount.
    const failsafe = setTimeout(() => setShown(true), 1600);

    return () => {
      clearTimeout(failsafe);
      observer.disconnect();
    };
  }, [threshold, rootMargin]);

  return [ref, shown];
}
