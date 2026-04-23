<template>
  <div class="h-screen w-screen overflow-hidden bg-charcoal grid grid-cols-1 lg:grid-cols-12">

    <!-- Left sidebar: controls + selected org box -->
    <div class="lg:col-span-3 flex flex-col h-screen overflow-hidden">
      <SidebarPanel
        :year-min="yearMin"
        :year-max="yearMax"
        :year-range="yearRange"
        :selected-org-types="selectedOrgTypes"
        :selected-funds="selectedFunds"
        :funds="allFunds"
        :org-search="orgSearch"
        :show-ellipse="showEllipse"
        :clip-axes="clipAxes"
        :search-hits="summaryCounts.search_hits"
        :counts="summaryCounts"
        @update:year-range="yearRange = $event"
        @update:selected-org-types="selectedOrgTypes = $event"
        @update:selected-funds="selectedFunds = $event"
        @update:org-search="orgSearch = $event"
        @update:show-ellipse="showEllipse = $event"
        @update:clip-axes="clipAxes = $event"
        @select-all-funds="selectAllFunds"
        @deselect-all-funds="deselectAllFunds"
      />
      <OrgInfoBox
        v-if="selectedOrgStat"
        :org-stat="selectedOrgStat"
        @close="clearSelectedOrg"
      />
    </div>

    <!-- Right: interactive chart -->
    <main class="lg:col-span-9 relative h-screen overflow-hidden">
      <ClientOnly>
        <DotChart
          :org-stats="orgStats"
          :search-matches="searchMatches"
          :selected-org="selectedOrg"
          :show-ellipse="showEllipse"
          :clip-axes="clipAxes"
          :loading="loading"
          :year-range="yearRange"
          @org-clicked="toggleOrg"
        />
        <template #fallback>
          <div class="h-full w-full flex items-center justify-center bg-charcoal">
            <span class="font-mono text-warm-sand text-sm animate-pulse">Loading chart…</span>
          </div>
        </template>
      </ClientOnly>

      <!-- API error banner -->
      <div
        v-if="error"
        class="absolute top-3 left-1/2 -translate-x-1/2 bg-dark-bg border border-burnt-orange/60 rounded px-4 py-2"
      >
        <p class="font-mono text-[11px] text-burnt-orange">
          ⚠ API error: {{ error }}
        </p>
      </div>
    </main>

  </div>
</template>

<script setup lang="ts">
const { grants, meta, loading, error } = useCbpfData()

const {
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
} = useChartFilters(grants, meta)

const yearMin = computed(() => meta.value.year_min)
const yearMax = computed(() => meta.value.year_max)
const allFunds = computed(() => meta.value.funds)
</script>
