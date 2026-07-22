import { motion } from 'framer-motion'
import { ArrowDown } from 'lucide-react'
import { usePrefersReducedMotion } from '../hooks/usePrefersReducedMotion'
import { GitHubIcon } from './GitHubIcon'
import { HeroPicture } from './HeroPicture'
import { StatusLeds } from './StatusLeds'

export function Hero() {
  const reduced = usePrefersReducedMotion()

  const fade = (delay: number) =>
    reduced
      ? {}
      : {
          initial: { opacity: 0, y: 16 },
          animate: { opacity: 1, y: 0 },
          transition: { duration: 0.7, ease: [0.22, 1, 0.36, 1] as const, delay },
        }

  return (
    <header className="relative bg-night">
      <div
        aria-hidden="true"
        className="pointer-events-none relative w-full max-w-full"
        style={{
          maskImage:
            'linear-gradient(to bottom, #000 0%, #000 48%, rgba(0,0,0,0.65) 72%, transparent 100%)',
          WebkitMaskImage:
            'linear-gradient(to bottom, #000 0%, #000 48%, rgba(0,0,0,0.65) 72%, transparent 100%)',
        }}
      >
        <HeroPicture stem="hero-rack-house" fetchPriority="high" />
        <StatusLeds />
      </div>

      <div className="relative z-10 -mt-16 sm:-mt-24 md:-mt-32 lg:-mt-40">
        <div className="pointer-events-none absolute inset-0 bg-gradient-to-t from-night via-night/85 to-transparent" />

        <div className="relative mx-auto w-full max-w-5xl px-5 pb-16 pt-10 sm:px-8 sm:pb-20 sm:pt-12">
          <motion.p
            className="font-display text-sm font-medium tracking-[0.18em] text-amber uppercase"
            {...fade(0.05)}
          >
            My Futuristic Home
          </motion.p>

          <motion.h1
            className="font-display mt-4 max-w-3xl text-4xl leading-[1.08] font-semibold text-balance text-white sm:text-5xl md:text-6xl"
            {...fade(0.18)}
          >
            The house that runs itself.
          </motion.h1>

          <motion.p
            className="mt-5 max-w-xl text-base text-mist/90 sm:text-lg"
            {...fade(0.32)}
          >
            A real smart home, built like production infrastructure. Local first,
            private by design, powered by AI that lives in the rack downstairs.
          </motion.p>

          <motion.div className="mt-9 flex flex-wrap gap-3" {...fade(0.46)}>
            <a
              href="#day-in-the-life"
              className="inline-flex items-center gap-2 rounded-md bg-amber px-5 py-3 text-sm font-semibold text-night transition hover:bg-amber/90"
            >
              Take the tour
              <ArrowDown className="h-4 w-4" aria-hidden="true" />
            </a>
            <a
              href="https://github.com/zlatko-lakisic/My-Futuristic-Home"
              target="_blank"
              rel="noopener"
              className="inline-flex items-center gap-2 rounded-md border border-line bg-panel/60 px-5 py-3 text-sm font-semibold text-white backdrop-blur-sm transition hover:border-sky/40 hover:bg-panel"
            >
              <GitHubIcon className="h-4 w-4" />
              Explore the project on GitHub
            </a>
          </motion.div>
        </div>
      </div>
    </header>
  )
}
