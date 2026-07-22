import { ArrowUpRight, BookOpen, Droplets, Sparkles, Zap } from 'lucide-react'
import type { LucideIcon } from 'lucide-react'
import type { ComponentType } from 'react'
import { GitHubIcon } from './GitHubIcon'
import { SectionReveal } from './SectionReveal'

type LinkCard = {
  title: string
  description: string
  href: string
  Icon: LucideIcon | ComponentType<{ className?: string }>
}

const LINKS: LinkCard[] = [
  {
    title: 'Main repository',
    description: 'Config, hardware inventory, and infrastructure layout for the whole house.',
    href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home',
    Icon: GitHubIcon,
  },
  {
    title: 'Project wiki',
    description: 'The deep documentation: networking, NVR, Proxmox, and how the pieces fit.',
    href: 'https://github.com/zlatko-lakisic/My-Futuristic-Home/wiki',
    Icon: BookOpen,
  },
  {
    title: 'Agentic orchestration',
    description: 'Edge AI on Jetson: local LLMs served from a k3s cluster in the rack.',
    href: 'https://github.com/zlatko-lakisic/agentic-orchestration',
    Icon: Sparkles,
  },
  {
    title: 'Agentic watering',
    description: 'Home Assistant integration that lets an LLM decide garden watering windows.',
    href: 'https://github.com/zlatko-lakisic/hacs-agentic-watering',
    Icon: Droplets,
  },
  {
    title: 'MSNSwitch watchdogs',
    description: 'Smart power outlets that automatically cycle devices that stop responding.',
    href: 'https://github.com/zlatko-lakisic/hacs-msnswitch',
    Icon: Zap,
  },
]

export function GoDeeper() {
  return (
    <section id="go-deeper" className="border-t border-line bg-panel/30 py-20 sm:py-28">
      <div className="mx-auto max-w-6xl px-5 sm:px-8">
        <SectionReveal>
          <p className="font-mono text-xs tracking-[0.16em] text-sky uppercase">Go deeper</p>
          <h2 className="font-display mt-3 text-3xl font-semibold text-white sm:text-4xl">
            The technical trail continues here.
          </h2>
          <p className="mt-4 max-w-2xl text-mist/85">
            This page is the story. The repositories and wiki hold the diagrams,
            configs, and decisions behind it.
          </p>
        </SectionReveal>

        <ul className="mt-12 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {LINKS.map((link, i) => (
            <li key={link.href} className={i === 0 ? 'sm:col-span-2 lg:col-span-1' : ''}>
              <SectionReveal delay={i * 0.04}>
                <a
                  href={link.href}
                  target="_blank"
                  rel="noopener"
                  className="group flex h-full flex-col rounded-lg border border-line bg-panel p-5 transition hover:border-sky/40"
                >
                  <div className="flex items-start justify-between gap-3">
                    <link.Icon className="h-5 w-5 text-amber" />
                    <ArrowUpRight
                      className="h-4 w-4 text-mist/40 transition group-hover:text-sky"
                      aria-hidden="true"
                    />
                  </div>
                  <h3 className="font-display mt-4 text-lg font-semibold text-white">
                    {link.title}
                  </h3>
                  <p className="mt-2 text-[15px] text-mist/80">{link.description}</p>
                </a>
              </SectionReveal>
            </li>
          ))}
        </ul>
      </div>
    </section>
  )
}
