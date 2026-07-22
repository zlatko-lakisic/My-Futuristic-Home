import { SectionReveal } from './SectionReveal'

export function AboutTheBuilder() {
  return (
    <section
      id="about-the-builder"
      className="mx-auto max-w-3xl px-5 py-20 sm:px-8 sm:py-28"
      aria-labelledby="about-builder-heading"
    >
      <SectionReveal>
        <p className="font-mono text-xs tracking-[0.16em] text-sky uppercase">
          About the builder
        </p>
        <h2
          id="about-builder-heading"
          className="font-display mt-3 text-3xl font-semibold text-white sm:text-4xl"
        >
          Same craft, smaller building.
        </h2>
        <div className="mt-8 space-y-5 text-mist/90">
          <p>
            Two decades of enterprise architecture taught the same lessons this house
            now runs on: clear boundaries, local control, and systems you can explain
            when they misbehave.
          </p>
          <p>
            Applying those principles at home is not a hobby diversion. It is a way to
            keep the craft honest, because a house will not forgive a clever design that
            fails at dawn.
          </p>
          <p>
            If you want the professional trail, it is on{' '}
            <a
              href="https://www.linkedin.com/in/zlatko-lakisic/"
              target="_blank"
              rel="noopener"
              className="font-medium text-sky transition hover:text-white focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-amber"
            >
              LinkedIn
            </a>
            . The source of truth for this project lives on{' '}
            <a
              href="https://github.com/zlatko-lakisic"
              target="_blank"
              rel="noopener"
              className="font-medium text-sky transition hover:text-white focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-amber"
            >
              GitHub
            </a>
            .
          </p>
        </div>
      </SectionReveal>
    </section>
  )
}
