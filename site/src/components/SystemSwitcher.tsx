import { Link } from 'react-router-dom'
import { systems } from '../content/systems'

function shortLabel(name: string): string {
  return name.replace(/^The\s+/i, '')
}

type SystemSwitcherProps = {
  currentSlug?: string
}

export function SystemSwitcher({ currentSlug }: SystemSwitcherProps) {
  return (
    <nav aria-label="Systems" className="min-w-0 flex-1">
      <ul className="flex gap-1.5 overflow-x-auto pb-0.5 [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
        {systems.map((system) => {
          const current = system.slug === currentSlug
          return (
            <li key={system.slug} className="shrink-0">
              <Link
                to={`/systems/${system.slug}`}
                aria-current={current ? 'page' : undefined}
                className={`font-mono inline-block rounded-md border px-2 py-1 text-[10px] tracking-wide whitespace-nowrap transition focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-amber ${
                  current
                    ? 'border-amber/50 bg-panel-raised text-amber'
                    : 'border-line bg-panel/60 text-mist/70 hover:border-sky/40 hover:text-mist'
                }`}
              >
                {shortLabel(system.name)}
              </Link>
            </li>
          )
        })}
      </ul>
    </nav>
  )
}
