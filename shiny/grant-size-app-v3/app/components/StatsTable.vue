<template>
  <div class="flex flex-col h-full w-full bg-charcoal min-h-0">
    <div class="flex items-center justify-between gap-2 px-3 py-2 border-b border-teal/20 flex-shrink-0 flex-wrap">
      <p class="font-mono text-[10px] text-teal">
        {{ rows.length.toLocaleString('en-GB') }} org × fund rows
        <span class="text-teal/50">· click a header to sort · click a row to select</span>
      </p>
      <button
        type="button"
        class="font-mono text-[10px] text-warm-sand border border-warm-sand/50 rounded px-2 py-1 hover:bg-warm-sand/10 transition-colors"
        :disabled="rows.length === 0"
        @click="downloadCsv"
      >
        ↓ Download CSV
      </button>
    </div>

    <div class="flex-1 min-h-0 overflow-auto custom-scrollbar">
      <table class="min-w-full text-left border-collapse">
        <thead class="sticky top-0 bg-dark-bg z-10">
          <tr>
            <th
              v-for="col in columns"
              :key="col.key"
              scope="col"
              class="font-mono text-[9px] text-teal uppercase tracking-wider px-3 py-2 border-b border-teal/30 whitespace-nowrap cursor-pointer select-none hover:text-warm-sand"
              :class="col.numeric ? 'text-right' : ''"
              :aria-sort="sortKey === col.key ? (sortDir === 'asc' ? 'ascending' : 'descending') : 'none'"
              @click="setSort(col.key)"
            >
              {{ col.label }}
              <span v-if="sortKey === col.key" class="text-warm-sand">{{ sortDir === 'asc' ? '▲' : '▼' }}</span>
            </th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="r in sortedRows"
            :key="rowKey(r)"
            class="border-b border-teal/10 hover:bg-slate-blue/30 cursor-pointer"
            :class="rowKey(r) === selectedOrg ? 'bg-slate-blue/40' : ''"
            @click="$emit('org-clicked', rowKey(r))"
          >
            <td class="px-3 py-1.5 font-sans text-[11px] text-warm-grey max-w-[18rem] truncate" :title="r.org_name">
              {{ r.org_name }}
            </td>
            <td class="px-3 py-1.5 font-mono text-[10px] whitespace-nowrap" :class="r.fund === 'Ukraine' ? 'text-[#f4a261]' : 'text-warm-grey'">
              {{ r.fund }}
            </td>
            <td class="px-3 py-1.5 font-mono text-[10px] text-warm-grey whitespace-nowrap">{{ r.org_type }}</td>
            <td class="px-3 py-1.5 font-mono text-[10px] text-warm-sand text-right">{{ r.n_grants }}</td>
            <td class="px-3 py-1.5 font-mono text-[10px] text-warm-sand text-right whitespace-nowrap">{{ formatUSD(r.median_size) }}</td>
            <td class="px-3 py-1.5 font-mono text-[10px] text-warm-sand text-right whitespace-nowrap">{{ formatUSD(r.total_usd) }}</td>
            <td class="px-3 py-1.5 font-mono text-[10px] text-warm-sand text-right">{{ (r.pct_health * 100).toFixed(0) }}%</td>
          </tr>
          <tr v-if="rows.length === 0">
            <td :colspan="columns.length" class="px-3 py-6 font-mono text-[11px] text-warm-grey/60 text-center">
              No data for current filter selection.
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { OrgStat } from '~/types/cbpf'
import { formatUSD, orgKey } from '~/types/cbpf'

type SortKey = keyof Pick<OrgStat, 'org_name' | 'fund' | 'org_type' | 'n_grants' | 'median_size' | 'total_usd' | 'pct_health'>

const props = defineProps<{
  rows: OrgStat[]
  selectedOrg: string | null
  filename?: string
}>()

defineEmits<{
  (e: 'org-clicked', key: string): void
}>()

const columns: { key: SortKey; label: string; numeric: boolean }[] = [
  { key: 'org_name', label: 'Organisation', numeric: false },
  { key: 'fund', label: 'Fund', numeric: false },
  { key: 'org_type', label: 'Type', numeric: false },
  { key: 'n_grants', label: '# Grants', numeric: true },
  { key: 'median_size', label: 'Median size', numeric: true },
  { key: 'total_usd', label: 'Total USD', numeric: true },
  { key: 'pct_health', label: 'Health %', numeric: true },
]

const sortKey = ref<SortKey>('total_usd')
const sortDir = ref<'asc' | 'desc'>('desc')

function setSort(key: SortKey) {
  if (sortKey.value === key) {
    sortDir.value = sortDir.value === 'asc' ? 'desc' : 'asc'
  }
  else {
    sortKey.value = key
    sortDir.value = columns.find(c => c.key === key)?.numeric ? 'desc' : 'asc'
  }
}

const sortedRows = computed(() => {
  const key = sortKey.value
  const dir = sortDir.value === 'asc' ? 1 : -1
  const collator = new Intl.Collator('en', { sensitivity: 'base' })
  return [...props.rows].sort((a, b) => {
    const va = a[key]
    const vb = b[key]
    let cmp = 0
    if (typeof va === 'number' && typeof vb === 'number') cmp = va - vb
    else cmp = collator.compare(String(va), String(vb))
    if (cmp === 0) cmp = collator.compare(a.org_name, b.org_name)
    return cmp * dir
  })
})

function rowKey(r: OrgStat): string {
  return orgKey(r.fund, r.org_name)
}

function csvCell(v: string | number): string {
  const s = String(v)
  return /[",\n\r]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s
}

function downloadCsv() {
  const header = ['org_name', 'fund', 'org_type', 'n_grants', 'median_size_usd', 'total_usd', 'health_share']
  const lines = [header.join(',')]
  for (const r of sortedRows.value) {
    lines.push([
      csvCell(r.org_name),
      csvCell(r.fund),
      csvCell(r.org_type),
      r.n_grants,
      Math.round(r.median_size),
      Math.round(r.total_usd),
      r.pct_health.toFixed(4),
    ].join(','))
  }
  const blob = new Blob([`﻿${lines.join('\n')}\n`], { type: 'text/csv;charset=utf-8' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = props.filename ?? 'cbpf_org_fund_stats.csv'
  document.body.appendChild(a)
  a.click()
  a.remove()
  setTimeout(() => URL.revokeObjectURL(url), 1000)
}
</script>
