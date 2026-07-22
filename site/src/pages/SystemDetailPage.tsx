import { useEffect } from 'react'
import { Link, useParams } from 'react-router-dom'
import { ArrowRight } from 'lucide-react'
import { getNextSystem, getSystem, type DiagramStep } from '../content/systems'
import { systemIcon } from '../components/systems/iconMap'
import { SectionReveal } from '../components/SectionReveal'
import { Footer } from '../components/Footer'
import { HeroPicture } from '../components/HeroPicture'
import { SkipLink } from '../components/SkipLink'
import { SystemSwitcher } from '../components/SystemSwitcher'
import { NotFoundPage } from './NotFoundPage'

function FlowDiagram({ steps }: { steps: DiagramStep[] }) {
  return (
    <ol className="mt-8 flex flex-col gap-3 sm:flex-row sm:items-stretch sm:gap-2">
      {steps.map((step, i) => (
        <li key={step.label} className="flex flex-1 items-stretch gap-2">
          <div className="flex flex-1 flex-col justify-center rounded-lg border border-line bg-panel px-4 py-3">
            <span className="font-mono text-[10px] tracking-[0.14em] text-sky uppercase">
              {String(i + 1).padStart(2, '0')}
            </span>
            <span className="font-display mt-1 text-base font-semibold text-white">
              {step.label}
            </span>
            {step.detail ? (
              <span className="mt-1 text-sm text-mist/70">{step.detail}</span>
            ) : null}
          </div>
          {i < steps.length - 1 ? (
            <span
              className="font-mono hidden items-center text-amber/70 sm:flex"
              aria-hidden="true"
            >
              →
            </span>
          ) : null}
        </li>
      ))}
    </ol>
  )
}

