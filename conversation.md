

Good — `patchwork` is already loaded. Now the edit.

Now let me render the report to verify it works.

The "invalid RGB specification" error typically comes from a malformed colour string. Let me inspect the rendered chunk to confirm everything landed correctly.

The chunk is syntactically fine. The "invalid RGB specification" is almost certainly the 3-char hex shorthand (`"#333"`, `"#555"`) — grid's text device is picky. Let me fix them to 6-char hex.

Rendered cleanly — only the benign "incomplete final line" warning remains. Let me fix that too.

Done. The concentration-benchmark chart is now a two-panel horizontal-bar comparison:

- **Left panel** — HHI (concentration), funds sorted ascending.
- **Right panel** — Envelope 2022–2024, same fund order.
- **Ukraine highlighted in red** in both panels.

The visual insight is now immediate: Ukraine's row is a medium-length bar on the left and a top-3 bar on the right — the "same shape, bigger envelope" story the chapter's prose makes.

Render notes:
- Only fix needed was swapping 3-char hex (`"#333"`, `"#555"`) for 6-char (`"#333333"`, `"#555555"`) — grid's text device rejected the shorthand under this graphics backend.
- `conc_agg` data frame is unchanged, so the concentration-table chunk and the callout below still key off the same numbers.
- Output: `ukraine-poolfund-report.html` (14 MB), rendered successfully.



Good questions — both point at the same editorial weakness. Let me address them together.

## Final narrative review

### Where the chapter is confusing itself

The word **"concentration"** is doing double duty, and the two meanings pull in opposite directions:

| Sense | What it measures | UHF result |
|---|---|---|
| **Statistical** (HHI, Gini on shares) | How evenly budget is split across partners | Mid-pack, normal |
| **Colloquial** (sector parlance) | Whether a small group captures a lot of money | Yes — 20 orgs, 55%, repeatedly |

A reader sees "UHF is not more concentrated than peers" and thinks the report is denying what the Core-20 table plainly shows. It isn't — but the language is fighting itself.

### Better vocabulary

Drop "concentration" as the load-bearing word. The phenomenon you're describing isn't *share concentration*; it's a combination of three separable things:

1. **Absolute-dollar capture** — UHF's top partner absorbs ~$50M, Yemen's absorbs ~$20M, both at 28% share. Same share, very different cheque.
2. **Ceiling-binding** — the top of the distribution is flattened by the $5M cap rather than by competition. Seven orgs max out; the cap is a regulatory floor for the elite tier.
3. **Incumbency** — 20 names reappear every round. This is a *tenure* property, not a *share* property. You can be a low-share incumbent (consistent mid-sized grants) or a high-share non-incumbent (one big one-off).

Suggested reframings of the chapter:

- **Rename**: "Concentration, Scale, and the Core-20" → **"Scale, Ceilings, and Incumbency: Why UHF Feels Concentrated When It Isn't"** (or simpler: **"The Shape of the UHF Portfolio"**).
- In prose, replace "more concentrated" with specific terms: *larger absolute grants*, *ceiling-bound*, *cap-saturated top tier*, *stable incumbent tier*, *oligopoly by repetition rather than by share*.

### Points that are underplayed

1. **The deconcentration trend is buried.** Top-5 share: 40% → 28%. Top-10: 62% → 45%. That's a real story — elite *widening*, not freezing — and it sits under a callout that most readers will skip. Move this closer to the headline.
2. **Localisation intersects with the Core-20.** The Core-20 includes Proliska, ICF Caritas Ukraine, ADRA Ukraine. "Concentration at the top" and "localisation" are not opposites in this fund — both are true simultaneously, and the chapter should say so explicitly.
3. **Cap-binding is itself a form of concentration, but of a different kind** — bunching, not skew. Worth making the distinction explicit so the flat-top P90 finding doesn't feel contradictory to the mid-pack HHI finding.
4. **Repetition is the UHF signature, not share.** The metric you actually care about is allocation-round frequency (rounds-present / rounds-held), not share-of-envelope. It's in the Core-20 table implicitly but could be its own small chart.

---

## On "first-grant entry"

Your intuition is exactly the right probe. **Incumbency starts with how you enter.** If the typical CBPF debut is a small try-out grant and UHF debuts are already at cap — that's a capacity-assessment signal, not just a scale signal. It's the missing piece that would make the "Core-20 is a closed tier" argument quantitative rather than narrative.

### Proposed analysis

Define two populations:

