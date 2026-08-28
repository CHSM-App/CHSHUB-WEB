import AppsShowcase from '../components/AppsShowcase';
import CtaSection from '../components/CtaSection';
import Faq from '../components/Faq';
import Features from '../components/Features';
import Footer from '../components/Footer';
import Hero from '../components/Hero';
import HowItWorks from '../components/HowItWorks';
import Navbar from '../components/Navbar';
import Roles from '../components/Roles';
import ShowcaseBand from '../components/ShowcaseBand';
import StatsBar from '../components/StatsBar';

export default function Home() {
  return (
    <div className='min-h-screen bg-white'>
      <Navbar />
      <main>
        <Hero />
        <StatsBar />
        <Roles />
        <Features />
        <ShowcaseBand />
        <AppsShowcase />
        <HowItWorks />
        <Faq />
        <CtaSection />
      </main>
      <Footer />
    </div>
  );
}
