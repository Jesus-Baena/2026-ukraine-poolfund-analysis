<template>
  <div class="relative w-full h-full bg-charcoal">
    <!-- Chart container -->
    <div ref="chartRef" class="w-full h-full" />

    <!-- Loading overlay -->
    <div
      v-if="loading"
      class="absolute inset-0 flex items-center justify-center bg-charcoal/80"
    >
      <span class="font-mono text-warm-sand text-sm animate-pulse">Loading data…</span>
    </div>

    <!-- Empty state -->
    <div
      v-else-if="orgStats.length === 0"
      class="absolute inset-0 flex items-center justify-center"
    >
      <span class="font-mono text-warm-grey/60 text-sm">No data for current filter selection.</span>
    </div>

    <!-- Hint bar -->
    <div
      v-if="!loading && orgStats.length > 0"
      class="absolute bottom-2 right-3 font-mono text-[9px] text-teal/50 pointer-events-none"
    >
      Click a dot to highlight · Search adds gold rings · Zoom / pan with mouse
    </div>
  </div>
</template>

<script setup lang="ts">
import type { OrgStat } from '~/types/cbpf'
import { DOT_COLORS, orgKey } from '~/types/cbpf'

const props = defineProps<{
  orgStats: OrgStat[]
  searchMatches: OrgStat[]
  selectedOrg: string | null
  showEllipse: boolean
  clipAxes: boolean
  loading: boolean
  yearRange: [number, number]
}>()

const emit = defineEmits<{
  (e: 'org-clicked', key: string): void
}>()

const chartRef = ref<HTMLDivElement | null>(null)
let Plotly: any = null

// ---- helpers -----------------------------------------------------------------

function formatUSD(val: number): string {
  if (val >= 1e9) return `$${(val / 1e9).toFixed(1)}B`
  if (val >= 1e6) return `$${(val / 1e6).toFixed(1)}M`
  if (val >= 1e3) return `$${(val / 1e3).toFixed(0)}K`
  return `$${val.toFixed(0)}`
}

function buildTooltip(d: OrgStat): string {
  return [
    `<b>${d.org_name}</b>`,
    `Fund: ${d.fund}`,
    `Type: ${d.org_type}`,
    `# Grants: ${d.n_grants}`,
    `Median size: ${formatUSD(d.median_size)}`,
    `Total disbursed: ${formatUSD(d.total_usd)}`,
    `Health share: ${(d.pct_health * 100).toFixed(0)}%`,
  ].join('<br>')
}

function sizeScale(usd: number, maxUSD: number): number {
  return 6 + 18 * Math.sqrt(usd / Math.max(maxUSD, 1))
}

// ---- trace builders ----------------------------------------------------------

function buildTraces(): object[] {
  const stats = props.orgStats
  if (stats.length === 0) return []

  const maxUSD = stats.reduce((m, d) => Math.max(m, d.total_usd), 1)
  const ukrData = stats.filter(d => d.dot_group === 'Ukraine')
  const otherData = stats.filter(d => d.dot_group !== 'Ukraine')
  const traces: object[] = []

  if (otherData.length > 0) {
    traces.push({
      x: otherData.map(d => d.n_grants),
      y: otherData.map(d => d.median_size),
      mode: 'markers',
      type: 'scatter',
      name: 'Other CBPF funds',
      customdata: otherData.map(d => orgKey(d.fund, d.org_name)),
      text: otherData.map(d => buildTooltip(d)),
      hoverinfo: 'text',
      marker: {
        color: DOT_COLORS['Other funds'],
        size: otherData.map(d => sizeScale(d.total_usd, maxUSD)),
        opacity: 0.65,
        line: { width: 0 },
      },
    })
  }

  if (ukrData.length > 0) {
    traces.push({
      x: ukrData.map(d => d.n_grants),
      y: ukrData.map(d => d.median_size),
      mode: 'markers',
      type: 'scatter',
      name: 'Ukraine UHF',
      customdata: ukrData.map(d => orgKey(d.fund, d.org_name)),
      text: ukrData.map(d => buildTooltip(d)),
      hoverinfo: 'text',
      marker: {
        color: DOT_COLORS['Ukraine'],
        size: ukrData.map(d => sizeScale(d.total_usd, maxUSD)),
        opacity: 0.78,
        line: { width: 0 },
      },
    })
  }

  // Gold rings: search matches
  if (props.searchMatches.length > 0) {
    traces.push({
      x: props.searchMatches.map(d => d.n_grants),
      y: props.searchMatches.map(d => d.median_size),
      mode: 'markers',
      type: 'scatter',
      name: '',
      hoverinfo: 'none',
      showlegend: false,
      marker: {
        color: 'rgba(0,0,0,0)',
        size: 22,
        line: { color: '#FFD700', width: 2.5 },
      },
    })
  }

  // Black ring: selected org
  if (props.selectedOrg) {
    const [fund, orgName] = props.selectedOrg.split('|||')
    const sel = stats.find(d => d.fund === fund && d.org_name === orgName)
    if (sel) {
      traces.push({
        x: [sel.n_grants],
        y: [sel.median_size],
        mode: 'markers',
        type: 'scatter',
        name: '',
        hoverinfo: 'none',
        showlegend: false,
        marker: {
          color: 'rgba(0,0,0,0)',
          size: 26,
          line: { color: '#DCAA89', width: 3 },
        },
      })
    }
  }

  // Parametric ellipse for UHF Exception annotation
  if (props.showEllipse) {
    const theta = Array.from({ length: 201 }, (_, i) => (i / 200) * 2 * Math.PI)
    traces.push({
      x: theta.map(t => 9 + 4.2 * Math.cos(t)),
      y: theta.map(t => 10 ** (6.45 + 0.55 * Math.sin(t))),
      mode: 'lines',
      type: 'scatter',
      name: '',
      hoverinfo: 'none',
      showlegend: false,
      line: { color: '#BFB9B5', width: 1.5, dash: 'dot' },
    })
  }

  return traces
}

