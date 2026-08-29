import { useState } from 'react';
import { Plus } from 'lucide-react';
import Reveal from './Reveal';

const faqs = [
  {
    q: 'Do residents have to pay to use the apps?',
    a: 'No. The Owner and Gatekeeper apps are free for your residents and security staff. The society subscribes once and every flat is covered.',
  },
  {
    q: 'Can we move our existing data across?',
    a: 'Yes. Flats, owners, tenants, buildings and parking import from Excel. If you are moving off the older Society software, talk to us about bringing your historical bills and receipts across.',
  },
  {
    q: 'How do residents pay maintenance?',
    a: 'Online from the Owner app, or by cash, cheque or bank transfer recorded by the committee. Post-dated cheques are recorded and tracked until they clear.',
  },
  {
    q: 'Does it work for a village or panchayat?',
    a: 'Yes. The console has a separate Village mode for houses, residents, house tax, water tax and scheme-wise bill runs.',
  },
  {
    q: 'Is our society data secure?',
    a: 'Your society is a separate tenant on the committee console, and the console takes the society from your sign-in, not from the page you are on. Each app also shows only the screens its users need — the gatekeeper app has no finance screens at all. Read our privacy policy for the full detail.',
  },
  {
    q: 'What languages are supported?',
    a: 'The Gatekeeper app ships in English, Hindi, Marathi, Bengali and Tamil, so your gate staff can work in the language they are comfortable with. The Owner and Secretary apps are in English today.',
  },
];

export default function Faq() {
  const [open, setOpen] = useState(0);

  return (
    <section id='faq' className='bg-white py-20 sm:py-28'>
      <div className='mx-auto max-w-3xl px-5 sm:px-8'>
        <Reveal className='text-center'>
          <p className='font-mono text-[10px] font-semibold tracking-[0.2em] text-brand-500 uppercase'>
            Questions
          </p>
          <h2 className='mt-3 font-display text-4xl font-bold tracking-tight text-slate-900 sm:text-5xl'>
            Before You Ask
          </h2>
        </Reveal>

        <div className='mt-12 space-y-3'>
          {faqs.map((faq, index) => {
            const isOpen = open === index;
            return (
              <Reveal key={faq.q} delay={index * 50}>
                <div
                  className={`overflow-hidden rounded-xl border transition-colors duration-200 ${
                    isOpen ? 'border-brand-200 bg-brand-50/40' : 'border-slate-200 bg-white'
                  }`}
                >
                  <button
                    type='button'
                    onClick={() => setOpen(isOpen ? -1 : index)}
                    aria-expanded={isOpen}
                    className='flex w-full items-center justify-between gap-6 px-5 py-4 text-left'
                  >
                    <span className='text-[15px] font-semibold text-slate-900'>{faq.q}</span>
                    <Plus
                      className={`h-4.5 w-4.5 shrink-0 transition-all duration-300 ${
                        isOpen ? 'rotate-45 text-brand-500' : 'text-slate-400'
                      }`}
                    />
                  </button>
                  <div
                    className={`grid transition-all duration-300 ease-out ${
                      isOpen ? 'grid-rows-[1fr] opacity-100' : 'grid-rows-[0fr] opacity-0'
                    }`}
                  >
                    <div className='overflow-hidden'>
                      <p className='px-5 pb-4 text-sm leading-relaxed text-slate-600'>{faq.a}</p>
                    </div>
                  </div>
                </div>
              </Reveal>
            );
          })}
        </div>
      </div>
    </section>
  );
}
