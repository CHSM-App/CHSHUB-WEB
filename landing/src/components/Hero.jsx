import { ArrowRight, Lock, PlugZap, ShieldCheck, Smartphone } from 'lucide-react';
import DeviceShowcase from './DeviceShowcase';
import { useReveal } from '../hooks/useReveal';

const chips = [
  { icon: ShieldCheck, label: 'Secure' },
  { icon: Lock, label: 'Reliable' },
  { icon: PlugZap, label: 'Easy to use' },
];

export default function Hero() {
  const [ref, shown] = useReveal({ threshold: 0 });

  const step = () =>
    `transition-all duration-700 ease-out ${
      shown ? 'translate-y-0 opacity-100' : 'translate-y-6 opacity-0'
    }`;

  return (
    <section
      id='top'
      ref={ref}
      className='relative isolate overflow-x-clip border-b border-slate-200 bg-gradient-to-br from-brand-50 via-white to-sky-50'
    >
      <div aria-hidden='true' className='pointer-events-none absolute inset-0 grid-lines opacity-60' />
      <div
        aria-hidden='true'
        className='pointer-events-none absolute -top-32 -left-24 h-[420px] w-[420px] rounded-full bg-brand-200/50 blur-[110px] animate-pulse-glow'
      />
      <div
        aria-hidden='true'
        className='pointer-events-none absolute top-20 -right-28 h-[460px] w-[460px] rounded-full bg-sky-200/50 blur-[110px]'
      />

      <div className='relative mx-auto max-w-6xl px-5 pt-10 pb-24 sm:px-8 sm:pt-14 sm:pb-28'>
        <div className='grid items-center gap-12 lg:grid-cols-[1fr_1.2fr] lg:gap-8'>
          <div>
            <span
              style={{ transitionDelay: '0ms' }}
              className={`inline-flex items-center gap-2 rounded-full border border-brand-200 bg-white px-3.5 py-1.5 font-mono text-[10px] font-semibold tracking-[0.16em] text-brand-600 uppercase card-shadow ${step()}`}
            >
              One platform · Four apps
            </span>

            <h1
              style={{ transitionDelay: '80ms' }}
              className={`mt-5 font-display text-5xl leading-[1.02] font-bold tracking-tight text-slate-900 sm:text-6xl lg:text-7xl ${step()}`}
            >
              Manage Smarter.
              <br />
              <span className='text-brand-500'>Together.</span>
            </h1>

            <p
              style={{ transitionDelay: '160ms' }}
              className={`mt-5 max-w-lg text-base leading-relaxed text-slate-600 ${step()}`}
            >
              CHS HUB is a complete digital solution for society management — billing, dues,
              visitors, notices and audit-ready books. Manage operations with the committee console
              and stay connected through three purpose-built mobile apps.
            </p>

            <div
              style={{ transitionDelay: '240ms' }}
              className={`mt-7 flex flex-col gap-3 sm:flex-row ${step()}`}
            >
              <a
                href='#contact'
                className='group inline-flex items-center justify-center gap-2 rounded-[10px] bg-brand-500 px-7 py-3.5 text-base font-semibold text-white shadow-[0_10px_28px_-8px_rgba(227,27,35,0.7)] transition-all hover:-translate-y-0.5 hover:bg-brand-600'
              >
                Explore Website
                <ArrowRight className='h-4 w-4 transition-transform group-hover:translate-x-1' />
              </a>
              <a
                href='#apps'
                className='inline-flex items-center justify-center gap-2 rounded-[10px] border border-slate-300 bg-white px-7 py-3.5 text-base font-semibold text-slate-700 transition-all hover:-translate-y-0.5 hover:border-slate-400'
              >
                <Smartphone className='h-4 w-4' />
                Get Mobile App
              </a>
            </div>

            <div
              style={{ transitionDelay: '320ms' }}
              className={`mt-7 flex flex-wrap items-center gap-2.5 ${step()}`}
            >
              {chips.map((chip) => (
                <span
                  key={chip.label}
                  className='inline-flex items-center gap-2 rounded-full border border-slate-200 bg-white px-3.5 py-1.5 text-xs font-semibold text-slate-600'
                >
                  <chip.icon className='h-3.5 w-3.5 text-brand-500' />
                  {chip.label}
                </span>
              ))}
            </div>
          </div>

          <div style={{ transitionDelay: '200ms' }} className={step()}>
            <DeviceShowcase />
          </div>
        </div>
      </div>
    </section>
  );
}
