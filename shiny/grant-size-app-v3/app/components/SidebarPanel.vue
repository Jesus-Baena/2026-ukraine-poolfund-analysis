<template>
  <aside class="flex flex-col h-screen bg-dark-bg border-r border-teal/30 overflow-hidden">

    <!-- Header -->
    <div class="px-4 py-3 border-b border-teal/20 flex-shrink-0 bg-slate-blue/40">
      <div class="flex items-center gap-2 mb-1">
        <svg class="w-4 h-4 text-burnt-orange flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
            d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
        </svg>
        <span class="font-mono text-[10px] text-teal uppercase tracking-widest">Controls</span>
      </div>
      <h1 class="font-sans text-warm-sand text-sm font-bold leading-tight">
        Grant Size vs # Grants per Org
      </h1>
      <p class="font-mono text-[10px] text-teal mt-0.5">
        CBPF Global Dataset · Feb 2026
      </p>
    </div>

    <!-- Scrollable controls -->
    <div class="flex-1 overflow-y-auto custom-scrollbar px-4 py-3 space-y-4 min-h-0">

      <!-- Year range -->
      <div>
        <div class="flex items-center justify-between mb-1.5">
          <span class="font-mono text-[9px] text-teal uppercase tracking-wider">Year Range</span>
          <span class="font-mono text-[10px] text-warm-sand">{{ yearRange[0] }}–{{ yearRange[1] }}</span>
        </div>
        <div class="space-y-1">
          <div class="flex items-center gap-2">
            <span class="font-mono text-[9px] text-teal/60 w-8">From</span>
            <input
              type="range"
              :min="yearMin"
              :max="yearRange[1]"
              :value="yearRange[0]"
              class="flex-1 accent-teal"
              @input="e => updateYear('min', +(e.target as HTMLInputElement).value)"
            >
          </div>
          <div class="flex items-center gap-2">
            <span class="font-mono text-[9px] text-teal/60 w-8">To</span>
            <input
              type="range"
              :min="yearRange[0]"
              :max="yearMax"
              :value="yearRange[1]"
              class="flex-1 accent-teal"
              @input="e => updateYear('max', +(e.target as HTMLInputElement).value)"
            >
          </div>
        </div>
      </div>

      <div class="border-t border-teal/20" />

      <!-- Organisation type -->
      <div>
        <span class="font-mono text-[9px] text-teal uppercase tracking-wider block mb-2">Organisation Type</span>
        <div class="space-y-1.5">
          <label v-for="type in ORG_TYPES" :key="type" class="flex items-center gap-2 cursor-pointer group">
            <input
              type="checkbox"
              :checked="selectedOrgTypes.includes(type)"
              class="accent-teal w-3 h-3 flex-shrink-0"
              @change="toggleOrgType(type)"
            >
            <span class="font-mono text-[10px] text-warm-grey group-hover:text-warm-sand transition-colors">{{ type }}</span>
          </label>
        </div>
      </div>

      <div class="border-t border-teal/20" />

      <!-- Funds -->
      <div>
        <div class="flex items-center justify-between mb-1.5">
          <span class="font-mono text-[9px] text-teal uppercase tracking-wider">Funds</span>
          <div class="flex gap-1">
            <button
              class="font-mono text-[8px] text-teal border border-teal/40 px-1.5 py-0.5 rounded hover:bg-teal/10 transition-colors"
              @click="$emit('selectAllFunds')"
            >
              All
            </button>
            <button
              class="font-mono text-[8px] text-teal border border-teal/40 px-1.5 py-0.5 rounded hover:bg-teal/10 transition-colors"
              @click="$emit('deselectAllFunds')"
            >
              None
            </button>
          </div>
        </div>
        <select
          :value="selectedFunds"
          multiple
          class="w-full bg-charcoal border border-teal/30 rounded text-warm-grey font-mono text-[10px] p-1 max-h-28 custom-scrollbar focus:border-teal focus:outline-none"
          @change="onFundsChange"
        >
          <option v-for="fund in funds" :key="fund" :value="fund">{{ fund }}</option>
        </select>
        <p class="font-mono text-[8px] text-teal/40 mt-1">Ctrl+click to toggle individual funds</p>
      </div>

      <div class="border-t border-teal/20" />

      <!-- Highlight org -->
      <div>
        <span class="font-mono text-[9px] text-teal uppercase tracking-wider block mb-1.5">Highlight Org</span>
        <input
          :value="orgSearch"
          type="text"
          placeholder="e.g. UNICEF, MSF…"
          class="w-full bg-charcoal border border-teal/30 rounded text-warm-grey font-mono text-[10px] px-2 py-1.5 placeholder-warm-grey/30 focus:border-teal focus:outline-none"
          @input="e => $emit('update:orgSearch', (e.target as HTMLInputElement).value)"
        >
        <p v-if="searchHits > 0" class="font-mono text-[8px] text-teal mt-0.5">
          {{ searchHits }} org{{ searchHits === 1 ? '' : 's' }} matched — gold rings on chart
        </p>
      </div>

      <div class="border-t border-teal/20" />

      <!-- Toggles -->
      <div class="space-y-2">
        <label class="flex items-center gap-2 cursor-pointer group">
          <input
            type="checkbox"
            :checked="showEllipse"
            class="accent-teal w-3 h-3 flex-shrink-0"
            @change="e => $emit('update:showEllipse', (e.target as HTMLInputElement).checked)"
          >
          <span class="font-mono text-[10px] text-warm-grey group-hover:text-warm-sand transition-colors">Show UHF Exception annotation</span>
        </label>
        <label class="flex items-center gap-2 cursor-pointer group">
          <input
            type="checkbox"
            :checked="clipAxes"
            class="accent-teal w-3 h-3 flex-shrink-0"
            @change="e => $emit('update:clipAxes', (e.target as HTMLInputElement).checked)"
          >
          <span class="font-mono text-[10px] text-warm-grey group-hover:text-warm-sand transition-colors">Focus axes on Ukraine range</span>
        </label>
      </div>

      <div class="border-t border-teal/20" />

      <!-- Summary counts -->
      <div v-if="counts.n_orgs > 0" class="space-y-1.5">
        <div class="flex justify-between items-baseline">
          <span class="font-mono text-[9px] text-teal uppercase tracking-wider">Org × fund dots</span>
          <span class="font-mono text-[10px] text-warm-sand">{{ counts.n_orgs }}</span>
        </div>
        <div class="flex justify-between items-baseline">
          <span class="font-mono text-[9px] text-teal uppercase tracking-wider">Ukraine UHF</span>
          <span class="font-mono text-[10px] text-warm-sand">{{ counts.n_ukraine }}</span>
        </div>
        <div class="flex justify-between items-baseline">
          <span class="font-mono text-[9px] text-teal uppercase tracking-wider">Other funds</span>
          <span class="font-mono text-[10px] text-warm-sand">{{ counts.n_other }}</span>
        </div>
        <div class="flex justify-between items-baseline">
          <span class="font-mono text-[9px] text-teal uppercase tracking-wider">Total disbursed</span>
          <span class="font-mono text-[10px] text-warm-sand">{{ formatUSD(counts.total_usd) }}</span>
        </div>
      </div>

      <!-- Attribution -->
      <div class="border-t border-teal/20 pt-2">
        <p class="font-mono text-[8px] text-teal/50 leading-relaxed">
          Source: CBPF ProjectSummary · Feb 2026 ·
          <a href="https://baena.ai" target="_blank" class="text-teal hover:text-warm-sand transition-colors">baena.ai</a>
        </p>
      </div>

    </div>
  </aside>