function buildLayout(): object {
  const [yMin, yMax] = props.yearRange
  const yrsLabel = `${yMin}–${yMax}`

  let xRange: number[] | undefined
  let yRangeLog: number[] | undefined

  if (props.clipAxes) {
    const ukr = props.orgStats.filter(d => d.fund === 'Ukraine')
    if (ukr.length > 0) {
      const xMax = Math.max(...ukr.map(d => d.n_grants)) + 3
      const yTop = Math.max(...ukr.map(d => d.median_size)) + 4e6
      xRange = [0.5, xMax]
      yRangeLog = [Math.log10(8000), Math.log10(yTop)]
    }
  }

  const annotations: object[] = []
  if (props.showEllipse) {
    annotations.push({
      x: 9,
      y: 6.85,
      text: 'The UHF Exception',
      showarrow: false,
      font: { color: '#DCAA89', size: 11, family: 'JetBrains Mono, monospace' },
      xanchor: 'center',
      yanchor: 'bottom',
    })
  }

  return {
    paper_bgcolor: '#1a1a1a',
    plot_bgcolor: '#2a2a2a',
    font: { family: 'Inter, sans-serif', color: '#BFB9B5', size: 12 },
    margin: { t: 40, b: 60, l: 90, r: 30 },
    xaxis: {
      title: { text: `Number of grants received (${yrsLabel})`, font: { size: 12 } },
      type: 'linear',
      gridcolor: 'rgba(76,132,141,0.18)',
      zerolinecolor: 'rgba(76,132,141,0.3)',
      tickfont: { family: 'JetBrains Mono, monospace', size: 10, color: '#BFB9B5' },
      range: xRange,
      autorange: !xRange,
    },
    yaxis: {
      title: { text: 'Median grant size (USD, log scale)', font: { size: 12 } },
      type: 'log',
      gridcolor: 'rgba(76,132,141,0.18)',
      zerolinecolor: 'rgba(76,132,141,0.3)',
      tickfont: { family: 'JetBrains Mono, monospace', size: 10, color: '#BFB9B5' },
      tickformat: '$~s',
      range: yRangeLog,
      autorange: !yRangeLog,
    },
    legend: {
      x: 0.01,
      y: 0.99,
      xanchor: 'left',
      yanchor: 'top',
      bgcolor: 'rgba(26,26,26,0.85)',
      bordercolor: 'rgba(76,132,141,0.6)',
      borderwidth: 1,
      font: { size: 11, family: 'JetBrains Mono, monospace', color: '#BFB9B5' },
    },
    hoverlabel: {
      bgcolor: '#2a2a2a',
      bordercolor: '#4C848D',
      font: { family: 'JetBrains Mono, monospace', size: 11, color: '#DCAA89' },
      align: 'left',
    },
    annotations,
  }
}

const plotConfig = {
  displayModeBar: true,
  modeBarButtonsToRemove: ['select2d', 'lasso2d', 'autoScale2d'],
  displaylogo: false,
  responsive: true,
  toImageButtonOptions: {
    format: 'png',
    filename: 'cbpf_grant_size_chart',
    width: 1400,
    height: 700,
  },
}

// ---- lifecycle ---------------------------------------------------------------

function handleClick(data: { points?: Array<{ customdata?: string }> }) {
  const key = data?.points?.[0]?.customdata
  if (key) emit('org-clicked', key)
}

onMounted(async () => {
  const mod = await import('plotly.js-dist-min')
  Plotly = (mod as any).default ?? mod
  if (!chartRef.value) return
  await Plotly.newPlot(chartRef.value, buildTraces(), buildLayout(), plotConfig)
  ;(chartRef.value as any).on('plotly_click', handleClick)
})

watch(
  [
    () => props.orgStats,
    () => props.searchMatches,
    () => props.selectedOrg,
    () => props.showEllipse,
    () => props.clipAxes,
    () => props.yearRange,
  ],
  async () => {
    if (!chartRef.value || !Plotly) return
    await Plotly.react(chartRef.value, buildTraces(), buildLayout(), plotConfig)
  },
)

onUnmounted(() => {
  if (chartRef.value && Plotly) Plotly.purge(chartRef.value)
})
</script>
