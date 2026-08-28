import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { LogIn, Menu, X } from 'lucide-react';
import Logo from './Logo';

const links = [
  { label: 'Home', href: '#top' },
  { label: 'Features', href: '#features' },
  { label: 'Solutions', href: '#apps' },
  { label: 'How it works', href: '#how' },
  { label: 'FAQ', href: '#faq' },
  { label: 'Contact', href: '#contact' },
];

export default function Navbar() {
  const [scrolled, setScrolled] = useState(false);
  const [open, setOpen] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 8);
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  return (
    <header
      className={`sticky top-0 z-50 w-full border-b transition-all duration-200 ${
        scrolled
          ? 'border-slate-200 bg-white/92 backdrop-blur-md card-shadow'
          : 'border-transparent bg-white'
      }`}
    >
      <div className='mx-auto flex h-16 max-w-6xl items-center justify-between px-5 sm:px-8'>
        <Link to='/' aria-label='CHS HUB home'>
          <Logo size={36} />
        </Link>

        <nav className='hidden items-center gap-7 lg:flex'>
          {links.map((link) => (
            <a
              key={link.href}
              href={link.href}
              className='text-sm font-medium text-slate-600 transition-colors hover:text-brand-500'
            >
              {link.label}
            </a>
          ))}
        </nav>

        <a
          href='https://chshub.co.in/login'
          className='hidden items-center gap-2 rounded-[10px] border border-slate-300 px-4 py-2 text-sm font-semibold text-slate-700 transition-colors hover:border-brand-300 hover:bg-brand-50 hover:text-brand-600 lg:inline-flex'
        >
          <LogIn className='h-4 w-4' />
          Login
        </a>

        <button
          type='button'
          onClick={() => setOpen((v) => !v)}
          aria-label={open ? 'Close menu' : 'Open menu'}
          aria-expanded={open}
          className='rounded-[10px] p-2 text-slate-700 transition-colors hover:bg-slate-100 lg:hidden'
        >
          {open ? <X className='h-6 w-6' /> : <Menu className='h-6 w-6' />}
        </button>
      </div>

      {open && (
        <div className='border-t border-slate-200 bg-white lg:hidden'>
          <nav className='mx-auto flex max-w-6xl flex-col px-5 py-3 sm:px-8'>
            {links.map((link) => (
              <a
                key={link.href}
                href={link.href}
                onClick={() => setOpen(false)}
                className='rounded-[10px] px-2 py-3 text-sm font-medium text-slate-700 transition-colors hover:bg-brand-50 hover:text-brand-600'
              >
                {link.label}
              </a>
            ))}
            <a
              href='https://chshub.co.in/login'
              className='mt-3 rounded-[10px] bg-brand-500 px-4 py-2.5 text-center text-sm font-semibold text-white'
            >
              Login
            </a>
          </nav>
        </div>
      )}
    </header>
  );
}
