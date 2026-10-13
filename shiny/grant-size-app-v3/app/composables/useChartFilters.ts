import type { GrantRecord, OrgStat, CbpfMeta, AllocationSource } from '~/types/cbpf'
import { orgKey, ORG_TYPE_ORDER, DEFAULT_ORG_TYPES, UKRAINE_FUND } from '~/types/cbpf'

const DEFAULT_YEARS: [number, number] = [2022, 2025]

function median(arr: number[]): number {
  if (arr.length === 0) return 0
  const sorted = [...arr].sort((a, b) => a - b)
  const mid = Math.floor(sorted.length / 2)
  return sorted.length % 2 !== 0
    ? sorted[mid]!
    : (sorted[mid - 1]! + sorted[mid]!) / 2
}

export function useChartFilters(
  grants: Readonly<Ref<GrantRecord[]>>,
  meta: Readonly<Ref<CbpfMeta>>,
) {
  // ---- filter state ----------------------------------------------------------

  const yearRange = ref<[number, number]>([...DEFAULT_YEARS])
  // Set to true when years were restored from the URL, so the meta watcher
  // clamps instead of resetting to the 2022–2025 default.
  const yearsExplicit = ref(false)

  watch(
    () => [meta.value.year_min, meta.value.year_max] as const,
    ([yMin, yMax]) => {
      if (!(yMax > 0)) return
      if (yearsExplicit.value) {
        const lo = Math.min(Math.max(yearRange.value[0], yMin), yMax)
        const hi = Math.max(Math.min(yearRange.value[1], yMax), lo)
        yearRange.value = [lo, hi]
      }
      else {
        yearRange.value = [
          Math.max(yMin, DEFAULT_YEARS[0]),
          Math.min(yMax, DEFAULT_YEARS[1]),
        ]
      }
    },
    { immediate: true },
  )

  // Org types present in the data, in preferred display order
  const orgTypes = computed<string[]>(() => {
    const present = new Set(grants.value.map(g => g.org_type))
    const ordered = ORG_TYPE_ORDER.filter(t => present.has(t))
    const extra = [...present].filter(t => !ORG_TYPE_ORDER.includes(t)).sort()
    return [...ordered, ...extra]
  })

  const selectedOrgTypes = ref<string[]>([...DEFAULT_ORG_TYPES])

  // Funds: all selected by default once meta loads, unless the URL already
  // supplied an explicit selection.
  const selectedFunds = ref<string[]>([])
  const fundsExplicit = ref(false)
  watch(
    () => meta.value.funds,
    (funds) => {
      if (funds.length > 0 && !fundsExplicit.value) {
        selectedFunds.value = [...funds]
      }
    },
    { immediate: true },
  )

  const allFundsSelected = computed(() => {
    const all = meta.value.funds
    if (all.length === 0) return true
    const sel = new Set(selectedFunds.value)
    return all.every(f => sel.has(f)) && sel.size === all.length
  })

  const selectedSource = ref<AllocationSource>('All')
  const orgSearch = ref('')
  const showEllipse = ref(false)
  const clipAxes = ref(true)
  const selectedOrg = ref<string | null>(null)

  // ---- aggregation (client-side, reactive) ---------------------------------

  const orgStats = computed<OrgStat[]>(() => {
    const [yMin, yMax] = yearRange.value
    const types = new Set(selectedOrgTypes.value)
    const funds = new Set(selectedFunds.value)
    const source = selectedSource.value

    if (types.size === 0 || funds.size === 0) return []

    const filtered = grants.value.filter(
      g =>
        g.allocation_year >= yMin
        && g.allocation_year <= yMax
        && types.has(g.org_type)
        && funds.has(g.fund)
        && (source === 'All' || g.source === source),
    )

    const groups = new Map<string, {
      fund: string
      org_name: string
      org_type: string
      budgets: number[]
      healthCount: number
    }>()

    for (const g of filtered) {
      const key = orgKey(g.fund, g.org_name)
      const existing = groups.get(key)
      if (existing) {
        existing.budgets.push(g.budget)
        if (g.cluster === 'Health') existing.healthCount++
      }
      else {
        groups.set(key, {
          fund: g.fund,
          org_name: g.org_name,
          org_type: g.org_type,
          budgets: [g.budget],
          healthCount: g.cluster === 'Health' ? 1 : 0,
        })
      }
    }

    return Array.from(groups.values()).map(g => ({
      fund: g.fund,
      org_name: g.org_name,
      org_type: g.org_type,
      n_grants: g.budgets.length,
      median_size: median(g.budgets),
      total_usd: g.budgets.reduce((s, b) => s + b, 0),
      pct_health: g.healthCount / g.budgets.length,
      dot_group: g.fund === UKRAINE_FUND ? 'Ukraine' : 'Other funds',
    } as OrgStat))
  })

  const searchMatches = computed<OrgStat[]>(() => {
    const term = orgSearch.value.trim()
    if (!term) return []
    try {
      const re = new RegExp(term, 'i')
      return orgStats.value.filter(s => re.test(s.org_name))
    }
    catch {
      return orgStats.value.filter(s =>
        s.org_name.toLowerCase().includes(term.toLowerCase()),
      )
    }
  })

  const selectedOrgStat = computed<OrgStat | null>(() => {
    if (!selectedOrg.value) return null
    const [fund, orgName] = selectedOrg.value.split('|||')
    return orgStats.value.find(s => s.fund === fund && s.org_name === orgName) ?? null
  })

  const summaryCounts = computed(() => {
    const data = orgStats.value
    return {
      n_orgs: data.length,
      n_ukraine: data.filter(d => d.fund === UKRAINE_FUND).length,
      n_other: data.filter(d => d.fund !== UKRAINE_FUND).length,
      total_usd: data.reduce((s, d) => s + d.total_usd, 0),
      search_hits: searchMatches.value.length,
    }
  })

  // ---- actions ---------------------------------------------------------------

  function toggleOrg(key: string) {
    selectedOrg.value = selectedOrg.value === key ? null : key
  }

  function clearSelectedOrg() {
    selectedOrg.value = null
  }

  function setFunds(list: string[], explicit = true) {
    selectedFunds.value = [...list]
    fundsExplicit.value = explicit
  }

  function selectAllFunds() {
    setFunds(meta.value.funds)
  }

  function deselectAllFunds() {
    setFunds([])
  }

  function selectUkraineOnly() {
    setFunds([UKRAINE_FUND])
  }

  function setYearRange(range: [number, number], explicit = true) {
    yearRange.value = [range[0], range[1]]
    yearsExplicit.value = explicit
  }

  return {
    yearRange,
    orgTypes,
    selectedOrgTypes,
    selectedFunds,
    allFundsSelected,
    selectedSource,
    orgSearch,
    showEllipse,
    clipAxes,
    selectedOrg,
    orgStats,
    searchMatches,
    selectedOrgStat,
    summaryCounts,
    toggleOrg,
    clearSelectedOrg,
    setFunds,
    setYearRange,
    selectAllFunds,
    deselectAllFunds,
    selectUkraineOnly,
  }
}
