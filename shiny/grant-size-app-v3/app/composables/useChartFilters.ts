import type { GrantRecord, OrgStat, CbpfMeta } from '~/types/cbpf'
import { orgKey } from '~/types/cbpf'

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
  const yearRange = ref<[number, number]>([2022, 2025])

  // Sync year defaults once meta loads
  watch(
    () => meta.value.year_max,
    (yMax) => {
      if (yMax > 0) {
        yearRange.value = [
          Math.max(meta.value.year_min, 2022),
          Math.min(yMax, 2025),
        ]
      }
    },
    { immediate: true },
  )

  const selectedOrgTypes = ref<string[]>(['INGO', 'NNGO'])

  // All funds selected by default once meta loads
  const selectedFunds = ref<string[]>([])
  watch(
    () => meta.value.funds,
    (funds) => {
      if (funds.length > 0 && selectedFunds.value.length === 0) {
        selectedFunds.value = [...funds]
      }
    },
    { immediate: true },
  )

  const orgSearch = ref('')
  const showEllipse = ref(false)
  const clipAxes = ref(true)
  const selectedOrg = ref<string | null>(null)

  // ---- aggregation (client-side, reactive) ---------------------------------

  const orgStats = computed<OrgStat[]>(() => {
    const [yMin, yMax] = yearRange.value
    const types = selectedOrgTypes.value
    const funds = selectedFunds.value

    if (types.length === 0 || funds.length === 0) return []

    // Filter individual grant records
    const filtered = grants.value.filter(
      g =>
        g.allocation_year >= yMin
        && g.allocation_year <= yMax
        && types.includes(g.org_type)
        && funds.includes(g.fund),
    )

    // Group by fund × org
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
      dot_group: g.fund === 'Ukraine' ? 'Ukraine' : 'Other funds',
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
      n_ukraine: data.filter(d => d.fund === 'Ukraine').length,
      n_other: data.filter(d => d.fund !== 'Ukraine').length,
      total_usd: data.reduce((s, d) => s + d.total_usd, 0),
      search_hits: searchMatches.value.length,
    }
  })

  function toggleOrg(key: string) {
    selectedOrg.value = selectedOrg.value === key ? null : key
  }

  function clearSelectedOrg() {
    selectedOrg.value = null
  }

  function selectAllFunds() {
    selectedFunds.value = [...meta.value.funds]
  }

  function deselectAllFunds() {
    selectedFunds.value = []
  }

  return {
    yearRange,
    selectedOrgTypes,
    selectedFunds,
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
    selectAllFunds,
    deselectAllFunds,
  }
}
