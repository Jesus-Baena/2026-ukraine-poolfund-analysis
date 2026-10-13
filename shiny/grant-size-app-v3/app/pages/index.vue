<template>
  <div class="h-dvh w-full max-w-[100vw] overflow-hidden bg-charcoal flex flex-col lg:grid lg:grid-cols-12">

    <!-- Mobile top bar -->
    <header class="lg:hidden flex items-center justify-between gap-2 px-3 py-2 border-b border-teal/30 bg-slate-blue/40 flex-shrink-0">
      <button
        type="button"
        class="flex items-center gap-1.5 font-mono text-[10px] uppercase tracking-wider text-teal border border-teal/40 rounded px-2 py-1 hover:bg-teal/10 hover:text-warm-sand transition-colors"
        :aria-expanded="drawerOpen"
        aria-controls="sidebar-drawer"
        @click="drawerOpen = !drawerOpen"
      >
        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
        </svg>
        Filters
      </button>
      <h1 class="font-sans text-warm-sand text-xs font-bold truncate">CBPF Grant Size Explorer</h1>
      <button
        type="button"
        class="font-mono text-[11px] text-teal border border-teal/40 rounded w-7 h-7 hover:bg-teal/10 hover:text-warm-sand transition-colors"
        aria-label="About this chart"
        @click="aboutOpen = true"
      >
        ?
      </button>
    </header>

    <!-- Backdrop for mobile drawer -->
    <Transition name="fade">
      <div
        v-if="drawerOpen"
        class="lg:hidden fixed inset-0 z-30 bg-black/60"
        aria-hidden="true"
        @click="drawerOpen = false"
      />
    </Transition>

    <!-- Left sidebar: controls + selected org box.
         Mobile: off-canvas drawer. Desktop: static 3-col panel. -->
    <div
      id="sidebar-drawer"
      class="fixed inset-y-0 left-0 z-40 w-[86vw] max-w-sm flex flex-col h-dvh overflow-hidden bg-dark-bg shadow-2xl
             transform transition-transform duration-200 ease-out
             lg:static lg:z-auto lg:w-auto lg:max-w-none lg:col-span-3 lg:h-full lg:transform-none lg:shadow-none lg:transition-none"
      :class="drawerOpen ? 'translate-x-0' : '-translate-x-full'"
    >
      <SidebarPanel
        :year-min="yearMin"
        :year-max="yearMax"
        :year-range="yearRange"
        :org-types="orgTypes"
        :selected-org-types="selectedOrgTypes"
        :selected-funds="selectedFunds"
        :funds="allFunds"
        :selected-source="selectedSource"
        :org-search="orgSearch"
        :show-ellipse="showEllipse"
        :clip-axes="clipAxes"
        :search-hits="summaryCounts.search_hits"
        :snapshot-date="meta.snapshot_date"
        :counts="summaryCounts"
        @update:year-range="setYearRange($event)"
        @update:selected-org-types="selectedOrgTypes = $event"
        @update:selected-funds="setFunds($event)"
        @update:selected-source="selectedSource = $event"
        @update:org-search="orgSearch = $event"
        @update:show-ellipse="showEllipse = $event"
        @update:clip-axes="clipAxes = $event"
        @select-all-funds="selectAllFunds"
        @deselect-all-funds="deselectAllFunds"
        @select-ukraine-only="selectUkraineOnly"
        @open-about="aboutOpen = true"
        @close-drawer="drawerOpen = false"
      />
      <OrgInfoBox
        v-if="selectedOrgStat"
        :org-stat="selectedOrgStat"
        @close="clearSelectedOrg"
      />
    </div>

    <!-- Right: chart / table -->
    <main class="lg:col-span-9 relative flex flex-col flex-1 min-h-0 min-w-0 overflow-hidden">

      <!-- Chart-area header: view toggle + copy link -->
      <div class="flex items-center justify-between gap-2 px-3 py-1.5 border-b border-teal/20 bg-dark-bg flex-shrink-0">
        <div class="inline-flex rounded border border-teal/40 overflow-hidden" role="tablist" aria-label="View">
          <button
            v-for="v in VIEWS"
            :key="v.id"
            type="button"
            role="tab"
            :aria-selected="view === v.id"
            class="font-mono text-[10px] uppercase tracking-wider px-2.5 py-1 transition-colors border-r border-teal/40 last:border-r-0"
            :class="view === v.id ? 'bg-teal/30 text-warm-sand' : 'text-warm-grey hover:bg-teal/10 hover:text-warm-sand'"
            @click="view = v.id"
          >
            {{ v.label }}
          </button>
        </div>

        <div class="flex items-center gap-2 min-w-0">
          <span v-if="selectedOrgStat" class="hidden md:inline font-mono text-[10px] text-warm-sand truncate max-w-[20rem]" :title="selectedOrgStat.org_name">
            ● {{ selectedOrgStat.org_name }}
          </span>
          <button
            type="button"
            class="font-mono text-[10px] text-teal border border-teal/40 rounded px-2 py-1 hover:bg-teal/10 hover:text-warm-sand transition-colors whitespace-nowrap"
            :class="copied ? 'text-warm-sand border-warm-sand/60' : ''"
            @click="copyLink"
          >
            {{ copied ? '✓ Copied' : '⧉ Copy link' }}
          </button>
        </div>
      </div>

      <!-- Clipboard-blocked fallback: selectable URL -->
      <div v-if="copyFallback" class="flex items-center gap-2 px-3 py-1.5 border-b border-teal/20 bg-dark-bg flex-shrink-0">
        <span class="font-mono text-[9px] text-teal uppercase tracking-wider whitespace-nowrap">Copy this link</span>
        <input
          ref="copyFallbackRef"
          :value="copyFallback"
          readonly
          class="flex-1 min-w-0 bg-charcoal border border-teal/30 rounded text-warm-grey font-mono text-[10px] px-2 py-1 focus:border-teal focus:outline-none"
          @focus="e => (e.target as HTMLInputElement).select()"
        >
        <button
          type="button"
          class="font-mono text-[10px] text-teal hover:text-warm-sand"
          aria-label="Dismiss"
          @click="copyFallback = null"
        >
          ×
        </button>
      </div>

      <!-- Content -->
      <div class="flex-1 min-h-0 min-w-0 relative">
        <ClientOnly>
          <DotChart
            v-if="view === 'chart'"
            :org-stats="orgStats"
            :search-matches="searchMatches"
            :selected-org="selectedOrg"
            :show-ellipse="showEllipse"
            :clip-axes="clipAxes"
            :loading="loading"
            :year-range="yearRange"
            @org-clicked="toggleOrg"
            @open-about="aboutOpen = true"
          />
          <StatsTable
            v-else
            :rows="orgStats"
            :selected-org="selectedOrg"
            :filename="csvFilename"
            @org-clicked="toggleOrg"
          />
          <template #fallback>
            <div class="h-full w-full flex items-center justify-center bg-charcoal">
              <span class="font-mono text-warm-sand text-sm animate-pulse">Loading chart…</span>
            </div>
          </template>
        </ClientOnly>

        <!-- Data error banner -->
        <div
          v-if="error"
          class="absolute top-3 left-1/2 -translate-x-1/2 max-w-[90%] bg-dark-bg border border-burnt-orange/60 rounded px-4 py-2"
        >
          <p class="font-mono text-[11px] text-burnt-orange break-words">
            ⚠ Data error: {{ error }}
          </p>
        </div>
      </div>
    </main>

    <AboutModal :open="aboutOpen" :meta="meta" @close="aboutOpen = false" />
  </div>
