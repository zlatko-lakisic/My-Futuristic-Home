import {
  Brain,
  Camera,
  Cpu,
  Droplets,
  Radio,
  Server,
  Shield,
  Zap,
  type LucideIcon,
} from 'lucide-react'
import { SectionReveal } from './SectionReveal'

type CastMember = {
  title: string
  blurb: string
  underTheHood: string
  Icon: LucideIcon
}

const CAST: CastMember[] = [
  {
    title: 'The Brain',
    blurb: 'Orchestrates every automation so the house feels intentional, not noisy.',
    underTheHood: 'Home Assistant',
    Icon: Brain,
  },
  {
    title: 'The Eyes',
    blurb: 'Watches the cameras and only raises events that matter.',
    underTheHood: 'Frigate + RTX A4000 + CodeProject.AI',
    Icon: Camera,
  },
  {
    title: 'The Edge AI',
    blurb: 'Serves local language models so judgment stays inside the house.',
    underTheHood: 'Jetson Orin + k3s + Ollama',
    Icon: Cpu,
  },
  {
    title: 'The Garden',
    blurb: 'Decides watering at dusk and dawn from weather, soil, and season.',
    underTheHood: 'hacs-agentic-watering + Orbit BHyve',
    Icon: Droplets,
  },
  {
    title: 'The Nervous System',
    blurb: 'Carries events between every subsystem on a board the size of a card.',
    underTheHood: 'Mosquitto MQTT on Pine64',
    Icon: Radio,
  },
  {
    title: 'The Backbone',
    blurb: 'A wall-mount rack that holds routing, switching, WiFi, storage, and compute.',
    underTheHood: '9U rack + 10G backbone + Proxmox',
    Icon: Server,
  },
  {
    title: 'The Safety Net',
    blurb: 'Power-cycles devices that stop responding so the house can heal itself.',
    underTheHood: 'hacs-msnswitch',
    Icon: Zap,
  },
  {
    title: 'The Moat',
    blurb: 'Keeps cheap IoT gadgets far away from the servers that matter.',
    underTheHood: 'Segmented network by role',
    Icon: Shield,
  },
]

export function MeetTheCast() {
  return (
    <section id="cast" className="mx-auto max-w-6xl px-5 py-20 sm:px-8 sm:py-28">
      <SectionReveal>
        <p className="font-mono text-xs tracking-[0.16em] text-sky uppercase">Meet the cast</p>
        <h2 className="font-display mt-3 max-w-2xl text-3xl font-semibold text-white sm:text-4xl">
          Eight roles. One house.
        </h2>
        <p className="mt-4 max-w-2xl text-mist/85">
          Each part has a job. Together they behave like a small production system
          that happens to live in a closet.
        </p>
      </SectionReveal>

      <ul className="mt-12 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {CAST.map((member, i) => (
          <li key={member.title}>
            <SectionReveal delay={i * 0.03}>
              <article className="flex h-full flex-col rounded-lg border border-line bg-panel p-5 transition hover:border-amber/30">
                <member.Icon className="h-5 w-5 text-amber" aria-hidden="true" strokeWidth={1.75} />
                <h3 className="font-display mt-4 text-lg font-semibold text-white">
                  {member.title}
                </h3>
                <p className="mt-2 flex-1 text-[15px] leading-relaxed text-mist/85">
                  {member.blurb}
                </p>
                <p className="font-mono mt-4 text-[11px] leading-snug tracking-wide text-sky/80">
                  {member.underTheHood}
                </p>
              </article>
            </SectionReveal>
          </li>
        ))}
      </ul>
    </section>
  )
}
