import { CreditCard, FileSpreadsheet, Settings2, UserPlus } from 'lucide-react';
import Reveal from './Reveal';

const steps = [
  {
    step: 'Step 1',
    icon: FileSpreadsheet,
    title: 'Register Society',
    text: 'Upload your existing flat, owner and tenant list from Excel. Buildings, wings and charge heads are set up in the same pass.',
    tint: 'bg-brand-50 text-brand-600',
  },
  {
    step: 'Step 2',
    icon: Settings2,
    title: 'Configure & Setup',
    text: 'Add members, flats and charge heads. Set up your billing cycle and payment options.',
    tint: 'bg-amber-50 text-amber-600',
  },
  {
    step: 'Step 3',
    icon: UserPlus,
    title: 'Invite Residents & Staff',
    text: 'Residents sign in to the Owner app with an OTP, gatekeepers get the Gatekeeper app, the committee gets the console.',
    tint: 'bg-sky-50 text-sky-600',
  },
  {
    step: 'Step 4',
    icon: CreditCard,
    title: 'Run Your First Bill Cycle',
    text: 'Generate bills for every flat, collect online or by cheque, and issue receipts — dues update themselves.',
    tint: 'bg-emerald-50 text-emerald-600',
  },
];

export default function HowItWorks() {
  return (
    <section id='how' className='border-y border-slate-200 bg-page py-20 sm:py-28'>
      <div className='mx-auto max-w-6xl px-5 sm:px-8'>
        <Reveal className='text-center'>
          <p className='font-mono text-[10px] font-semibold tracking-[0.2em] text-brand-500 uppercase'>
            Simple steps
          </p>
          <h2 className='mt-3 font-display text-4xl font-bold tracking-tight text-slate-900 sm:text-5xl'>
            How CHS HUB Works
          </h2>
          <p className='mx-auto mt-4 max-w-2xl text-base leading-relaxed text-slate-600'>
            Most societies move off their spreadsheets and legacy software within the first billing
            cycle.
          </p>
        </Reveal>

        <div className='relative mt-14'>
          <div
            aria-hidden='true'
            className='pointer-events-none absolute top-7 right-[12%] left-[12%] hidden h-px bg-gradient-to-r from-brand-200 via-slate-300 to-brand-200 lg:block'
          />

          <div className='grid gap-10 sm:grid-cols-2 lg:grid-cols-4 lg:gap-6'>
            {steps.map((item, index) => (
              <Reveal key={item.step} delay={index * 100} className='relative text-center'>
                <div
                  className={`mx-auto flex h-14 w-14 items-center justify-center rounded-2xl border-4 border-page ${item.tint}`}
                >
                  <item.icon className='h-6 w-6' />
                </div>
                <p className='mt-4 font-mono text-[10px] font-semibold tracking-[0.16em] text-brand-500 uppercase'>
                  {item.step}
                </p>
                <h3 className='mt-1.5 font-display text-lg font-bold tracking-tight text-slate-900'>
                  {item.title}
                </h3>
                <p className='mt-2 text-sm leading-relaxed text-slate-600'>{item.text}</p>
              </Reveal>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