- **UHF debut**: for each org that ever received a UHF grant, the size of their *first-ever* UHF grant (regardless of prior history in other CBPFs).
- **Global CBPF debut (ex-UHF)**: for each org that ever received a CBPF grant outside Ukraine, the size of their *first-ever* CBPF grant in any non-UHF fund.

Then compare the distributions. Three findings worth checking:

| Question | Metric |
|---|---|
| How big is a typical debut? | Median and P90 of first-grant size, by context |
| How many orgs entered CBPF *through* UHF? | Orgs whose global-first CBPF grant was in Ukraine |
| Which UHF debutants came in at the cap? | Named list of orgs whose first UHF grant was ≥ $3M |

### Code sketch (ready to drop in as a new chunk)

```{r first-grant-entry}
#| fig-width: 10
#| fig-height: 5

first_grants <- project_summary %>%
  filter(!is.na(OrganizationName), !is.na(Budget), Budget > 0,
         AllocationYear <= 2025) %>%
  group_by(OrganizationName, PooledFundName) %>%
  arrange(AllocationYear, ChfProjectCode, .by_group = TRUE) %>%
  slice_min(AllocationYear, n = 1, with_ties = TRUE) %>%
  summarise(
    first_year        = min(AllocationYear),
    first_grant_value = max(Budget),           # biggest cheque in the first year
    first_year_total  = sum(Budget),           # total absorbed in year 1
    .groups = "drop"
  ) %>%
  mutate(Context = if_else(PooledFundName == "Ukraine",
                           "UHF debut", "Other CBPF debut"))

# Summary stats
first_grants %>%
  group_by(Context) %>%
  summarise(
    n       = n(),
    median  = median(first_grant_value),
    p75     = quantile(first_grant_value, 0.75),
    p90     = quantile(first_grant_value, 0.90),
    max     = max(first_grant_value),
    .groups = "drop"
  ) %>%
  mutate(across(median:max, ~scales::dollar(., scale_cut = scales::cut_short_scale()))) %>%
  knitr::kable(caption = "How large is an organisation's first grant in the fund?")

# Density / jitter comparison
ggplot(first_grants,
       aes(x = first_grant_value, y = Context, fill = Context)) +
  ggdist::stat_halfeye(alpha = 0.6, .width = c(0.5, 0.9)) +
  geom_jitter(height = 0.12, size = 0.9, alpha = 0.4) +
  scale_x_log10(labels = scales::label_dollar(scale_cut = scales::cut_short_scale())) +
  scale_fill_manual(values = c("UHF debut" = "#c9184a",
                               "Other CBPF debut" = "#8aa9b0"),
                    guide = "none") +
  labs(
    title    = "UHF debut grants are structurally larger than CBPF debut grants elsewhere",
    subtitle = "First grant received by each (organisation, fund) pair, 2014–2025. Log scale.",
    x = "Size of first grant in the fund (log scale)", y = NULL,
    caption = "Source: CBPF ProjectSummary dataset, Feb 2026 extract"
  ) +
  theme_minimal(base_size = 13)
```

Plus a named-entry table to make the point tangible:

```{r uhf-cap-debuts}
first_grants %>%
  filter(Context == "UHF debut", first_grant_value >= 3e6) %>%
  arrange(desc(first_grant_value)) %>%
  transmute(
    Organisation = OrganizationName,
    `First year` = first_year,
    `First grant` = scales::dollar(first_grant_value,
                                   scale_cut = scales::cut_short_scale(),
                                   accuracy  = 0.01)
  ) %>%
  knitr::kable(caption = "Organisations whose first-ever UHF grant was ≥ $3M — entry at the top of the ceiling.")
```

### Where this belongs in the report

Right after the Core-20 table, as a new section titled something like **"Entry at the ceiling: what a first UHF grant looks like."** The logical flow becomes:

1. HHI says UHF is mid-pack → ok, but that's *share*.
2. Envelope arithmetic says the top partners absorb large absolute dollars → why aren't new names breaking in?
3. **First-grant analysis** → because UHF debuts are large, the entry bar is already at the cap, and the incumbent tier forms at arrival, not over years.
4. Core-20 table → these are those incumbents.
5. Dependency ratio → and for some of them, UHF scale exceeded their pre-war institutional weight.

That chain reads as a single argument, end-to-end.

---

**Want me to implement?** Two things I'd do in one pass:

1. Rename the chapter and tighten the prose to drop "concentration" where it's ambiguous, keep it where it's technical (HHI is HHI).
2. Add the first-grant-entry section (chart + summary table + named debutants ≥ $3M) between the Core-20 table and the dependency-ratio section.

Say the word and I'll make both edits and re-render.