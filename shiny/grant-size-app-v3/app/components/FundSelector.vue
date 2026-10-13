<template>
  <div>
    <div class="flex items-center justify-between mb-1.5 gap-2">
      <span class="font-mono text-[9px] text-teal uppercase tracking-wider">
        Funds
        <span class="text-teal/60 normal-case tracking-normal">({{ selectedFunds.length }}/{{ funds.length }})</span>
      </span>
      <div class="flex gap-1">
        <button
          type="button"
          class="font-mono text-[8px] text-teal border border-teal/40 px-1.5 py-0.5 rounded hover:bg-teal/10 transition-colors"
          @click="$emit('selectAll')"
        >
          All
        </button>
        <button
          type="button"
          class="font-mono text-[8px] text-teal border border-teal/40 px-1.5 py-0.5 rounded hover:bg-teal/10 transition-colors"
          @click="$emit('selectNone')"
        >
          None
        </button>
        <button
          type="button"
          class="font-mono text-[8px] text-warm-sand border border-warm-sand/50 px-1.5 py-0.5 rounded hover:bg-warm-sand/10 transition-colors"
          @click="$emit('selectUkraine')"
        >
          Ukraine only
        </button>
      </div>
    </div>

    <input
      v-model="filter"
      type="search"
      placeholder="Filter funds…"
      aria-label="Filter fund list"
      class="w-full bg-charcoal border border-teal/30 rounded text-warm-grey font-mono text-[10px] px-2 py-1 mb-1 placeholder-warm-grey/30 focus:border-teal focus:outline-none"
    >

    <div
      class="max-h-36 overflow-y-auto custom-scrollbar border border-teal/20 rounded bg-charcoal/60 px-1.5 py-1"
      role="group"
      aria-label="Funds"
    >
      <label
        v-for="fund in visibleFunds"
        :key="fund"
        class="flex items-center gap-2 cursor-pointer group py-0.5"
      >
        <input
          type="checkbox"
          :checked="selectedSet.has(fund)"
          class="accent-teal w-3 h-3 flex-shrink-0"
          @change="toggle(fund)"
        >
        <span
          class="font-mono text-[10px] transition-colors truncate"
          :class="fund === 'Ukraine' ? 'text-warm-sand' : 'text-warm-grey group-hover:text-warm-sand'"
        >{{ fund }}</span>
      </label>
      <p v-if="visibleFunds.length === 0" class="font-mono text-[9px] text-warm-grey/50 py-1">
        No fund matches "{{ filter }}"
      </p>
    </div>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{
  funds: readonly string[]
  selectedFunds: readonly string[]
}>()

const emit = defineEmits<{
  (e: 'update:selectedFunds', val: string[]): void
  (e: 'selectAll'): void
  (e: 'selectNone'): void
  (e: 'selectUkraine'): void
}>()

const filter = ref('')

const selectedSet = computed(() => new Set(props.selectedFunds))

const visibleFunds = computed(() => {
  const f = filter.value.trim().toLowerCase()
  if (!f) return props.funds
  return props.funds.filter(x => x.toLowerCase().includes(f))
})

function toggle(fund: string) {
  const next = selectedSet.value.has(fund)
    ? props.selectedFunds.filter(f => f !== fund)
    : [...props.selectedFunds, fund]
  emit('update:selectedFunds', next)
}
</script>
