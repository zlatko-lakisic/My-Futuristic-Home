import { DayInTheLife } from '../components/DayInTheLife'
import { Footer } from '../components/Footer'
import { GoDeeper } from '../components/GoDeeper'
import { Hero } from '../components/Hero'
import { MeetTheCast } from '../components/MeetTheCast'
import { Principles } from '../components/Principles'
import { RackElevation } from '../components/RackElevation'
import { WhatIsThis } from '../components/WhatIsThis'

export function HomePage() {
  return (
    <>
      <a
        href="#what-is-this"
        className="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 focus:z-50 focus:rounded-md focus:bg-amber focus:px-4 focus:py-2 focus:text-sm focus:font-semibold focus:text-night"
      >
        Skip to content
      </a>
      <Hero />
      <main>
        <WhatIsThis />
        <DayInTheLife />
        <MeetTheCast />
        <RackElevation />
        <Principles />
        <GoDeeper />
      </main>
      <Footer />
    </>
  )
}
