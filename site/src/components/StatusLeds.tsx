import { motion } from 'framer-motion'
import { usePrefersReducedMotion } from '../hooks/usePrefersReducedMotion'

const LEDS = [
  { top: '18%', left: '12%', delay: 0 },
  { top: '28%', left: '78%', delay: 0.8 },
  { top: '52%', left: '22%', delay: 1.4 },
  { top: '64%', left: '88%', delay: 0.4 },
  { top: '76%', left: '48%', delay: 1.1 },
]

export function StatusLeds() {
  const reduced = usePrefersReducedMotion()

  return (
    <div aria-hidden="true" className="pointer-events-none absolute inset-0 overflow-hidden">
      {LEDS.map((led, i) => (
        <motion.span
          key={i}
          className="absolute h-1.5 w-1.5 rounded-full bg-amber"
          style={{ top: led.top, left: led.left, boxShadow: '0 0 10px 2px rgba(245, 168, 60, 0.45)' }}
          animate={
            reduced
              ? { opacity: 0.55 }
              : { opacity: [0.25, 0.95, 0.35, 0.85, 0.25] }
          }
          transition={
            reduced
              ? { duration: 0 }
              : { duration: 4.5, repeat: Infinity, delay: led.delay, ease: 'easeInOut' }
          }
        />
      ))}
    </div>
  )
}
