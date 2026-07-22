import { useEffect } from 'react'
import { useLocation } from 'react-router-dom'

/** Scroll to top on pathname change; honor hash anchors after paint. */
export function ScrollManager() {
  const { pathname, hash } = useLocation()

  useEffect(() => {
    if (!hash) {
      window.scrollTo({ top: 0, left: 0, behavior: 'instant' })
      return
    }

    const id = decodeURIComponent(hash.replace(/^#/, ''))
    let attempts = 0
    let frame = 0

    const tryScroll = () => {
      const el = document.getElementById(id)
      if (el) {
        el.scrollIntoView({ behavior: 'smooth', block: 'start' })
        return
      }
      attempts += 1
      if (attempts < 12) {
        frame = requestAnimationFrame(tryScroll)
      } else {
        window.scrollTo({ top: 0, left: 0, behavior: 'instant' })
      }
    }

    frame = requestAnimationFrame(tryScroll)
    return () => cancelAnimationFrame(frame)
  }, [pathname, hash])

  return null
}
