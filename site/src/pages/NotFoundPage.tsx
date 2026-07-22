import { Link } from 'react-router-dom'
import { SkipLink } from '../components/SkipLink'
import { SystemSwitcher } from '../components/SystemSwitcher'
import { Footer } from '../components/Footer'

export function NotFoundPage() {
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
          <SystemSwitcher />
        </div>
      </div>

      <main
        id="main-content"
        className="mx-auto flex max-w-3xl flex-col px-5 py-20 sm:px-8 sm:py-28"
      >
        <p className="font-mono text-xs tracking-[0.16em] text-sky uppercase">404</p>
        <h1 className="font-display mt-3 text-3xl font-semibold text-white sm:text-4xl md:text-5xl">
          That room does not exist.
        </h1>
        <p className="mt-4 max-w-xl text-lg text-mist/90">
          The link is stale, mistyped, or pointing at a page that never shipped. Pick a
          system below, or head back to the house.
        </p>
        <Link
          to="/"
          className="mt-8 inline-flex w-fit items-center rounded-md bg-amber px-5 py-3 text-sm font-semibold text-night transition hover:bg-amber/90 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-amber"
        >
          Back to the house
        </Link>
      </main>

      <Footer />
    </div>
  )
}
