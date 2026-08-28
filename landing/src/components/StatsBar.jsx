import { Building2, IndianRupee, Star, Users } from 'lucide-react';
import { useCountUp } from '../hooks/useReveal';

const stats = [
  { icon: Building2, value: 500, suffix: '+', label: 'Societies' },
  { icon: Users, value: 50000, suffix: '+', label: 'Residents', compact: true },
  { icon: IndianRupee, value: 100000, suffix: '+', label: 'Transactions', compact: true },
  { icon: Star, value: 99, suffix: '%', label: 'Satisfaction' },
];

function Stat({ icon: Icon, value, suffix, label, compact }) {
  const [ref, count] = useCountUp(value);
  const shown = compact ? `${Math.round(count / 1000)},000` : count.toLocaleString('en-IN');

  return (
    <div ref={ref} className='flex items-center justify-center gap-3 px-4 py-6 text-white'>
      <Icon className='h-7 w-7 shrink-0 text-white/70' />
      <div>
        <p className='font-display text-3xl leading-none font-bold tabular-nums'>
          {shown}
          {suffix}
        </p>
        <p className='mt-1 text-xs font-medium text-white/70'>{label}</p>
      </div>
    </div>
  );
}

export default function StatsBar() {
  return (
    <section className='relative -mt-16 px-5 sm:px-8'>
      <div className='mx-auto max-w-5xl'>
        <div className='grid divide-y divide-white/15 rounded-2xl bg-gradient-to-r from-brand-500 to-brand-600 shadow-[0_20px_50px_-16px_rgba(227,27,35,0.55)] sm:grid-cols-2 sm:divide-y-0 lg:grid-cols-4 lg:divide-x'>
          {stats.map((stat) => (
            <Stat key={stat.label} {...stat} />
          ))}
        </div>
      </div>
    </section>
  );
}
