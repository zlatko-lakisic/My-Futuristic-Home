import { useRef } from 'react'
import { motion, useScroll, useTransform } from 'framer-motion'
import { usePrefersReducedMotion } from '../hooks/usePrefersReducedMotion'
import { SectionReveal } from './SectionReveal'

type Stop = {
  time: string
  title: string
  body: string
  sky: string
}

const STOPS: Stop[] = [
  {
    time: '05:40',
    title: 'Dawn',
    body: 'The garden AI checks the weather forecast and decides this morning\'s watering. Rain coming later? It skips the cycle.',
    sky: '#3a4a6a',
  },
  {
    time: '08:15',
    title: 'Morning',
    body: 'Cameras watch the driveway. The AI on the local GPU knows the difference between a delivery truck and a passing car, so only the truck gets a notification.',
    sky: '#5a7a9a',
  },
  {
    time: '10:05',
    title: 'Late morning',
    body: 'A gate at the edge of the yard opens. A long range sensor tells the house, the nearest camera takes a burst of snapshots, and an AI describes who is walking toward the home. If it is a person, a summary lands on our phones before they reach the door.',
    sky: '#6a88a8',
  },
  {
    time: '11:50',
    title: 'Midday',
    body: 'A stubborn device stops responding somewhere in the house. A power watchdog notices, cycles its outlet, and it comes back before anyone knew it was gone.',
    sky: '#6a8aaa',
  },
  {
    time: '14:30',
    title: 'Afternoon',
    body: 'Every event in the house flows through a tiny message broker the size of a credit card. Millions of messages, one quiet board.',
    sky: '#4a6080',
  },
  {
    time: '18:45',
    title: 'Dusk',
    body: 'The garden AI runs its evening pass. A local language model, running on hardware in the rack, reasons about soil, weather, and season, then a piece of deterministic code validates every number before a single valve opens.',
    sky: '#8a5a3a',
  },
  {
    time: '23:10',
    title: 'Night',
    body: 'Recordings stream over a 10 gigabit link to storage built by hand. The house keeps watch so nobody else has to.',
    sky: '#1a2238',
  },
]

export function DayInTheLife() {
  const ref = useRef<HTMLElement>(null)
  const reduced = usePrefersReducedMotion()
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ['start end', 'end start'],
  })

  const bg = useTransform(
    scrollYProgress,
    [0, 0.14, 0.28, 0.42, 0.56, 0.72, 0.88],
    STOPS.map((s) => s.sky),
  )

  return (
    <section
      id="day-in-the-life"
      ref={ref}
      className="relative overflow-hidden py-20 sm:py-28"
    >
      {reduced ? (
        <div
          aria-hidden="true"
          className="absolute inset-0"
          style={{
            background:
              'linear-gradient(180deg, #3a4a6a 0%, #5a7a9a 18%, #6a88a8 32%, #6a8aaa 48%, #8a5a3a 72%, #1a2238 100%)',
          }}
        />
      ) : (
        <motion.div aria-hidden="true" className="absolute inset-0" style={{ backgroundColor: bg }} />
      )}
      <div
        aria-hidden="true"
        className="absolute inset-0 bg-gradient-to-b from-night/70 via-night/45 to-night/80"
      />

      <div className="relative z-10 mx-auto max-w-3xl px-5 sm:px-8">
        <SectionReveal>
          <p className="font-mono text-xs tracking-[0.16em] text-amber uppercase">
            A day in the life
          </p>
          <h2 className="font-display mt-3 text-3xl font-semibold text-white sm:text-4xl">
            Twenty-four hours of quiet work.
          </h2>
          <p className="mt-4 max-w-2xl text-mist/85">
            Scroll through a day in the house. Each stop is a moment the system
            acts on its own, before anyone asks it to.
          </p>
        </SectionReveal>

        <ol className="relative mt-14 space-y-0">
          <div
            aria-hidden="true"
            className="absolute top-2 bottom-2 left-[11px] w-px bg-white/15 sm:left-[15px]"
          />

          {STOPS.map((stop, i) => (
            <li key={stop.title} className="relative pl-10 sm:pl-14">
              <SectionReveal delay={i * 0.04}>
                <div className="absolute top-1.5 left-0 flex h-6 w-6 items-center justify-center sm:h-8 sm:w-8">
                  <span className="h-2.5 w-2.5 rounded-full bg-amber shadow-[0_0_12px_rgba(245,168,60,0.55)]" />
                </div>

                <article className="pb-12 last:pb-0">
                  <div className="flex flex-wrap items-baseline gap-x-3 gap-y-1">
                    <span className="font-mono text-xs tracking-wider text-sky">
                      {stop.time}
                    </span>
                    <h3 className="font-display text-xl font-semibold text-white sm:text-2xl">
                      {stop.title}
                    </h3>
                  </div>
                  <p className="mt-3 max-w-xl text-[17px] text-mist/90">{stop.body}</p>
                </article>
              </SectionReveal>
            </li>
          ))}
        </ol>
      </div>
    </section>
  )
}
