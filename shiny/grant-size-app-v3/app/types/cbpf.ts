// Raw grant record returned by GET /cbpf/grants (one row per grant)
export interface GrantRecord {
  allocation_year: number
  fund: string
  org_name: string
  org_type: string
  budget: number
  cluster: string
}

// Metadata returned by GET /cbpf/meta
export interface CbpfMeta {
  year_min: number
  year_max: number
  funds: string[]
}

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
