import type { GrantRecord, CbpfMeta } from '~/types/cbpf'

export function useCbpfData() {
  const config = useRuntimeConfig()
  const base = (config.public.plumberBase as string) || ''

  // When plumberBase is unset, load from pre-generated static JSON files
  // served from /data/. Set NUXT_PUBLIC_PLUMBER_BASE=https://rplumber.baena.info
  // once the plumber image is deployed to use the live API instead.
  const grantsUrl = base ? `${base}/cbpf/grants` : '/data/cbpf_grants.json'
  const metaUrl   = base ? `${base}/cbpf/meta`   : '/data/cbpf_meta.json'

  const grants = ref<GrantRecord[]>([])
  const meta = ref<CbpfMeta>({ year_min: 2014, year_max: 2025, funds: [] })
  const loading = ref(true)
  const error = ref<string | null>(null)

  async function load() {
    loading.value = true
    error.value = null
    try {
      const [grantsRes, metaRes] = await Promise.all([
        fetch(grantsUrl),
        fetch(metaUrl),
      ])
      if (!grantsRes.ok) throw new Error(`Grants: HTTP ${grantsRes.status} (${grantsUrl})`)
      if (!metaRes.ok) throw new Error(`Meta: HTTP ${metaRes.status} (${metaUrl})`)
      grants.value = await grantsRes.json()
      meta.value = await metaRes.json()
    }
    catch (e: unknown) {
      error.value = e instanceof Error ? e.message : 'Failed to load CBPF data'
      console.error('[useCbpfData]', e)
    }
    finally {
      loading.value = false
    }
  }

  if (import.meta.client) {
    load()
  }

  return {
    grants: readonly(grants),
    meta: readonly(meta),
    loading: readonly(loading),
    error: readonly(error),
  }
}
