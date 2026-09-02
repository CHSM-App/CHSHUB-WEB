import { ClipboardList, Home, ShieldCheck, UserCog, Users } from 'lucide-react';
import Reveal from './Reveal';

const roles = [
  {
    icon: UserCog,
    title: 'For Admins',
    text: 'Complete control over society operations and management',
    tint: 'bg-brand-50 border-brand-100',
    icon_tint: 'bg-brand-100 text-brand-600',
  },
  {
    icon: ClipboardList,
    title: 'For Secretaries',
    text: 'Bills, receipts, cashbook and defaulters — all from your phone',
    tint: 'bg-amber-50 border-amber-100',
    icon_tint: 'bg-amber-100 text-amber-600',
  },
  {
    icon: Home,
    title: 'For Residents',
    text: 'Pay dues, raise complaints and book amenities with a few taps',
    tint: 'bg-sky-50 border-sky-100',
    icon_tint: 'bg-sky-100 text-sky-600',
  },
  {
    icon: ShieldCheck,
    title: 'For Security',
    text: 'Scan gate passes, log visitor entries and alert residents instantly',
    tint: 'bg-indigo-50 border-indigo-100',
    icon_tint: 'bg-indigo-100 text-indigo-600',
  },
  {
    icon: Users,
    title: 'For Committees',
    text: 'Notices, polls, meetings and reports that keep everyone informed',
    tint: 'bg-emerald-50 border-emerald-100',
    icon_tint: 'bg-emerald-100 text-emerald-600',
  },
];

export default function Roles() {
  return (
    <section className='bg-white py-20 sm:py-24'>
      <div className='mx-auto max-w-6xl px-5 sm:px-8'>
        <Reveal className='text-center'>
          <p className='font-mono text-[10px] font-semibold tracking-[0.2em] text-brand-500 uppercase'>
            Built for everyone
          </p>
          <h2 className='mt-3 font-display text-4xl font-bold tracking-tight text-slate-900 sm:text-5xl'>
            One Platform. Many Possibilities.
          </h2>
        </Reveal>

        <div className='mt-12 grid gap-4 sm:grid-cols-2 lg:grid-cols-5'>
          {roles.map((role, index) => (
            <Reveal key={role.title} delay={index * 70}>
              <div
                className={`h-full rounded-2xl border p-6 text-center transition-all duration-200 hover:-translate-y-1 hover:card-shadow ${role.tint}`}
              >
                <div
                  className={`mx-auto flex h-12 w-12 items-center justify-center rounded-xl ${role.icon_tint}`}
                >
                  <role.icon className='h-6 w-6' />
                </div>
                <h3 className='mt-4 font-display text-lg font-bold tracking-tight text-slate-900'>
                  {role.title}
                </h3>
                <p className='mt-2 text-sm leading-relaxed text-slate-600'>{role.text}</p>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}
