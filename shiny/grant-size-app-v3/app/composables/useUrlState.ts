import type { LocationQueryRaw } from 'vue-router'
import type { AllocationSource, CbpfMeta } from '~/types/cbpf'
import { ALLOCATION_SOURCES, DEFAULT_ORG_TYPES, orgKey, parseOrgKey } from '~/types/cbpf'

export type ViewMode = 'chart' | 'table'

/**
 * Two-way sync between the filter state and the URL query string so any
 * view can be shared as a link.
 *
 *   years=2022-2025      year range
 *   types=INGO,NNGO      organisation types (omitted when default INGO+NNGO)
 *   funds=Ukraine,Syria  fund selection (omitted when all funds; "none" = empty)
 *   source=Reserve       allocation source (omitted when All)
 *   q=unicef             highlight search
 *   ellipse=1            UHF Exception annotation on
 *   clip=0               axis clipping off (default on)
 *   org=Ukraine|Org name selected org (fund|name)
 *   view=table           table view (omitted for chart)
 *
 * Reading: Nuxt hydrates a prerendered page on `payload.path` ("/") and only
 * after `app:suspense:resolve` replaces the URL with the one the browser
 * actually requested, so at mount time both the router and window.location
 * can be "/" — the navigation timing entry keeps the original URL and is used
 * as the source of truth.
 *
 * Writing: router.replace with the rebuilt query, debounced, enabled only
 * once hydration has settled so Nuxt's own deferred replace cannot clobber it.
 */
export function useUrlState(
  filters: ReturnType<typeof useChartFilters>,
  meta: Readonly<Ref<CbpfMeta>>,
  view: Ref<ViewMode>,
) {
  const route = useRoute()
  const router = useRouter()
  const nuxtApp = useNuxtApp()
  const ready = ref(false)

  function initialParams(): URLSearchParams {
    const nav = performance.getEntriesByType?.('navigation')[0] as PerformanceNavigationTiming | undefined
    const href = nav?.name || window.location.href
    try {
      return new URL(href, window.location.origin).searchParams
    }
    catch {
      return new URLSearchParams(window.location.search)
    }
  }

  function restore(p: URLSearchParams) {
    const years = p.get('years')
    if (years) {
      const m = years.match(/^(\d{4})-(\d{4})$/)
      if (m) {
        const lo = Number(m[1])
        const hi = Number(m[2])
        if (lo <= hi) filters.setYearRange([lo, hi])
      }
    }

    const types = p.get('types')
    if (types !== null) {
      filters.selectedOrgTypes.value = types.split(',').map(s => s.trim()).filter(Boolean)
    }

    const funds = p.get('funds')
    if (funds !== null) {
      filters.setFunds(funds === 'none' ? [] : funds.split(',').map(s => s.trim()).filter(Boolean))
    }

    const source = p.get('source')
    if (source && (ALLOCATION_SOURCES as string[]).includes(source)) {
      filters.selectedSource.value = source as AllocationSource
    }

    const q = p.get('q')
    if (q) filters.orgSearch.value = q

    if (p.get('ellipse') === '1') filters.showEllipse.value = true
    if (p.get('clip') === '0') filters.clipAxes.value = false

    const org = p.get('org')
    if (org) {
      const i = org.indexOf('|')
      if (i > 0) filters.selectedOrg.value = orgKey(org.slice(0, i), org.slice(i + 1))
    }

    if (p.get('view') === 'table') view.value = 'table'
  }

  function buildQuery(): LocationQueryRaw {
    const q: LocationQueryRaw = {}
    const [lo, hi] = filters.yearRange.value
    q.years = `${lo}-${hi}`

    const types = filters.selectedOrgTypes.value
    const isDefaultTypes = types.length === DEFAULT_ORG_TYPES.length
      && DEFAULT_ORG_TYPES.every(t => types.includes(t))
    if (!isDefaultTypes) q.types = types.join(',')

    if (meta.value.funds.length > 0 && !filters.allFundsSelected.value) {
      const sel = filters.selectedFunds.value
      q.funds = sel.length === 0 ? 'none' : sel.join(',')
    }

    if (filters.selectedSource.value !== 'All') q.source = filters.selectedSource.value
    if (filters.orgSearch.value.trim()) q.q = filters.orgSearch.value.trim()
    if (filters.showEllipse.value) q.ellipse = '1'
    if (!filters.clipAxes.value) q.clip = '0'

    if (filters.selectedOrg.value) {
      const { fund, orgName } = parseOrgKey(filters.selectedOrg.value)
      q.org = `${fund}|${orgName}`
    }

    if (view.value === 'table') q.view = 'table'
    return q
  }

  let timer: ReturnType<typeof setTimeout> | null = null
  function scheduleWrite() {
    if (!ready.value) return
    if (timer) clearTimeout(timer)
    timer = setTimeout(() => {
      const next = router.resolve({ path: route.path, query: buildQuery(), hash: route.hash })
      if (next.fullPath !== route.fullPath) {
        router.replace(next).catch(() => { /* ignore redundant navigation */ })
      }
    }, 150)
  }

  function enableWrites() {
    if (ready.value) return
    ready.value = true
    scheduleWrite()
  }

  onMounted(() => {
    restore(initialParams())

    if (nuxtApp.isHydrating) {
      // Wait for Nuxt's deferred replace of the real URL (runs in its own
      // app:suspense:resolve hook, registered before ours) before writing.
      nuxtApp.hooks.hookOnce('app:suspense:resolve', async () => {
        await nextTick()
        enableWrites()
      })
      // Safety net in case the hook has already fired.
      setTimeout(enableWrites, 1500)
    }
    else {
      enableWrites()
    }
  })

  watch(
    [
      filters.yearRange,
      filters.selectedOrgTypes,
      filters.selectedFunds,
      filters.selectedSource,
      filters.orgSearch,
      filters.showEllipse,
      filters.clipAxes,
      filters.selectedOrg,
      view,
      () => meta.value.funds,
    ],
    scheduleWrite,
    { deep: true },
  )

  onBeforeUnmount(() => {
    if (timer) clearTimeout(timer)
  })

  return { ready, buildQuery }
}
