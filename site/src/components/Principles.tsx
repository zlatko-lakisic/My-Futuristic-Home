import { SectionReveal } from './SectionReveal'

const PRINCIPLES = [
  {
    title: 'Local first',
    body: 'The cloud is a guest, not a landlord. Critical control stays on hardware you can touch.',
  },
  {
    title: 'AI for judgment, code for math',
    body: 'Language models can reason about weather and context. Deterministic code validates every number before a valve opens.',
  },
  {
    title: 'Segment everything',
    body: 'A smart bulb should never meet a server. Networks are split by role so one bad gadget cannot wander.',
  },
  {
    title: 'Heal before you page',
    body: 'Systems should notice silence, recover themselves, and leave humans out of the loop until it matters.',
  },
]

export function Principles() {
  return (
    <section id="principles" className="mx-auto max-w-5xl px-5 py-20 sm:px-8 sm:py-28">
      <SectionReveal>
        <p className="font-mono text-xs tracking-[0.16em] text-sky uppercase">The principles</p>
        <h2 className="font-display mt-3 text-3xl font-semibold text-white sm:text-4xl">
          Hobby energy. Production discipline.
        </h2>
      </SectionReveal>

      <ol className="mt-12 grid gap-6 sm:grid-cols-2">
        {PRINCIPLES.map((item, i) => (
          <li key={item.title}>
            <SectionReveal delay={i * 0.05}>
              <article className="h-full border-l-2 border-amber/70 pl-5">
                <h3 className="font-display text-xl font-semibold text-white">{item.title}</h3>
                <p className="mt-2 text-[16px] text-mist/85">{item.body}</p>
              </article>
            </SectionReveal>
          </li>
        ))}
      </ol>
    </section>
  )
}