</template>

<script setup lang="ts">
const ORG_TYPES = ['INGO', 'NNGO', 'UN Agency', 'Others']

const props = defineProps<{
  yearMin: number
  yearMax: number
  yearRange: [number, number]
  selectedOrgTypes: string[]
  selectedFunds: string[]
  funds: string[]
  orgSearch: string
  showEllipse: boolean
  clipAxes: boolean
  searchHits: number
  counts: {
    n_orgs: number
    n_ukraine: number
    n_other: number
    total_usd: number
    search_hits: number
  }
}>()

const emit = defineEmits<{
  (e: 'update:yearRange', val: [number, number]): void
  (e: 'update:selectedOrgTypes', val: string[]): void
  (e: 'update:selectedFunds', val: string[]): void
  (e: 'update:orgSearch', val: string): void
  (e: 'update:showEllipse', val: boolean): void
  (e: 'update:clipAxes', val: boolean): void
  (e: 'selectAllFunds'): void
  (e: 'deselectAllFunds'): void
}>()

function updateYear(end: 'min' | 'max', val: number) {
  const [lo, hi] = props.yearRange
  emit('update:yearRange', end === 'min' ? [val, hi] : [lo, val])
}

function toggleOrgType(type: string) {
  const current = props.selectedOrgTypes
  const next = current.includes(type)
    ? current.filter(t => t !== type)
    : [...current, type]
  emit('update:selectedOrgTypes', next)
}

function onFundsChange(e: Event) {
  const select = e.target as HTMLSelectElement
  const selected = Array.from(select.selectedOptions).map(o => o.value)
  emit('update:selectedFunds', selected)
}

function formatUSD(val: number): string {
  if (val >= 1e9) return `$${(val / 1e9).toFixed(1)}B`
  if (val >= 1e6) return `$${(val / 1e6).toFixed(1)}M`
  if (val >= 1e3) return `$${(val / 1e3).toFixed(0)}K`
  return `$${val.toFixed(0)}`
}
</script>
