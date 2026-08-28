import {
  BarChart3,
  Bell,
  CalendarCheck,
  FileText,
  Receipt,
  Users,
  Wallet,
  Wrench,
} from 'lucide-react';
import Reveal from './Reveal';

const features = [
  {
    icon: Receipt,
    title: 'Billing & Collections',
    text: 'Generate bills, collect payments and issue receipts on the spot.',
    tint: 'bg-brand-50 text-brand-600',
  },
  {
    icon: Wrench,
    title: 'Complaints Management',
    text: 'Residents raise issues from the app; the committee tracks and closes them.',
    tint: 'bg-amber-50 text-amber-600',
  },
  {
    icon: Users,
    title: 'Visitor Management',
    text: 'Gate passes, QR scanning and in/out logs at every entry.',
    tint: 'bg-sky-50 text-sky-600',
  },
  {
    icon: Bell,
    title: 'Notices & Alerts',
    text: 'Push a notice once and it reaches every resident in real time.',
    tint: 'bg-indigo-50 text-indigo-600',
  },
  {
    icon: BarChart3,
    title: 'Reports & Analytics',
    text: 'Income, expenditure, balance sheet, audit and AGM packs in a click.',
    tint: 'bg-emerald-50 text-emerald-600',
  },
  {
    icon: Wallet,
    title: 'Accounts & Cashbook',
    text: 'Expenses, vendor bills and ledger stay reconciled automatically.',
    tint: 'bg-violet-50 text-violet-600',
  },
  {
    icon: CalendarCheck,
    title: 'Facilities & Events',
    text: 'Book the clubhouse by slot, run polls and schedule meetings.',
    tint: 'bg-rose-50 text-rose-600',
  },
  {
    icon: FileText,
    title: 'Documents & NOC',
    text: 'Society documents, share certificates and NOC issuance, searchable.',
    tint: 'bg-teal-50 text-teal-600',
  },
];

export default function Features() {
  return (
    <section id='features' className='border-y border-slate-200 bg-page py-20 sm:py-28'>
      <div className='mx-auto max-w-6xl px-5 sm:px-8'>
        <Reveal className='text-center'>
          <p className='font-mono text-[10px] font-semibold tracking-[0.2em] text-brand-500 uppercase'>
            Powerful features
          </p>
          <h2 className='mt-3 font-display text-4xl font-bold tracking-tight text-slate-900 sm:text-5xl'>
            Everything You Need, All in One Place
          </h2>
          <p className='mx-auto mt-4 max-w-2xl text-base leading-relaxed text-slate-600'>
            Built from the day-to-day work of real housing societies — not a generic CRM bent into
            shape.
          </p>
        </Reveal>

        <div className='mt-14 grid gap-5 sm:grid-cols-2 lg:grid-cols-4'>
          {features.map((feature, index) => (
            <Reveal key={feature.title} delay={(index % 4) * 70}>
              <div className='group h-full rounded-2xl border border-slate-200 bg-white p-6 transition-all duration-200 hover:-translate-y-1 hover:border-brand-200 hover:card-shadow'>
                <div
                  className={`flex h-11 w-11 items-center justify-center rounded-xl transition-transform duration-200 group-hover:scale-110 ${feature.tint}`}
                >
                  <feature.icon className='h-5 w-5' />
                </div>
                <h3 className='mt-5 font-display text-lg font-bold tracking-tight text-slate-900'>
                  {feature.title}
                </h3>
                <p className='mt-2 text-sm leading-relaxed text-slate-600'>{feature.text}</p>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}
