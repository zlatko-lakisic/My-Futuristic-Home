export function Footer() {
  return (
    <footer className="border-t border-line py-12">
      <div className="mx-auto flex max-w-6xl flex-col gap-6 px-5 sm:flex-row sm:items-end sm:justify-between sm:px-8">
        <div>
          <p className="font-display text-lg font-semibold text-white">
            Built and operated by Zlatko Lakisic
          </p>
          <p className="mt-2 text-sm text-mist/70">Yes, it really runs the house.</p>
          <p className="mt-4 font-mono text-xs text-mist/45">MIT license</p>
        </div>

        <nav aria-label="Author links" className="flex flex-wrap gap-4 text-sm">
          <a
            href="https://github.com/zlatko-lakisic"
            target="_blank"
            rel="noopener"
            className="text-sky transition hover:text-white"
          >
            GitHub
          </a>
          <a
            href="https://www.linkedin.com/in/zlatko-lakisic/"
            target="_blank"
            rel="noopener"
            className="text-sky transition hover:text-white"
          >
            LinkedIn
          </a>
        </nav>
      </div>
    </footer>
  )
}
