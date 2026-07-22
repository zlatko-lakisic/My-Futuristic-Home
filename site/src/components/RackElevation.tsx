import { useState } from 'react'
import { SectionReveal } from './SectionReveal'

type Unit = {
  u: number
  role: string
  detail: string
}

const UNITS: Unit[] = [
  { u: 9, role: 'Gateway', detail: 'Edge routing and the house\'s front door to the wider network.' },
  { u: 8, role: 'Switching', detail: '10 gigabit backbone that stitches cameras, storage, and servers together.' },
  { u: 7, role: 'Patch Panel', detail: 'Forty-eight ports of house-wide copper, labeled and quiet.' },
  { u: 6, role: 'PoE', detail: 'Power and data for access points and IoT endpoints in one midspan.' },
  { u: 5, role: 'Controllers', detail: 'WiFi and infrastructure control planes that keep the airwaves tidy.' },
  { u: 4, role: 'Storage', detail: 'Camera recordings and backups on hardware built by hand.' },
  { u: 3, role: 'Storage', detail: 'Secondary NAS capacity for resilience and long-term keep.' },
  { u: 2, role: 'Compute', detail: 'Virtualization hosts that run the services the house depends on.' },
  { u: 1, role: 'Home Assistant Server', detail: 'The automation brain, always on, always local.' },
]

export function RackElevation() {
  const [active, setActive] = useState<number | null>(null)

  return (
    <section id="rack" className="border-y border-line bg-panel/40 py-20 sm:py-28">
      <div className="mx-auto grid max-w-6xl gap-12 px-5 sm:px-8 lg:grid-cols-[1fr_1.1fr] lg:items-center">
        <SectionReveal>
          <p className="font-mono text-xs tracking-[0.16em] text-sky uppercase">
            Built in a closet
          </p>
          <h2 className="font-display mt-3 text-3xl font-semibold text-white sm:text-4xl">
            Run like a datacenter.
          </h2>
          <p className="mt-4 max-w-md text-mist/85">
            A 9U wall-mount rack holds the backbone of the house. Tap or hover a
            unit to see what it does. Roles only. No model parade.
          </p>
          <p
            className="mt-6 min-h-[4.5rem] rounded-md border border-line bg-night/60 px-4 py-3 text-sm text-mist/90"
            aria-live="polite"
          >
            {active !== null ? (
              <>
                <span className="font-mono text-xs text-amber">U{UNITS[active].u}</span>
                <span className="ml-2 font-medium text-white">{UNITS[active].role}</span>
                <span className="mt-1 block text-mist/80">{UNITS[active].detail}</span>
              </>
            ) : (
              <span className="text-mist/55">Select a rack unit to learn its role.</span>
            )}
          </p>
        </SectionReveal>

        <SectionReveal delay={0.08}>
          <div
            className="mx-auto w-full max-w-md rounded-xl border border-line bg-night p-3 shadow-[inset_0_0_0_1px_rgba(245,168,60,0.08)]"
            role="list"
            aria-label="Nine unit rack elevation"
          >
            <div className="mb-2 flex items-center justify-between px-1">
              <span className="font-mono text-[10px] tracking-[0.14em] text-mist/50 uppercase">
                9U wall rack
              </span>
              <span className="font-mono text-[10px] text-amber/70">LIVE</span>
            </div>

            <ul className="space-y-1.5">
              {UNITS.map((unit, index) => {
                const isActive = active === index
                return (
                  <li key={unit.u} role="listitem">
                    <button
                      type="button"
                      onMouseEnter={() => setActive(index)}
                      onFocus={() => setActive(index)}
                      onClick={() => setActive(index)}
                      className={`flex w-full items-stretch overflow-hidden rounded-md border text-left transition ${
                        isActive
                          ? 'border-amber/50 bg-panel-raised'
                          : 'border-line bg-panel hover:border-sky/35'
                      }`}
                    >
                      <span className="font-mono flex w-12 shrink-0 items-center justify-center border-r border-line bg-night/80 text-[11px] text-mist/55">
                        U{unit.u}
                      </span>
                      <span className="flex flex-1 items-center justify-between gap-3 px-3 py-2.5">
                        <span className="text-sm font-medium text-white">{unit.role}</span>
                        <span
                          className={`h-1.5 w-1.5 rounded-full ${
                            isActive ? 'bg-amber' : 'bg-sky/40'
                          }`}
                          aria-hidden="true"
                        />
                      </span>
                    </button>
                  </li>
                )
              })}
            </ul>
          </div>
        </SectionReveal>
      </div>
    </section>
  )
}
