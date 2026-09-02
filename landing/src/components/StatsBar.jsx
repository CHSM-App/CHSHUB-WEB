import { FileSpreadsheet, Languages, Lock, ShieldCheck } from 'lucide-react';

// Capability claims rather than usage counts — every one of these is something
// the product actually does, so nothing here needs to be revised as the
// customer base grows.
const points = [
  {
    icon: FileSpreadsheet,
    title: 'Excel import',
    text: 'Bring your existing flats and owners',
  },
  {
    icon: ShieldCheck,
    title: 'Audit-ready',
    text: 'Balance sheet, AGM and audit reports',
  },
  {
    icon: Lock,
    title: 'Separate tenants',
    text: 'Your society, its own data',
  },
  {
    icon: Languages,
    title: 'Multi-language',
    text: 'Gatekeeper app in 5 Indian languages',
  },
];

export default function StatsBar() {
  return (
    <section className='relative -mt-16 px-5 sm:px-8'>
      <div className='mx-auto max-w-5xl'>
        <div className='grid divide-y divide-white/15 rounded-2xl bg-gradient-to-r from-brand-500 to-brand-600 shadow-[0_20px_50px_-16px_rgba(227,27,35,0.55)] sm:grid-cols-2 sm:divide-y-0 lg:grid-cols-4 lg:divide-x'>
          {points.map((point) => (
            <div key={point.title} className='flex items-start gap-3 px-5 py-6 text-white'>
              <point.icon className='mt-0.5 h-6 w-6 shrink-0 text-white/75' />
              <div>
                <p className='font-display text-lg leading-tight font-bold'>{point.title}</p>
                <p className='mt-1 text-xs leading-snug text-white/75'>{point.text}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
