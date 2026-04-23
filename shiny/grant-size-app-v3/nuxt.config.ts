// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },

  modules: ['@nuxtjs/tailwindcss'],

  css: ['~/assets/css/main.css'],

  runtimeConfig: {
    public: {
      // Set NUXT_PUBLIC_PLUMBER_BASE=https://rplumber.baena.info in production.
      // Empty string → composable falls back to pre-generated /data/cbpf_*.json files.
      plumberBase: '',
    },
  },

  app: {
    head: {
      title: 'CBPF Grant Size Analysis',
      meta: [
        { charset: 'utf-8' },
        { name: 'viewport', content: 'width=device-width, initial-scale=1' },
        {
          name: 'description',
          content: 'Interactive grant size vs number of grants per organisation — CBPF global poolfund dataset.',
        },
      ],
      link: [
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
      include: ['plotly.js-dist-min'],
    },
  },
})
