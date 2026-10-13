import type { Config } from 'tailwindcss'

export default {
  content: [
    './app/**/*.{vue,ts,js}',
  ],
  theme: {
    extend: {
      colors: {
        'warm-sand': '#DCAA89',
        'terracotta': '#D6794D',
        'slate-blue': '#30525C',
        'teal': '#4C848D',
        'burnt-orange': '#C35627',
        'warm-grey': '#BFB9B5',
        'charcoal': '#1a1a1a',
        'dark-bg': '#2a2a2a',
      },
      fontFamily: {
        mono: ['JetBrains Mono', 'ui-monospace', 'SFMono-Regular', 'monospace'],
        sans: ['Inter', 'ui-sans-serif', 'system-ui', 'sans-serif'],
      },
    },
  },
} satisfies Config
