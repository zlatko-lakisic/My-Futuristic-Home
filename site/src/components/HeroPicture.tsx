/** Shared full-bleed hero picture: WebP with JPEG fallback. */
type HeroPictureProps = {
  /** Filename stem without extension, e.g. `hero-brain` or `hero-rack-house`. */
  stem: string
  className?: string
  fetchPriority?: 'high' | 'low' | 'auto'
}

export function HeroPicture({
  stem,
  className = 'block h-auto w-full max-w-full',
  fetchPriority,
}: HeroPictureProps) {
  const base = import.meta.env.BASE_URL

  return (
    <picture>
      {/* TODO: regenerate source art at 1920x760 or wider for sharper desktop rendering. */}
      <source type="image/webp" srcSet={`${base}${stem}.webp`} />
      <img
        src={`${base}${stem}.jpg`}
        alt=""
        width={1024}
        height={405}
        sizes="100vw"
        className={className}
        decoding="async"
        fetchPriority={fetchPriority}
      />
    </picture>
  )
}
