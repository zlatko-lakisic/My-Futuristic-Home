import { Link } from 'react-router-dom'
import { systems } from '../content/systems'
import { systemIcon } from './systems/iconMap'
import { SectionReveal } from './SectionReveal'

export function MeetTheCast() {
  return (
    <section id="cast" className="mx-auto max-w-6xl px-5 py-20 sm:px-8 sm:py-28">
      <SectionReveal>
        <p className="font-mono text-xs tracking-[0.16em] text-sky uppercase">Meet the cast</p>
        <h2 className="font-display mt-3 max-w-2xl text-3xl font-semibold text-white sm:text-4xl">
          Nine roles. One house.
        </h2>
        <p className="mt-4 max-w-2xl text-mist/85">
          Each part has a job. Together they behave like a small production system
          that happens to live in a closet.
        </p>
      </SectionReveal>

      <ul className="mt-12 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {systems.map((member, i) => {
          const Icon = systemIcon(member.icon)
          return (
            <li key={member.slug}>
              <SectionReveal delay={i * 0.03}>
                <Link
                  to={`/systems/${member.slug}`}
                  className="group flex h-full flex-col rounded-lg border border-line bg-panel p-5 transition hover:border-amber/50 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-amber"
                >
                  <Icon className="h-5 w-5 text-amber" aria-hidden="true" strokeWidth={1.75} />
                  <h3 className="font-display mt-4 text-lg font-semibold text-white">
                    {member.name}
                  </h3>
                  <p className="mt-2 flex-1 text-[15px] leading-relaxed text-mist/85">
                    {member.tagline}
                  </p>
                  <p className="font-mono mt-4 text-[11px] leading-snug tracking-wide text-sky/80">
                    {member.underTheHood.join(' + ')}
                  </p>
                  <span className="mt-4 self-end text-sm font-medium text-amber/70 transition group-hover:text-amber group-hover:opacity-100 group-focus-visible:text-amber max-sm:opacity-100 sm:opacity-0 sm:group-hover:opacity-100 sm:group-focus-visible:opacity-100">
                    Explore →
                  </span>
                </Link>
              </SectionReveal>
            </li>
          )
        })}
      </ul>
    </section>
  )
}
