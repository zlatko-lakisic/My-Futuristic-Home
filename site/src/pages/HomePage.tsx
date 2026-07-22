import { AboutTheBuilder } from '../components/AboutTheBuilder'
import { BuildLogQuote } from '../components/BuildLogQuote'
import { DayInTheLife } from '../components/DayInTheLife'
import { Footer } from '../components/Footer'
import { GoDeeper } from '../components/GoDeeper'
import { Hero } from '../components/Hero'
import { MeetTheCast } from '../components/MeetTheCast'
import { Principles } from '../components/Principles'
import { RackElevation } from '../components/RackElevation'
import { SkipLink } from '../components/SkipLink'
import { WhatIsThis } from '../components/WhatIsThis'

export function HomePage() {
  return (
    <>
      <SkipLink />
      <Hero />
      <main id="main-content">
        <WhatIsThis />
        <DayInTheLife />
        <BuildLogQuote />
        <MeetTheCast />
        <RackElevation />
        <Principles />
        <GoDeeper />
        <AboutTheBuilder />
      </main>
      <Footer />
    </>
  )
}
