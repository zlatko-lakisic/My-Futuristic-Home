import { Link } from 'react-router-dom'
import { SectionReveal } from './SectionReveal'

export function BuildLogQuote() {
  return (
    <section
      id="build-log"
      className="border-y border-line bg-night py-20 sm:py-28"
      aria-labelledby="build-log-heading"
    >
      <div className="mx-auto max-w-3xl px-5 sm:px-8">
        <SectionReveal>
          <p className="font-mono text-xs tracking-[0.16em] text-amber uppercase">
            From the build log
          </p>
          <div className="mt-5 h-px w-12 bg-amber" aria-hidden="true" />
          <blockquote className="mt-8">
            <p
              id="build-log-heading"
              className="font-display text-2xl leading-snug font-semibold text-balance text-white sm:text-3xl md:text-[2rem]"
            >
              An LLM once silently turned 60 square meters into roughly 12,600 square
              feet. That is why every watering number is checked by code before a valve
              opens.
            </p>
            <p className="mt-6 text-base text-mist/85">
              Deterministic code for math. The model for judgment.
            </p>
          </blockquote>
          <Link
            to="/systems/garden"
            className="mt-8 inline-flex text-sm font-semibold text-sky transition hover:text-white focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-amber"
          >
            How the garden decides →
          </Link>
        </SectionReveal>
      </div>
    </section>
  )
}
