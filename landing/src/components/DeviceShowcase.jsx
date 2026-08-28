import { useState } from 'react';

// Screenshots live in landing/public/screens/ so they can be dropped in without
// touching code. If one is missing the frame falls back to a tinted panel
// instead of showing a broken image.
const DASHBOARD_SRC = '/screens/dashboard.png';
const OWNER_SRC = '/screens/owner_home_screen.png';

function Screen({ src, alt, className, fallback, children }) {
  const [failed, setFailed] = useState(false);

  if (failed) {
    return <div className={`${className} ${fallback}`}>{children}</div>;
  }

  return (
    <img
      src={src}
      alt={alt}
      loading='lazy'
      onError={() => setFailed(true)}
      className={className}
    />
  );
}

export default function DeviceShowcase() {
  return (
    <div className='relative pr-[16%] sm:pr-[18%] lg:-ml-6 lg:pr-[20%]'>
      {/* laptop — sits left, leaving room at the right for the phone to overlap */}
      <div className='relative w-full'>
        <div className='rounded-t-2xl border border-slate-300/70 bg-slate-800 p-1.5 pb-0 shadow-[0_30px_70px_-24px_rgba(23,31,43,0.4)] sm:p-2'>
          <div className='overflow-hidden rounded-t-lg bg-white'>
            <Screen
              src={DASHBOARD_SRC}
              alt='CHS HUB committee dashboard showing the maintenance tracker, dues and recent activity'
              className='block aspect-[16/10] w-full object-cover object-top'
              fallback='flex items-center justify-center bg-gradient-to-br from-slate-100 to-slate-200 text-xs text-slate-400'
            >
              Dashboard preview
            </Screen>
          </div>
        </div>
        <div className='mx-auto h-3 w-[108%] -translate-x-[3.7%] rounded-b-xl border border-t-0 border-slate-300/70 bg-slate-700' />
        <div className='mx-auto h-1 w-[70%] rounded-b-md bg-slate-400/40' />
      </div>

      {/* phone stands to the right, overlapping the laptop's edge */}
      <div className='absolute right-0 -bottom-4 w-[29%] animate-float sm:-bottom-6 sm:w-[30%]'>
        <div className='rounded-[1.4rem] border border-slate-300/70 bg-slate-800 p-[5px] shadow-[0_28px_56px_-16px_rgba(23,31,43,0.55)] sm:rounded-[1.7rem] sm:p-[6px]'>
          <div className='relative overflow-hidden rounded-[1.05rem] bg-white sm:rounded-[1.3rem]'>
            <Screen
              src={OWNER_SRC}
              alt='CHS HUB Owner app home screen'
              style={{ aspectRatio: '853/1844' }}
              className='block w-full object-contain'
              fallback='bg-gradient-to-b from-brand-500 to-brand-700'
            />
          </div>
        </div>
      </div>
    </div>
  );
}
