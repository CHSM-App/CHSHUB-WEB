import { Mail, MapPin, Phone } from 'lucide-react';
import Logo from './Logo';

const columns = [
  {
    title: 'Quick Links',
    links: [
      { label: 'Home', href: '#top' },
      { label: 'Features', href: '#features' },
      { label: 'Solutions', href: '#apps' },
      { label: 'How it works', href: '#how' },
    ],
  },
  {
    title: 'Platform',
    links: [
      { label: 'Owner app', href: '#apps' },
      { label: 'Gatekeeper app', href: '#apps' },
      { label: 'Secretary app', href: '#apps' },
      { label: 'Web console', href: 'https://chshub.co.in/login' },
    ],
  },
  {
    title: 'Support',
    links: [
      { label: 'FAQ', href: '#faq' },
      { label: 'Book a demo', href: '#contact' },
      { label: 'Privacy policy', href: 'https://chshub.co.in/privacy-policy' },
      { label: 'Delete account', href: 'https://chshub.co.in/delete-account.html' },
    ],
  },
];

const contact = [
  { icon: Mail, label: 'support@vengurlatech.com', href: 'mailto:support@vengurlatech.com' },
  { icon: Phone, label: '+91 94222 29951', href: 'tel:+919422229951' },
  { icon: MapPin, label: 'Vengurla Tech, Maharashtra, India' },
];

export default function Footer() {
  return (
    <footer className='bg-slate-900'>
      <div className='mx-auto max-w-6xl px-5 py-14 sm:px-8'>
        <div className='grid gap-10 sm:grid-cols-2 lg:grid-cols-5'>
          <div className='lg:col-span-2'>
            <Logo size={38} tone='light' />
            <p className='mt-5 max-w-xs text-sm leading-relaxed text-white/50'>
              A complete housing society management platform — billing, dues, visitors, notices and
              audit-ready reports across web and mobile.
            </p>
          </div>

          {columns.map((column) => (
            <div key={column.title}>
              <p className='font-mono text-[9px] font-semibold tracking-[0.2em] text-white/40 uppercase'>
                {column.title}
              </p>
              <ul className='mt-4 space-y-2.5'>
                {column.links.map((link) => (
                  <li key={link.label}>
                    <a
                      href={link.href}
                      className='text-sm text-white/65 transition-colors hover:text-brand-400'
                    >
                      {link.label}
                    </a>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        <div className='mt-12 grid gap-4 border-t border-white/10 pt-8 sm:grid-cols-3'>
          {contact.map((item) => {
            const body = (
              <span className='flex items-start gap-2.5 text-sm text-white/60'>
                <item.icon className='mt-0.5 h-4 w-4 shrink-0 text-brand-400' />
                {item.label}
              </span>
            );
            return item.href ? (
              <a key={item.label} href={item.href} className='transition-colors hover:text-white'>
                {body}
              </a>
            ) : (
              <div key={item.label}>{body}</div>
            );
          })}
        </div>

        <div className='mt-8 flex flex-col gap-2 border-t border-white/10 pt-6 sm:flex-row sm:items-center sm:justify-between'>
          <p className='text-xs text-white/40'>
            Copyright &copy; {new Date().getFullYear()} chsHub.co.in — a Vengurla Tech product.
          </p>
          <p className='font-mono text-[9px] tracking-[0.16em] text-white/30 uppercase'>
            Made for co-operative housing societies
          </p>
        </div>
      </div>
    </footer>
  );
}
