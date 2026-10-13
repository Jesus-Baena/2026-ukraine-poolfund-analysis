import type { GrantRecord, CbpfMeta } from '~/types/cbpf'

const EMPTY_META: CbpfMeta = {
  year_min: 2014,
  year_max: 2025,
  funds: [],
  snapshot_date: '',
  n_grants: 0,
  n_funds: 0,
  built_at: '',
}

export function useCbpfData() {
  const config = useRuntimeConfig()
  const base = (config.public.plumberBase as string) || ''

  // Default: static JSON built by scripts/build_data.py and served from /data/.
  // Optionally set NUXT_PUBLIC_PLUMBER_BASE to point at a live plumber API
  // exposing the same two shapes at /cbpf/grants and /cbpf/meta.
  const grantsUrl = base ? `${base}/cbpf/grants` : '/data/cbpf_grants.json'
  const metaUrl   = base ? `${base}/cbpf/meta`   : '/data/cbpf_meta.json'

  const grants = ref<GrantRecord[]>([])
  const meta = ref<CbpfMeta>({ ...EMPTY_META })
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
      const g = (await grantsRes.json()) as GrantRecord[]
      const m = (await metaRes.json()) as Partial<CbpfMeta>
      grants.value = g.map(r => ({ ...r, source: r.source ?? 'Unknown' }))
      meta.value = { ...EMPTY_META, ...m }
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
