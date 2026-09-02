import { Building2, Receipt, ShieldCheck } from 'lucide-react';
import Reveal from './Reveal';

const points = [
  {
    icon: Receipt,
    title: 'Instant Receipts',
    text: 'Record a payment and print the receipt on the spot.',
  },
  {
    icon: ShieldCheck,
    title: 'Dues on Track',
    text: 'Defaulters and post-dated cheques tracked in one list.',
  },
  {
    icon: Building2,
    title: 'Start in Minutes',
    text: 'Import your existing flats and owners from Excel.',
  },
];

export default function ShowcaseBand() {
  return (
    <section className='relative isolate overflow-hidden'>
      <img
        src='/img/society-building.jpg'
        alt='A housing society building at dusk'
        loading='lazy'
        className='absolute inset-0 h-full w-full object-cover'
      />
      <div
        aria-hidden='true'
        className='absolute inset-0 bg-gradient-to-r from-slate-950/94 via-slate-950/82 to-slate-950/70'
      />

      <div className='relative mx-auto max-w-6xl px-5 py-20 sm:px-8 sm:py-28'>
        <Reveal className='max-w-2xl'>
          <p className='font-mono text-[10px] font-semibold tracking-[0.2em] text-brand-300 uppercase'>
            Why committees switch
          </p>
          <h2 className='mt-3 font-display text-4xl font-bold tracking-tight text-white sm:text-5xl'>
            Your society, finally on one system
          </h2>
          <p className='mt-5 text-base leading-relaxed text-white/70'>
            No more parallel spreadsheets, WhatsApp groups for notices and a register at the gate.
            Everything a committee runs sits in one place — and every resident sees the part that
            belongs to them.
          </p>
        </Reveal>

        <div className='mt-12 grid gap-5 sm:grid-cols-3'>
          {points.map((point, index) => (
            <Reveal key={point.title} delay={index * 90}>
              <div className='h-full rounded-2xl border border-white/15 bg-slate-950/45 p-5 backdrop-blur-md'>
                <div className='flex h-10 w-10 items-center justify-center rounded-xl bg-brand-500'>
                  <point.icon className='h-5 w-5 text-white' />
                </div>
                <h3 className='mt-4 font-display text-lg font-bold tracking-tight text-white'>
                  {point.title}
                </h3>
                <p className='mt-1.5 text-sm leading-relaxed text-white/65'>{point.text}</p>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}
