export default function Logo({ size = 40, showWordmark = true, tone = 'dark' }) {
  const title = tone === 'light' ? 'text-white' : 'text-brand-500';
  const sub = tone === 'light' ? 'text-white/60' : 'text-slate-500';

  return (
    <div className='flex items-center gap-2.5'>
      <div
        className='flex shrink-0 flex-col items-center justify-center bg-brand-500 font-display leading-[0.85] font-bold text-white'
        style={{
          width: size,
          height: size,
          borderRadius: size * 0.22,
          fontSize: size * 0.3,
        }}
      >
        <span>CHS</span>
        <span>HUB</span>
      </div>
      {showWordmark && (
        <div className='leading-tight'>
          <div className={`font-display text-lg font-bold tracking-wide uppercase ${title}`}>
            Society
          </div>
          <div className={`font-mono text-[9px] tracking-[0.18em] uppercase ${sub}`}>
            Management
          </div>
        </div>
      )}
    </div>
  );
}