</template>

<script setup lang="ts">
import type { ViewMode } from '~/composables/useUrlState'

const VIEWS: { id: ViewMode; label: string }[] = [
  { id: 'chart', label: 'Chart' },
  { id: 'table', label: 'Table' },
]

const { grants, meta, loading, error } = useCbpfData()

const filters = useChartFilters(grants, meta)
const {
  yearRange,
  orgTypes,
  selectedOrgTypes,
  selectedFunds,
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
} = filters

const view = ref<ViewMode>('chart')
const drawerOpen = ref(false)
const aboutOpen = ref(false)
const copied = ref(false)

useUrlState(filters, meta, view)

const yearMin = computed(() => meta.value.year_min)
const yearMax = computed(() => meta.value.year_max)
const allFunds = computed(() => meta.value.funds)

const csvFilename = computed(() => {
  const [lo, hi] = yearRange.value
  return `cbpf_org_fund_stats_${lo}-${hi}.csv`
})

let copiedTimer: ReturnType<typeof setTimeout> | null = null
const copyFallback = ref<string | null>(null)
const copyFallbackRef = ref<HTMLInputElement | null>(null)

function legacyCopy(text: string): boolean {
  try {
    const ta = document.createElement('textarea')
    ta.value = text
    ta.setAttribute('readonly', '')
    ta.style.position = 'fixed'
    ta.style.opacity = '0'
    document.body.appendChild(ta)
    ta.select()
    const ok = document.execCommand('copy')
    ta.remove()
    return ok
  }
  catch {
    return false
  }
}

async function copyLink() {
  const url = window.location.href
  let ok = false
  try {
    if (navigator.clipboard?.writeText) {
      await navigator.clipboard.writeText(url)
      ok = true
    }
  }
  catch {
    ok = false
  }
  if (!ok) ok = legacyCopy(url)

  if (ok) {
    copyFallback.value = null
    copied.value = true
    if (copiedTimer) clearTimeout(copiedTimer)
    copiedTimer = setTimeout(() => { copied.value = false }, 1800)
  }
  else {
    // Clipboard blocked: show the URL pre-selected so the user can Ctrl+C.
    copyFallback.value = url
    await nextTick()
    copyFallbackRef.value?.focus()
    copyFallbackRef.value?.select()
  }
}

// Close the drawer with Escape on mobile
function onKey(e: KeyboardEvent) {
  if (e.key === 'Escape' && drawerOpen.value && !aboutOpen.value) drawerOpen.value = false
}
onMounted(() => document.addEventListener('keydown', onKey))
onBeforeUnmount(() => {
  document.removeEventListener('keydown', onKey)
  if (copiedTimer) clearTimeout(copiedTimer)
})
</script>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.15s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
