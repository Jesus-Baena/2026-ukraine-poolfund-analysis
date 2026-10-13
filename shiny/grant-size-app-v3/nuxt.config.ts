// https://nuxt.com/docs/api/configuration/nuxt-config
const SITE_TITLE = 'CBPF Grant Size Explorer'
const SITE_DESCRIPTION
  = 'Interactive chart of grant size vs number of grants per organisation across UN Country-Based Pooled Funds (CBPF), '
  + 'highlighting the Ukraine Humanitarian Fund. Companion to the "UHF twin tiers" analysis by Jesus Baena.'

export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },

  modules: ['@nuxtjs/tailwindcss'],

  css: ['~/assets/css/main.css'],

  runtimeConfig: {
    public: {
      // Optional. Leave empty (default) to load the pre-built static JSON in
      // public/data/. Set NUXT_PUBLIC_PLUMBER_BASE=https://host to fetch
      // /cbpf/grants and /cbpf/meta from a live plumber API instead.
      plumberBase: '',
    },
  },

  app: {
    head: {
      htmlAttrs: { lang: 'en' },
      title: SITE_TITLE,
      meta: [
        { charset: 'utf-8' },
        { name: 'viewport', content: 'width=device-width, initial-scale=1, viewport-fit=cover' },
        { name: 'description', content: SITE_DESCRIPTION },
        { name: 'author', content: 'Jesus Baena' },
        { name: 'theme-color', content: '#1a1a1a' },
        { name: 'color-scheme', content: 'dark' },
        // Open Graph
        { property: 'og:type', content: 'website' },
        { property: 'og:title', content: SITE_TITLE },
        { property: 'og:description', content: SITE_DESCRIPTION },
        { property: 'og:site_name', content: 'baena.ai' },
        { property: 'og:locale', content: 'en_GB' },
        // Twitter card
        { name: 'twitter:card', content: 'summary' },
        { name: 'twitter:title', content: SITE_TITLE },
        { name: 'twitter:description', content: SITE_DESCRIPTION },
      ],
      link: [
        { rel: 'icon', type: 'image/svg+xml', href: '/favicon.svg' },
        { rel: 'preconnect', href: 'https://fonts.googleapis.com' },
        { rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: '' },
        {
          rel: 'stylesheet',
          href: 'https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600;700&family=Inter:wght@400;500;600;700&display=swap',
        },
      ],
    },
  },

  nitro: {
    prerender: {
      routes: ['/'],
    },
  },

  vite: {
    optimizeDeps: {
      include: ['plotly.js-basic-dist-min'],
    },
  },
})
