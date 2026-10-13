// Raw grant record from /data/cbpf_grants.json (one row per grant),
// produced by scripts/build_data.py from the CBPF OData ProjectSummary +
// Cluster entity sets.
export interface GrantRecord {
  allocation_year: number
  fund: string
  org_name: string
  org_type: string
  budget: number
  cluster: string
  /** AllocationSourceName: "Standard" | "Reserve" */
  source: string
}

// Metadata from /data/cbpf_meta.json
export interface CbpfMeta {
  year_min: number
  year_max: number
  funds: string[]
  /** ISO date of the CBPF OData snapshot the JSON was built from */
  snapshot_date: string
  n_grants: number
  n_funds: number
  built_at: string
}

export type AllocationSource = 'All' | 'Standard' | 'Reserve'
export const ALLOCATION_SOURCES: AllocationSource[] = ['All', 'Standard', 'Reserve']

// Preferred display order for org types; anything else is appended alphabetically
export const ORG_TYPE_ORDER = ['INGO', 'NNGO', 'UN Agency', 'Red Cross', 'Others', 'Other (uncategorised)']
export const DEFAULT_ORG_TYPES = ['INGO', 'NNGO']

export const UKRAINE_FUND = 'Ukraine'

// Aggregated org × fund stat computed client-side from GrantRecord[]
export interface OrgStat {
  fund: string
  org_name: string
  org_type: string
  n_grants: number
  median_size: number
  total_usd: number
  pct_health: number
  dot_group: 'Ukraine' | 'Other funds'
}

// Unique key for an org within a fund (used for click selection)
export function orgKey(fund: string, orgName: string): string {
  return `${fund}|||${orgName}`
}

export function parseOrgKey(key: string): { fund: string; orgName: string } {
  const [fund, orgName] = key.split('|||')
  return { fund: fund ?? '', orgName: orgName ?? '' }
}

// Dot colours: Ukraine orange, all other CBPF funds teal
export const DOT_COLORS: Record<string, string> = {
  'Ukraine': '#f4a261',
  'Other funds': '#94d2bd',
}

export function formatUSD(val: number): string {
  if (val >= 1e9) return `$${(val / 1e9).toFixed(1)}B`
  if (val >= 1e6) return `$${(val / 1e6).toFixed(1)}M`
  if (val >= 1e3) return `$${(val / 1e3).toFixed(0)}K`
  return `$${val.toFixed(0)}`
}

export function formatSnapshotDate(iso: string | undefined): string {
  if (!iso) return 'unknown date'
  const d = new Date(`${iso}T00:00:00Z`)
  if (Number.isNaN(d.getTime())) return iso
  return d.toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric', timeZone: 'UTC' })
}
