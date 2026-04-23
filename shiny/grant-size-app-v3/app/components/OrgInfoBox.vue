<template>
  <div class="flex-shrink-0 border-t border-teal/30 bg-slate-blue/20 px-4 py-3">
    <div class="flex items-start justify-between mb-2">
      <div class="flex items-center gap-2">
        <svg class="w-3.5 h-3.5 text-burnt-orange flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
            d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <span class="font-mono text-[9px] text-teal uppercase tracking-wider">Selected</span>
      </div>
      <button
        class="font-mono text-[9px] text-teal/60 hover:text-warm-sand transition-colors uppercase tracking-wider"
        @click="$emit('close')"
      >
        clear ×
      </button>
    </div>

    <p class="font-sans text-warm-sand text-xs font-semibold leading-snug mb-0.5">
      {{ orgStat.org_name }}
    </p>
    <p class="font-mono text-[10px] text-teal mb-2">
      {{ orgStat.fund }} · {{ orgStat.org_type }}
    </p>

    <div class="space-y-1">
      <div class="flex justify-between items-baseline">
        <span class="font-mono text-[9px] text-teal/70 uppercase tracking-wider">Grants received</span>
        <span class="font-mono text-[10px] text-warm-sand">{{ orgStat.n_grants }}</span>
      </div>
      <div class="flex justify-between items-baseline">
        <span class="font-mono text-[9px] text-teal/70 uppercase tracking-wider">Median size</span>
        <span class="font-mono text-[10px] text-warm-sand">{{ formatUSD(orgStat.median_size) }}</span>
      </div>
      <div class="flex justify-between items-baseline">
        <span class="font-mono text-[9px] text-teal/70 uppercase tracking-wider">Total disbursed</span>
        <span class="font-mono text-[10px] text-warm-sand">{{ formatUSD(orgStat.total_usd) }}</span>
      </div>
      <div class="flex justify-between items-baseline">
        <span class="font-mono text-[9px] text-teal/70 uppercase tracking-wider">Health share</span>
        <span class="font-mono text-[10px] text-warm-sand">{{ (orgStat.pct_health * 100).toFixed(0) }}%</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { OrgStat } from '~/types/cbpf'

defineProps<{
  orgStat: OrgStat
}>()

defineEmits<{
  (e: 'close'): void
}>()

function formatUSD(val: number): string {
  if (val >= 1e9) return `$${(val / 1e9).toFixed(1)}B`
  if (val >= 1e6) return `$${(val / 1e6).toFixed(1)}M`
  if (val >= 1e3) return `$${(val / 1e3).toFixed(0)}K`
  return `$${val.toFixed(0)}`
}
</script>
