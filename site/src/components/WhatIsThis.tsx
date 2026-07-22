import { SectionReveal } from './SectionReveal'

export function WhatIsThis() {
  return (
    <section id="what-is-this" className="mx-auto max-w-3xl px-5 py-20 sm:px-8 sm:py-28">
      <SectionReveal>
        <p className="font-mono text-xs tracking-[0.16em] text-sky uppercase">What is this?</p>
        <h2 className="font-display mt-3 text-3xl font-semibold text-white sm:text-4xl">
          A house that thinks locally.
        </h2>
      </SectionReveal>

      <div className="mt-10 space-y-6 text-mist/90">
        <SectionReveal delay={0.05}>
          <p>
            My Futuristic Home is a fully self-hosted smart home. Cameras, watering,
            networking, storage, and automation live downstairs in the rack. The parts
            that decide, record, and route all run on hardware inside the house.
          </p>
        </SectionReveal>
        <SectionReveal delay={0.1}>
          <p>
            It exists for three reasons: privacy, reliability, and the quiet satisfaction
            of building something that works. The stack looks like a small datacenter
            because that is how you keep a home steady for years.
          </p>
        </SectionReveal>
        <SectionReveal delay={0.15}>
          <p>
            One rule shapes every decision. The decision layer never leaves the house.
            Where a device forces a cloud, it gets a narrow job and no keys: a guest with
            a task, not a shared trust model.
          </p>
        </SectionReveal>
      </div>
    </section>
  )
}
