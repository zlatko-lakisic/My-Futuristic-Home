import { motion } from 'framer-motion'
import { ArrowDown } from 'lucide-react'
import { usePrefersReducedMotion } from '../hooks/usePrefersReducedMotion'
import { GitHubIcon } from './GitHubIcon'
import { StatusLeds } from './StatusLeds'

function NightHouse() {
  return (
    <svg
      aria-hidden="true"
      className="absolute inset-0 h-full w-full"
      viewBox="0 0 1440 900"
      preserveAspectRatio="xMidYMid slice"
      fill="none"
    >
      <defs>
        <linearGradient id="skyGrad" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#151b2e" />
          <stop offset="55%" stopColor="#0e1220" />
          <stop offset="100%" stopColor="#0a0d16" />
        </linearGradient>
        <linearGradient id="hillGrad" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#12182a" />
          <stop offset="100%" stopColor="#0a0d16" />
        </linearGradient>
        <radialGradient id="porchGlow" cx="50%" cy="55%" r="35%">
          <stop offset="0%" stopColor="#f5a83c" stopOpacity="0.22" />
          <stop offset="100%" stopColor="#f5a83c" stopOpacity="0" />
        </radialGradient>
      </defs>

      <rect width="1440" height="900" fill="url(#skyGrad)" />

      {/* faint stars */}
      <g fill="#c7cdda" opacity="0.35">
        <circle cx="180" cy="90" r="1.2" />
        <circle cx="320" cy="140" r="0.9" />
        <circle cx="510" cy="70" r="1.1" />
        <circle cx="780" cy="110" r="0.8" />
        <circle cx="980" cy="55" r="1.3" />
        <circle cx="1180" cy="130" r="0.9" />
        <circle cx="1320" cy="80" r="1" />
        <circle cx="640" cy="160" r="0.7" />
      </g>

      <ellipse cx="720" cy="620" rx="420" ry="180" fill="url(#porchGlow)" />

      {/* ground */}
      <path
        d="M0 720 C 220 680, 420 700, 720 690 C 1020 680, 1220 710, 1440 690 L 1440 900 L 0 900 Z"
        fill="url(#hillGrad)"
      />

      {/* house silhouette */}
      <g transform="translate(520 380)">
        <path
          d="M40 180 L40 90 L200 20 L360 90 L360 180 Z"
          fill="#12182a"
          stroke="#2a3148"
          strokeWidth="1.5"
        />
        <rect x="60" y="100" width="280" height="160" fill="#101628" stroke="#2a3148" strokeWidth="1.5" />
        {/* lit windows */}
        <rect x="95" y="130" width="42" height="52" rx="2" fill="#f5a83c" opacity="0.85" />
        <rect x="175" y="130" width="42" height="52" rx="2" fill="#f5a83c" opacity="0.7" />
        <rect x="255" y="130" width="42" height="52" rx="2" fill="#7fb4d9" opacity="0.55" />
        {/* door */}
        <rect x="175" y="200" width="50" height="60" rx="2" fill="#171d30" stroke="#2a3148" />
        <circle cx="215" cy="232" r="2" fill="#f5a83c" />
        {/* chimney */}
        <rect x="290" y="45" width="28" height="48" fill="#12182a" stroke="#2a3148" strokeWidth="1.5" />
      </g>
    </svg>
  )
}

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
    <header className="relative flex min-h-[100svh] flex-col justify-end overflow-hidden">
      <NightHouse />
      <StatusLeds />

      <div className="pointer-events-none absolute inset-0 bg-gradient-to-t from-night via-night/55 to-transparent" />

      <div className="relative z-10 mx-auto w-full max-w-5xl px-5 pb-16 pt-28 sm:px-8 sm:pb-20">
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
    </header>
  )
}
