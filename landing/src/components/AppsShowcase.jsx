import { useState } from 'react';
import { Building2, ClipboardList, Home, ShieldCheck } from 'lucide-react';
import Reveal from './Reveal';

const apps = [
  {
    eyebrow: 'Owners & residents',
    name: 'CHS HUB Owner',
    icon: Home,
    screen: '/screens/owner_home_screen.png',
    ratio: '853/1844',
    device: 'phone',
    accent: 'bg-brand-500',
    chip: 'text-brand-600',
    text: 'Everything a resident needs, in one place. Pay maintenance and download the receipt, approve a visitor before they reach the lobby, raise a complaint and watch it move, and keep up with notices, polls and society documents. Book the clubhouse, list something on the marketplace, and see exactly what you owe and why.',
  },
  {
    eyebrow: 'Security & gate staff',
    name: 'CHS HUB Gatekeeper',
    icon: ShieldCheck,
    screen: '/screens/security_home_screen.png',
    ratio: '858/1834',
    device: 'phone',
    accent: 'bg-indigo-500',
    chip: 'text-indigo-600',
    text: 'Built for the person standing at the gate. Scan a gate-pass QR the moment a visitor arrives, log entries in and out, and push an instant alert to the resident so nobody waits. Staff and gatekeeper attendance is recorded in the same app, and it works in the language your gate staff are comfortable with.',
  },
  {
    eyebrow: 'Committee on the move',
    name: 'Secretary App',
    icon: ClipboardList,
    screen: '/screens/secretary-app.png',
    ratio: '858/1834',
    device: 'phone',
    accent: 'bg-blue-600',
    chip: 'text-blue-700',
    text: 'The back-office in your pocket. See collection and dues on a live dashboard, generate the month’s bills, record receipts and chase defaulters. Cashbook, expenses, ledger and vendor bills stay reconciled, while announcements, meetings, events and NOCs go out without opening a laptop.',
  },
  {
    eyebrow: 'Full committee console',
    name: 'chshub.co.in',
    icon: Building2,
    screen: '/screens/dashboard.png',
    ratio: '1536/1024',
    device: 'laptop',
    accent: 'bg-sky-600',
    chip: 'text-sky-700',
    text: 'Where the whole society is administered. Property, people, staff and vendor masters; finance from PDC and loans through to ledger and cashbook; and the reports an auditor actually asks for — income and expenditure, balance sheet, AGM pack and owner ledger. Import from Excel, export to PDF or XLSX.',
  },
];

function DeviceFrame({ src, name, device, ratio }) {
  const [failed, setFailed] = useState(false);

  if (failed) {
    return (
      <div className='flex aspect-[4/3] w-full items-center justify-center rounded-2xl border border-slate-200 bg-gradient-to-br from-slate-100 to-slate-200'>
        <span className='font-mono text-[10px] tracking-[0.16em] text-slate-400 uppercase'>
          {name} preview
        </span>
      </div>
    );
  }

  if (device === 'laptop') {
    return (
      <div className='group w-full'>
        <div className='rounded-t-2xl border border-slate-300/70 bg-slate-800 p-2 pb-0 card-shadow-lg transition-all duration-300 group-hover:-translate-y-1.5 group-hover:shadow-[0_36px_70px_-18px_rgba(23,31,43,0.45)]'>
          <div className='overflow-hidden rounded-t-lg bg-white'>
            <img
              src={src}
              alt={name + ' dashboard'}
              loading='lazy'
              onError={() => setFailed(true)}
              style={{ aspectRatio: ratio }}
              className='block w-full object-cover object-top'
            />
          </div>
        </div>
        <div className='mx-auto h-3 w-[106%] -translate-x-[2.8%] rounded-b-xl border border-t-0 border-slate-300/70 bg-slate-700' />
        <div className='mx-auto h-1 w-[64%] rounded-b-md bg-slate-400/40' />
      </div>
    );
  }

  return (
    <div className='group mx-auto w-[168px] sm:w-[196px]'>
      <div className='rounded-[1.9rem] border border-slate-300/70 bg-slate-800 p-[6px] card-shadow-lg transition-all duration-300 group-hover:-translate-y-2 group-hover:shadow-[0_36px_70px_-18px_rgba(23,31,43,0.45)]'>
        <div className='overflow-hidden rounded-[1.5rem] bg-white'>
          <img
            src={src}
            alt={name + ' home screen'}
            loading='lazy'
            onError={() => setFailed(true)}
            style={{ aspectRatio: ratio }}
            className='block w-full object-contain'
          />
        </div>
      </div>
    </div>
  );
}

export default function AppsShowcase() {
  return (
    <section id='apps' className='bg-white py-20 sm:py-28'>
      <div className='mx-auto max-w-6xl px-5 sm:px-8'>
        <Reveal className='text-center'>
          <p className='font-mono text-[10px] font-semibold tracking-[0.2em] text-brand-500 uppercase'>
            The platform
          </p>
          <h2 className='mt-3 font-display text-4xl font-bold tracking-tight text-slate-900 sm:text-5xl'>
            Four Apps, One Shared Record
          </h2>
          <p className='mx-auto mt-4 max-w-2xl text-base leading-relaxed text-slate-600'>
            Every app writes to the same society database. A payment taken on the Secretary app
            shows instantly in the owner&rsquo;s ledger, and a gate pass issued by a resident is on
            the gatekeeper&rsquo;s scanner before the visitor reaches the lobby.
          </p>
        </Reveal>

        <div className='mt-14 space-y-12 sm:space-y-16'>
          {apps.map((app, index) => {
            const imageFirst = index % 2 === 0;

            return (
              <Reveal key={app.name}>
                <div className='grid items-center gap-8 sm:gap-12 lg:grid-cols-2'>
                  <div className={`rounded-3xl bg-page p-6 sm:p-8 ${imageFirst ? '' : 'lg:order-2'}`}>
                    <DeviceFrame src={app.screen} name={app.name} device={app.device} ratio={app.ratio} />
                  </div>

                  <div className={imageFirst ? '' : 'lg:order-1'}>
                    <p
                      className={`font-mono text-[10px] font-semibold tracking-[0.2em] uppercase ${app.chip}`}
                    >
                      {app.eyebrow}
                    </p>
                    <h3 className='mt-3 flex items-center gap-3 font-display text-3xl font-bold tracking-tight text-slate-900 sm:text-4xl'>
                      <span
                        className={`flex h-10 w-10 items-center justify-center rounded-xl ${app.accent}`}
                      >
                        <app.icon className='h-5 w-5 text-white' />
                      </span>
                      {app.name}
                    </h3>
                    <p className='mt-5 text-base leading-relaxed text-slate-600'>{app.text}</p>
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
