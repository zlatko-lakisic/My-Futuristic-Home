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
import type { SystemIcon } from '../../content/systems'

const ICONS: Record<SystemIcon, LucideIcon> = {
  brain: Brain,
  camera: Camera,
  cpu: Cpu,
  droplets: Droplets,
  radio: Radio,
  server: Server,
  zap: Zap,
  shield: Shield,
}

export function systemIcon(name: SystemIcon): LucideIcon {
  return ICONS[name]
}