export function SystemDetailPage() {
  const { slug = '' } = useParams()
  const system = getSystem(slug)

  useEffect(() => {
    if (!system) return
    const prev = document.title
    document.title = `${system.name}, My Futuristic Home`
    let meta = document.querySelector('meta[name="description"]')
    const prevDesc = meta?.getAttribute('content') ?? ''
    if (!meta) {
      meta = document.createElement('meta')
      meta.setAttribute('name', 'description')
      document.head.appendChild(meta)
    }
    meta.setAttribute('content', system.metaDescription)
    return () => {
      document.title = prev
      meta?.setAttribute('content', prevDesc)
    }
  }, [system])

  if (!system) {
    return <NotFoundPage />
  }

  const Icon = systemIcon(system.icon)
  const next = getNextSystem(system.slug)

  return (
    <div className="min-h-svh bg-night">
      <SkipLink />
      <div className="relative z-20 border-b border-line bg-panel/50 backdrop-blur-sm">
        <div className="mx-auto flex max-w-5xl items-center gap-4 px-5 py-4 sm:px-8">
          <Link
            to="/"
            className="shrink-0 text-sm font-medium text-mist/90 transition hover:text-amber focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-amber"
          >
            ← Back to the house
          </Link>
          <SystemSwitcher currentSlug={system.slug} />
        </div>
      </div>

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
          <HeroPicture stem={`hero-${system.slug}`} fetchPriority="high" />
        </div>

        <div className="relative z-10 -mt-16 sm:-mt-24 md:-mt-32 lg:-mt-40">
          <div className="pointer-events-none absolute inset-0 bg-gradient-to-t from-night via-night/85 to-transparent" />

          <div className="relative mx-auto w-full max-w-5xl px-5 pb-12 pt-10 sm:px-8 sm:pb-16 sm:pt-12">
            <SectionReveal>
              <Icon className="h-7 w-7 text-amber" strokeWidth={1.75} aria-hidden="true" />
              <h1 className="font-display mt-5 max-w-3xl text-3xl font-semibold text-white sm:text-4xl md:text-5xl">
                {system.name}
              </h1>
              <p className="mt-4 max-w-2xl text-lg text-mist/90">{system.tagline}</p>
              <ul className="mt-6 flex flex-wrap gap-2">
                {system.underTheHood.map((chip) => (
                  <li
                    key={chip}
                    className="font-mono rounded-md border border-line bg-panel/80 px-2.5 py-1 text-[11px] tracking-wide text-sky/90 backdrop-blur-sm"
                  >
                    {chip}
                  </li>
                ))}
              </ul>
            </SectionReveal>
          </div>
        </div>
      </header>

      <main id="main-content" className="mx-auto max-w-3xl px-5 py-14 sm:px-8 sm:py-20">
        <SectionReveal>
          <h2 className="font-display text-2xl font-semibold text-white">What it does</h2>
          <div className="mt-5 space-y-4 text-mist/90">
            {system.whatItDoes.map((p) => (
              <p key={p.slice(0, 48)}>{p}</p>
            ))}
          </div>
        </SectionReveal>

        <SectionReveal className="mt-14">
          <h2 className="font-display text-2xl font-semibold text-white">How it works</h2>
          <div className="mt-5 space-y-4 text-mist/90">
            {system.howItWorks.map((p) => (
              <p key={p.slice(0, 48)}>{p}</p>
            ))}
          </div>
          {system.diagram ? <FlowDiagram steps={system.diagram} /> : null}
        </SectionReveal>

        {system.rackUnits ? (
          <SectionReveal className="mt-14">
            <h2 className="font-display text-2xl font-semibold text-white">Rack elevation</h2>
            <p className="mt-3 text-mist/80">
              Full model parade for the 9U wall rack. Anchors land on storage and compute bays.
            </p>
            <ul className="mt-8 space-y-2">
              {system.rackUnits.map((unit) => {
                const anchorId =
                  unit.anchor === 'storage' && unit.u === 4
                    ? 'storage'
                    : unit.anchor === 'compute' && unit.u === 2
                      ? 'compute'
                      : undefined
                return (
                  <li
                    key={unit.u}
                    id={anchorId}
                    className="scroll-mt-24 overflow-hidden rounded-lg border border-line bg-panel"
                  >
                    <div className="flex items-stretch">
                      <span className="font-mono flex w-14 shrink-0 items-center justify-center border-r border-line bg-night/80 text-xs text-amber">
                        U{unit.u}
                      </span>
                      <div className="flex-1 px-4 py-3">
                        <div className="flex flex-wrap items-baseline gap-x-3 gap-y-1">
                          <span className="font-medium text-white">{unit.role}</span>
                          <span className="font-mono text-[11px] text-sky/80">{unit.model}</span>
                        </div>
                        <p className="mt-1.5 text-sm text-mist/80">{unit.detail}</p>
                      </div>
                    </div>
                  </li>
                )
              })}
            </ul>
          </SectionReveal>
        ) : null}

        <SectionReveal className="mt-14">
          <h2 className="font-display text-2xl font-semibold text-white">
            Hardware and software
          </h2>
          <dl className="mt-6 divide-y divide-line border-y border-line">
            {system.stack.map((item) => (
              <div
                key={item.label}
                className="grid gap-1 py-3 sm:grid-cols-[11rem_1fr] sm:gap-6"
              >
                <dt className="font-mono text-[11px] tracking-wide text-sky/80 uppercase">
                  {item.label}
                </dt>
                <dd className="text-sm text-mist/90 sm:text-base">{item.value}</dd>
              </div>
            ))}
          </dl>
        </SectionReveal>

        <SectionReveal className="mt-14">
          <h2 className="font-display text-2xl font-semibold text-white">Design decisions</h2>
          <ul className="mt-6 space-y-5">
            {system.decisions.map((d) => (
              <li key={d.title} className="rounded-lg border border-line bg-panel/60 px-4 py-4">
                <p className="font-semibold text-white">{d.title}</p>
                <p className="mt-2 text-sm leading-relaxed text-mist/85 sm:text-[15px]">
                  {d.body}
                </p>
              </li>
            ))}
          </ul>
        </SectionReveal>

        <SectionReveal className="mt-14">
          <h2 className="font-display text-2xl font-semibold text-white">Go deeper</h2>
          <ul className="mt-5 flex flex-wrap gap-2">
            {system.goDeeper.map((link) => (
              <li key={link.href}>
                <a
                  href={link.href}
                  target="_blank"
                  rel="noopener"
                  className="font-mono inline-flex items-center rounded-md border border-line bg-panel px-3 py-1.5 text-[12px] text-sky transition hover:border-sky/50 hover:text-white focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-amber"
                >
                  {link.label}
                </a>
              </li>
            ))}
          </ul>
        </SectionReveal>

        <SectionReveal className="mt-16">
          <Link
            to={`/systems/${next.slug}`}
            className="group flex items-center justify-between gap-4 rounded-lg border border-line bg-panel p-5 transition hover:border-amber/40 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-amber"
          >
            <div>
              <p className="font-mono text-[10px] tracking-[0.14em] text-mist/50 uppercase">
                Next system
              </p>
              <p className="font-display mt-1 text-xl font-semibold text-white">{next.name}</p>
              <p className="mt-1 text-sm text-mist/75">{next.tagline}</p>
            </div>
            <ArrowRight
              className="h-5 w-5 shrink-0 text-amber transition group-hover:translate-x-0.5"
              aria-hidden="true"
            />
          </Link>
        </SectionReveal>
      </main>

      <Footer />
    </div>
  )
}
