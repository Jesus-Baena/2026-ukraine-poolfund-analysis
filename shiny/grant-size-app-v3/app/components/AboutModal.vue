<template>
  <Teleport to="body">
    <Transition name="fade">
      <div
        v-if="open"
        class="fixed inset-0 z-[100] flex items-end sm:items-center justify-center p-0 sm:p-6"
        @keydown.esc="$emit('close')"
      >
        <div class="absolute inset-0 bg-black/70" aria-hidden="true" @click="$emit('close')" />

        <div
          ref="dialogRef"
          role="dialog"
          aria-modal="true"
          aria-labelledby="about-title"
          tabindex="-1"
          class="relative w-full sm:max-w-2xl max-h-[92dvh] sm:max-h-[85dvh] flex flex-col bg-dark-bg border border-teal/40 rounded-t-xl sm:rounded-xl shadow-2xl outline-none"
        >
          <!-- Header -->
          <div class="flex items-start justify-between gap-4 px-5 py-4 border-b border-teal/20 bg-slate-blue/30 rounded-t-xl flex-shrink-0">
            <div>
              <p class="font-mono text-[10px] text-teal uppercase tracking-widest mb-0.5">About this chart</p>
              <h2 id="about-title" class="font-sans text-warm-sand text-base font-bold leading-tight">
                CBPF Grant Size Explorer
              </h2>
            </div>
            <button
              type="button"
              class="font-mono text-[11px] text-teal hover:text-warm-sand border border-teal/40 rounded px-2 py-1 transition-colors"
              aria-label="Close"
              @click="$emit('close')"
            >
              Esc ×
            </button>
          </div>

          <!-- Body -->
          <div class="overflow-y-auto custom-scrollbar px-5 py-4 space-y-5 text-[12px] leading-relaxed text-warm-grey font-sans">

            <section>
              <h3 class="font-mono text-[10px] text-teal uppercase tracking-wider mb-1.5">What it shows</h3>
              <p>
                Every dot is one <strong class="text-warm-sand">organisation within one pooled fund</strong>.
                The chart compares how many grants an organisation received from a UN
                Country-Based Pooled Fund (CBPF) with how large those grants typically were,
                over the selected allocation years. Dots for the
                <span class="text-[#f4a261] font-semibold">Ukraine Humanitarian Fund (UHF)</span>
                are shown in orange against every other CBPF in teal, so the UHF pattern can be
                read against the global baseline.
              </p>
            </section>

            <section>
              <h3 class="font-mono text-[10px] text-teal uppercase tracking-wider mb-1.5">How to read it</h3>
              <ul class="space-y-1 list-disc pl-4">
                <li><strong class="text-warm-sand">X axis</strong> — number of grants the organisation received from that fund in the selected years (linear).</li>
                <li><strong class="text-warm-sand">Y axis</strong> — median grant size in USD, on a log scale. Each step up the axis is ×10.</li>
                <li><strong class="text-warm-sand">Dot size</strong> — total USD received by that organisation from that fund (area scales with the square root of the total).</li>
                <li><strong class="text-warm-sand">Colour</strong> — <span class="text-[#f4a261]">orange</span> = Ukraine UHF; <span class="text-[#94d2bd]">teal</span> = all other CBPFs.</li>
                <li><strong class="text-warm-sand">Gold rings</strong> — organisations matching the "Highlight org" search (regular expressions allowed).</li>
                <li><strong class="text-warm-sand">Sand ring</strong> — the dot you clicked; its figures appear in the sidebar.</li>
                <li><strong class="text-warm-sand">Dotted ellipse</strong> — the "UHF Exception" annotation from the report. Its position is calibrated for the default 2022–2025 view with INGO + NNGO and all funds; it is a fixed overlay and does not move with other filters.</li>
                <li><strong class="text-warm-sand">Focus axes</strong> — clips the axes to the range occupied by Ukraine dots (plus a buffer) so the UHF cluster is readable; turn it off to see every fund.</li>
              </ul>
            </section>

            <section>
              <h3 class="font-mono text-[10px] text-teal uppercase tracking-wider mb-1.5">Data</h3>
              <p>
                Source: the public
                <a href="https://cbpfapi.unocha.org/vo2/odata/" target="_blank" rel="noopener" class="text-teal hover:text-warm-sand underline decoration-teal/40">CBPF OData API</a>
                (OCHA), entity sets <code class="font-mono text-[11px] text-warm-sand">ProjectSummary</code> and
                <code class="font-mono text-[11px] text-warm-sand">Cluster</code>, snapshot of
                <strong class="text-warm-sand">{{ formatSnapshotDate(meta.snapshot_date) }}</strong>
                <span v-if="meta.n_grants"> — {{ meta.n_grants.toLocaleString('en-GB') }} grants across {{ meta.n_funds }} funds, {{ meta.year_min }}–{{ meta.year_max }}</span>.
                Data for the current year is partial.
              </p>
            </section>

            <section>
              <h3 class="font-mono text-[10px] text-teal uppercase tracking-wider mb-1.5">Methodology</h3>
              <ul class="space-y-1 list-disc pl-4">
                <li>Grants with allocation year 2014 or later and a budget greater than zero are kept.</li>
                <li>One row per project (grant); <strong class="text-warm-sand">median grant size is computed per organisation × fund over the selected years</strong>, so changing the year range changes the medians.</li>
                <li>Organisation types follow the CBPF classification: International NGO → INGO, National NGO → NNGO, UN Agency, Red Cross/Crescent → Red Cross, Others.</li>
                <li>Each project's primary cluster is the cluster with the highest budget percentage. <em>Health share</em> is the share of an organisation's grants whose primary cluster is Health.</li>
                <li>Allocation source distinguishes <em>Standard</em> allocations (strategic rounds) from <em>Reserve</em> allocations (rapid response).</li>
                <li>Figures are nominal USD as recorded in the CBPF system; no inflation adjustment.</li>
              </ul>
            </section>

            <section>
              <h3 class="font-mono text-[10px] text-teal uppercase tracking-wider mb-1.5">Read more</h3>
              <ul class="space-y-1">
                <li>
                  <a href="https://baena.ai/demos/ukraine-poolfund-report" target="_blank" rel="noopener" class="text-teal hover:text-warm-sand underline decoration-teal/40">Full report: Ukraine Humanitarian Fund analysis</a>
                  <span class="text-warm-grey/60"> — the chart this app replicates (Quarto)</span>
                </li>
                <li>
                  <a href="https://baena.ai/articles/uhf-twin-tiers" target="_blank" rel="noopener" class="text-teal hover:text-warm-sand underline decoration-teal/40">Article: The UHF's twin tiers</a>
                  <span class="text-warm-grey/60"> — the short-form argument</span>
                </li>
                <li>
                  <a href="https://baena.ai" target="_blank" rel="noopener" class="text-teal hover:text-warm-sand underline decoration-teal/40">baena.ai</a>
                  <span class="text-warm-grey/60"> — Jesus Baena</span>
                </li>
              </ul>
            </section>

            <p class="font-mono text-[9px] text-teal/50 pt-2 border-t border-teal/20">
              Tip: every filter is stored in the URL — use "Copy link" to share exactly what you see.
              The Plotly toolbar (top right of the chart) exports a PNG.
            </p>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
import type { CbpfMeta } from '~/types/cbpf'
import { formatSnapshotDate } from '~/types/cbpf'

const props = defineProps<{
  open: boolean
  meta: CbpfMeta
}>()

const emit = defineEmits<{
  (e: 'close'): void
}>()

const dialogRef = ref<HTMLDivElement | null>(null)

function onKey(e: KeyboardEvent) {
  if (e.key === 'Escape' && props.open) emit('close')
}

watch(() => props.open, async (isOpen) => {
  if (!import.meta.client) return
  if (isOpen) {
    document.addEventListener('keydown', onKey)
    document.body.style.overflow = 'hidden'
    await nextTick()
    dialogRef.value?.focus()
  }
  else {
    document.removeEventListener('keydown', onKey)
    document.body.style.overflow = ''
  }
})

onBeforeUnmount(() => {
  if (import.meta.client) {
    document.removeEventListener('keydown', onKey)
    document.body.style.overflow = ''
  }
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
