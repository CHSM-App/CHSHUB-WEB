import { ArrowRight, Mail, Monitor, Phone } from 'lucide-react';
import Reveal from './Reveal';

function PlayStoreGlyph() {
  return (
    <svg viewBox='0 0 24 24' aria-hidden='true' className='h-6 w-6 shrink-0'>
      <path fill='#fff' d='M3.6 1.8a1 1 0 0 0-.5.9v18.6a1 1 0 0 0 .5.9l10-10.2-10-10.2Z' opacity='.9' />
      <path fill='#fff' d='m14.9 10.7 3.2-3.3 1.9 1.1c1.1.6 1.1 2.2 0 2.8l-1.9 1.1-3.2-3.3v1.6Z' opacity='.75' />
      <path fill='#fff' d='m4.3 22.3 10.6-10.8 2.4 2.5-11 6.3a1 1 0 0 1-2-.4v2.4Z' opacity='.6' />
    </svg>
  );
}

export default function CtaSection() {
  return (
    <section
      id='contact'
      className='relative isolate overflow-x-clip bg-gradient-to-br from-brand-600 via-brand-500 to-indigo-700 py-20 sm:py-24'
    >
      <div
        aria-hidden='true'
        className='pointer-events-none absolute -top-24 -left-20 h-[380px] w-[380px] rounded-full bg-white/10 blur-[100px]'
      />

      <div className='relative mx-auto max-w-6xl px-5 sm:px-8'>
        <div className='grid items-center gap-12 lg:grid-cols-[1.1fr_1fr]'>
          <Reveal>
            <h2 className='font-display text-4xl leading-tight font-bold tracking-tight text-white sm:text-5xl'>
              Ready to Transform
              <br />
              Your Society?
            </h2>
            <p className='mt-5 max-w-lg text-base leading-relaxed text-white/85'>
              Book a 30-minute walkthrough. We will set up a demo society with your own flat list,
              so you see your data in it — not ours.
            </p>

            <div className='mt-8 flex flex-col gap-3 sm:flex-row'>
              <a
                href='mailto:support@vengurlatech.com?subject=CHS%20HUB%20demo%20request'
                className='group inline-flex items-center justify-center gap-2 rounded-[10px] bg-white px-7 py-3.5 text-base font-semibold text-brand-600 transition-all hover:-translate-y-0.5 hover:bg-brand-50'
              >
                <Mail className='h-4 w-4' />
                Get Started Now
                <ArrowRight className='h-4 w-4 transition-transform group-hover:translate-x-1' />
              </a>
              <a
                href='tel:+919422229951'
                className='inline-flex items-center justify-center gap-2 rounded-[10px] border border-white/45 px-7 py-3.5 text-base font-semibold text-white transition-all hover:-translate-y-0.5 hover:bg-white/10'
              >
                <Phone className='h-4 w-4' />
                +91 94222 29951
              </a>
            </div>

            <p className='mt-6 font-mono text-[10px] tracking-[0.16em] text-white/70 uppercase'>
              No setup fee · Data import included
            </p>
          </Reveal>

          <Reveal delay={120} className='grid gap-4 sm:grid-cols-2'>
            <div className='rounded-2xl bg-white/12 p-5 backdrop-blur-sm'>
              <div className='flex h-10 w-10 items-center justify-center rounded-xl bg-white/20'>
                <Monitor className='h-5 w-5 text-white' />
              </div>
              <p className='mt-4 font-display text-lg font-bold text-white'>Website for Management</p>
              <p className='mt-1.5 text-sm text-white/75'>
                The full committee console at chshub.co.in
              </p>
              <a
                href='https://chshub.co.in/login'
                className='mt-4 inline-flex items-center gap-1.5 rounded-[10px] bg-white px-4 py-2 text-sm font-semibold text-brand-600 transition-colors hover:bg-brand-50'
              >
                Explore Website
                <ArrowRight className='h-3.5 w-3.5' />
              </a>
            </div>

            <div className='rounded-2xl bg-white/12 p-5 backdrop-blur-sm'>
              <div className='flex items-center gap-2'>
                <img
                  src='/img/owner-icon.png'
                  alt='CHS HUB Owner app icon'
                  loading='lazy'
                  className='h-10 w-10 rounded-xl ring-1 ring-white/25'
                />
                <img
                  src='/img/gatekeeper-icon.png'
                  alt='CHS HUB Gatekeeper app icon'
                  loading='lazy'
                  className='h-10 w-10 rounded-xl ring-1 ring-white/25'
                />
              </div>
              <p className='mt-4 font-display text-lg font-bold text-white'>Mobile App for Residents</p>
              <p className='mt-1.5 text-sm text-white/75'>
                Owner, Gatekeeper and Secretary apps
              </p>
              {/* Play Store badge. The apps are not published yet, so this is a
                  non-link placeholder — swap the wrapper for an <a href="..."> once
                  the listing is live. */}
              <div className='mt-4 inline-flex cursor-default items-center gap-2.5 rounded-[10px] border border-white/25 bg-white/10 px-4 py-2'>
                <PlayStoreGlyph />
                <span className='text-left leading-tight'>
                  <span className='block text-[9px] tracking-[0.14em] text-white/60 uppercase'>
                    Coming soon on
                  </span>
                  <span className='block text-sm font-semibold text-white'>Google Play</span>
                </span>
              </div>
            </div>
          </Reveal>
        </div>
      </div>
    </section>
  );
}
