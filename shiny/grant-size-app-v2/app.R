# ============================================================
# Grant Size vs Number of Grants per Organisation — v2
# Each dot = one organisation within one specific CBPF fund
# Ukraine UHF vs all other CBPF funds, 2014-2025
#
# Data: CBPF ProjectSummary + Cluster datasets, Feb 2026 extract
# Author: SWAM / JBI
# ============================================================

# Ensure user library is on the path (needed when launched outside RStudio)
user_lib <- path.expand("~/R/library")
if (dir.exists(user_lib) && !(user_lib %in% .libPaths())) {
  .libPaths(c(user_lib, .libPaths()))
}

library(shiny)
library(bslib)
library(dplyr)
library(ggplot2)
library(plotly)
library(readr)
library(scales)
library(tidyr)
library(glue)

# ===========================================================
# DATA — loaded once at startup; pipeline mirrors the QMD
# ===========================================================

project_summary <- read_csv("data/ProjectSummary_ALL_20260219_100323_UTC.csv",
                            show_col_types = FALSE) %>%
  filter(AllocationYear <= 2025, AllocationYear >= 2014)

clusters_raw    <- read_csv("data/Cluster_ALL_20260219_100323_UTC.csv",
                            show_col_types = FALSE) %>%
  filter(AllocationYear <= 2025, AllocationYear >= 2014)

# Full dataset — mature period (2014-2025), all org types included
grants <- project_summary %>%
  filter(!is.na(Budget), Budget > 0) %>%
  mutate(
    Context = if_else(PooledFundName == "Ukraine", "Ukraine UHF", "Global CBPF"),
    OrgType = case_when(
      OrganizationType == "International NGO" ~ "INGO",
      OrganizationType == "National NGO"      ~ "NNGO",
      OrganizationType == "UN Agency"         ~ "UN Agency",
      OrganizationType == "Others"            ~ "Others",
      OrganizationType == "Red Cross/Crescent" ~ "Red Cross",
      TRUE                                    ~ "Other (uncategorised)"
    )
  )

# FIX D1/D2: use ChfProjectCode (globally unique) instead of ChfId,
# and clusters already filtered to 2014-2025 above
cl_primary <- clusters_raw %>%
  group_by(ChfProjectCode) %>%
  slice_max(Percentage, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  select(ChfProjectCode, Cluster) %>%
  mutate(Cluster = case_when(
    Cluster == "Water, Sanitation and Hygiene"     ~ "WASH",
    Cluster == "Emergency Shelter and NFI"         ~ "Shelter & NFI",
    Cluster == "Camp Coordination / Management"    ~ "Camp Coord./Mgmt",
    Cluster == "Coordination and Support Services" ~ "Coord. & Support",
    Cluster == "Emergency Telecommunications"      ~ "Telecoms",
    TRUE ~ Cluster
  ))

grants_cl <- grants %>%
  left_join(cl_primary, by = "ChfProjectCode") %>%
  mutate(
    Cluster   = replace_na(Cluster, "Unknown"),
    is_health = Cluster == "Health"
  )

# FIX D4: year floor pinned to 2014 (mature period)
year_min <- 2014L
year_max <- 2025L

# Palette aligned with the main report (teal family)
dot_colors <- c(
  "Ukraine"     = "#005f73",  # primary teal — subject
  "Other funds" = "#94d2bd"   # soft teal — context
)

# FIX D7: cleaner Ukraine-first sort
other_funds <- grants_cl %>%
  filter(PooledFundName != "Ukraine") %>%
  distinct(PooledFundName) %>% arrange(PooledFundName) %>% pull(PooledFundName)
all_funds <- c("Ukraine", other_funds)

# ===========================================================
# UI
# ===========================================================

ui <- page_sidebar(
  theme = bs_theme(
    version     = 5,
    primary     = "#005f73",
    bg          = "#ffffff",
    fg          = "#2d3748",
    base_font   = font_google("Inter"),
    code_font   = font_google("JetBrains Mono"),
    "body-bg"   = "#f7fafc"
  ),

  title = tags$div(
    style = "display:flex; align-items:center; gap:12px;",
    tags$span(style = "font-weight:700; font-size:1.1em;",
              "Grant Size vs Number of Grants — CBPF Partners"),
    tags$span(
      style = "font-size:0.8em; color:#cbd5e0; font-weight:400;",
      "Ukraine UHF in context · 2014\u20132025"
    )
  ),

  window_title = "CBPF Grant Size Explorer",

  tags$head(
    tags$style(HTML("
      .navbar, .bslib-page-title, header.navbar {
        background: linear-gradient(90deg, #003d4c 0%, #005f73 100%) !important;
        color: #ffffff !important;
        border-bottom: 3px solid #94d2bd;
      }
      .navbar .navbar-brand, .navbar * { color: #ffffff !important; }
      .kpi-card {
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-left: 4px solid #005f73;
        border-radius: 8px;
        padding: 12px 16px;
        box-shadow: 0 1px 2px rgba(0,0,0,0.04);
      }
      .kpi-card.accent { border-left-color: #ee9b00; }
      .kpi-card.soft   { border-left-color: #94d2bd; }
      .kpi-label {
        font-size: 0.72em; color: #4a5568;
        text-transform: uppercase; letter-spacing: 0.05em;
        font-weight: 600; margin-bottom: 2px;
      }
      .kpi-value { font-size: 1.55em; font-weight: 700; color: #003d4c; line-height: 1.15; }
      .kpi-sub   { font-size: 0.78em; color: #718096; margin-top: 2px; }
      .selected-org-box {
        background: #e6f0f2; border: 1px solid #94d2bd;
        border-left: 4px solid #005f73;
        border-radius: 6px; padding: 8px 12px;
        font-size: 0.88em; color: #2d3748;
      }
      .fund-btns { display:flex; gap:6px; margin-bottom:6px; }
      .fund-btns .btn { font-size:0.75em; padding:3px 10px; }
      .intro-card {
        background: rgba(0,95,115,0.04);
        border-left: 3px solid #005f73;
        padding: 10px 14px; border-radius: 0 6px 6px 0;
        font-size: 0.88em; color: #4a5568;
        margin-bottom: 12px;
      }
      .section-label {
        color: #003d4c; font-size: 0.72em; font-weight: 700;
        text-transform: uppercase; letter-spacing: 0.08em;
        margin: 14px 0 6px 0; padding-bottom: 4px;
        border-bottom: 1px solid #e2e8f0;
      }
      .section-label:first-of-type { margin-top: 0; }
    "))
  ),

  sidebar = sidebar(
    width = 310,
    title = NULL,
    open  = "always",

    div(class = "section-label", "Time window"),
    sliderInput("years", NULL,
                min   = year_min,
                max   = year_max,
                value = c(2022L, 2025L),
                step  = 1L, sep = ""),

    div(class = "section-label", "Organisation type"),
    checkboxGroupInput("org_type", NULL,
                       choices  = c("INGO", "NNGO", "UN Agency", "Others", "Red Cross"),
                       selected = c("INGO", "NNGO")),

    div(class = "section-label", "Funds to show"),
    div(class = "fund-btns",
        actionButton("funds_all",  "All",   class = "btn-sm btn-outline-secondary"),
        actionButton("funds_none", "None",  class = "btn-sm btn-outline-secondary"),
        actionButton("funds_ukr",  "Ukraine only", class = "btn-sm btn-outline-primary")
    ),
    selectizeInput("funds", NULL,
                   choices  = all_funds,
                   selected = all_funds,
                   multiple = TRUE,
                   options  = list(
                     placeholder      = "Pick funds\u2026",
                     plugins          = list("remove_button"),
                     closeAfterSelect = FALSE
                   )),

    div(class = "section-label", "Highlight"),
    textInput("org_search", NULL,
              placeholder = "e.g. M\u00e9decins, UNHCR\u2026"),
    uiOutput("search_hit_count"),
    uiOutput("selected_org_info"),
    uiOutput("clear_selection_ui"),

    div(class = "section-label", "Display"),
    checkboxInput("show_ellipse",
                  "'UHF Exception' zone (2022\u20132025 only)",
                  value = FALSE),
    checkboxInput("clip_axes",
                  "Focus on Ukraine range",
                  value = TRUE),

    hr(style="margin:14px 0;"),
    tags$p(
      "Methodology and interpretation at ",
      tags$a("baena.ai", href = "https://baena.ai", target = "_blank"),
      style = "font-size:11.5px; color:#718096; margin: 0;"
    )
  ),

  # -------- KPI STRIP --------
  layout_columns(
    col_widths = c(3, 3, 3, 3),
    fillable   = FALSE,
    uiOutput("kpi_orgs"),
    uiOutput("kpi_funds"),
    uiOutput("kpi_disbursed"),
    uiOutput("kpi_ukraine_share")
  ),

  # -------- Intro explainer --------
  div(class = "intro-card",
      strong("How to read this chart."),
      " Each dot is one organisation within one CBPF fund. ",
      "X-axis: number of grants received in the selected window. ",
      "Y-axis: median grant size (log scale). ",
      "Bubble size: total disbursed. ",
      tags$span(style = "color:#005f73; font-weight:600;", "Ukraine partners"),
      " stand out in darker teal; all other CBPF fund partners in light teal."
  ),

  # -------- Main chart card --------
  card(
    full_screen = TRUE,
    card_header("Organisation dot-chart", class = "bg-light"),
    plotlyOutput("chart", height = "640px"),
    card_footer(
      class = "text-muted",
      style = "font-size:0.8em;",
      "Click a dot to highlight \u00b7 Search box adds gold rings \u00b7 Zoom / pan with mouse \u00b7 Download PNG from toolbar"
    )
  )
)

# ===========================================================
# SERVER
# ===========================================================

server <- function(input, output, session) {

  # --- selected org via click (toggle) ----------------------
  selected_org <- reactiveVal(NULL)

  observeEvent(event_data("plotly_click", source = "dotchart"), {
    click <- event_data("plotly_click", source = "dotchart")
    if (!is.null(click) && !is.null(click$key)) {
      current <- selected_org()
      if (!is.null(current) && current == click$key) {
        selected_org(NULL)
      } else {
        selected_org(click$key)
      }
    }
  })

  # --- fund quick buttons ----------------------------------
  observeEvent(input$funds_all, {
    updateSelectizeInput(session, "funds", selected = all_funds)
  })
  observeEvent(input$funds_none, {
    updateSelectizeInput(session, "funds", selected = character(0))
  })
  observeEvent(input$funds_ukr, {
    updateSelectizeInput(session, "funds", selected = "Ukraine")
  })

  observeEvent(input$reset_click, {
    selected_org(NULL)
  })

  # --- aggregated data reactive ------------------------------
  org_stats <- reactive({
    req(length(input$org_type) > 0, length(input$funds) > 0)

    grants_cl %>%
      filter(
        AllocationYear    >= input$years[1],
        AllocationYear    <= input$years[2],
        OrgType           %in% input$org_type,
        PooledFundName    %in% input$funds,
        !is.na(Budget), Budget > 0,
        !is.na(OrganizationName)
      ) %>%
      group_by(PooledFundName, OrganizationName, OrganizationType, OrgType) %>%
      summarise(
        n_grants    = n(),
        median_size = median(Budget),
        total_usd   = sum(Budget),
        pct_health  = mean(Cluster == "Health"),
        .groups     = "drop"
      ) %>%
      mutate(
        dot_group = if_else(PooledFundName == "Ukraine", "Ukraine", "Other funds"),
        tooltip = glue(
          "<b>{OrganizationName}</b><br>",
          "Fund: {PooledFundName}<br>",
          "Type: {OrganizationType}<br>",
          "# Grants: {n_grants}<br>",
          "Median size: {dollar(median_size, accuracy = 1, scale_cut = cut_short_scale())}<br>",
          "Total disbursed: {dollar(total_usd, accuracy = 1, scale_cut = cut_short_scale())}<br>",
          "% Health grants: {percent(pct_health, accuracy = 1)}"
        )
      )
  })

  # --- KPI widgets -----------------------------------------
  kpi_box <- function(label, value, sub = NULL, variant = "") {
    div(class = paste("kpi-card", variant),
        div(class = "kpi-label", label),
        div(class = "kpi-value", value),
        if (!is.null(sub)) div(class = "kpi-sub", sub)
    )
  }

  output$kpi_orgs <- renderUI({
    d <- org_stats()
    kpi_box("Org\u00d7Fund rows",
            format(nrow(d), big.mark = ","),
            sub = paste0(n_distinct(d$OrganizationName), " unique organisations"))
  })

  output$kpi_funds <- renderUI({
    d <- org_stats()
    kpi_box("Funds shown",
            n_distinct(d$PooledFundName),
            sub = paste0("of ", length(all_funds), " total"),
            variant = "soft")
  })

  output$kpi_disbursed <- renderUI({
    d <- org_stats()
    kpi_box("Total disbursed",
            dollar(sum(d$total_usd, na.rm = TRUE),
                   scale_cut = cut_short_scale(), accuracy = 0.1),
            sub = paste0(input$years[1], "\u2013", input$years[2]))
  })

  output$kpi_ukraine_share <- renderUI({
    d <- org_stats()
    total  <- sum(d$total_usd, na.rm = TRUE)
    ukr    <- sum(d$total_usd[d$PooledFundName == "Ukraine"], na.rm = TRUE)
    share  <- if (total > 0) ukr / total else 0
    kpi_box("Ukraine share",
            percent(share, accuracy = 0.1),
            sub = paste0(dollar(ukr, scale_cut = cut_short_scale(), accuracy = 0.1),
                         " to Ukraine"),
            variant = "accent")
  })

  # --- sidebar info widgets ---------------------------------
  output$search_hit_count <- renderUI({
    term <- trimws(if (is.null(input$org_search)) "" else input$org_search)
    if (nchar(term) == 0) return(NULL)
    data <- org_stats()
    n <- sum(grepl(term, data$OrganizationName, ignore.case = TRUE))
    div(style = "font-size:0.82em; color:#718096; margin-top:4px;",
        glue("{n} org{ifelse(n==1,'','s')} matched"))
  })

  output$clear_selection_ui <- renderUI({
    sel <- selected_org()
    if (is.null(sel)) return(NULL)
    tagList(
      br(),
      actionButton("reset_click", "Clear selection",
                   class = "btn-sm btn-outline-secondary",
                   style = "width: 100%;")
    )
  })

  output$selected_org_info <- renderUI({
    sel <- selected_org()
    if (is.null(sel)) return(NULL)
    if (!grepl("|", sel, fixed = TRUE)) return(NULL)
    parts <- strsplit(sel, "|", fixed = TRUE)[[1]]
    fund_name <- parts[1]
    org_name  <- parts[2]
    data <- org_stats()
    row  <- data %>% filter(PooledFundName == fund_name, OrganizationName == org_name)
    if (nrow(row) == 0) return(NULL)
    tagList(
      br(),
      div(
        class = "selected-org-box",
        tags$b(org_name), br(),
        tags$span(style = "color:#005f73; font-weight:600;", fund_name), br(),
        tags$small(row$OrganizationType[1]), br(), br(),
        tags$b(row$n_grants[1]), " grants received", br(),
        "Median: ", tags$b(dollar(row$median_size[1], scale_cut = cut_short_scale(), accuracy = 0.01)), br(),
        "Total: ",  tags$b(dollar(row$total_usd[1],   scale_cut = cut_short_scale(), accuracy = 0.01)), br(),
        "Health grants: ", tags$b(percent(row$pct_health[1], accuracy = 1))
      )
    )
  })

  # --- main chart -------------------------------------------
  output$chart <- renderPlotly({
    data <- org_stats()

    if (nrow(data) == 0) {
      return(plotly_empty() %>%
               layout(title = "No data for the current filter selection."))
    }

    yrs_label <- paste0(input$years[1], "\u2013", input$years[2])

    # Axis limits
    if (input$clip_axes && any(data$PooledFundName == "Ukraine")) {
      ukr_rows  <- data %>% filter(PooledFundName == "Ukraine")
      x_right   <- max(ukr_rows$n_grants)    + 3
      y_top     <- max(ukr_rows$median_size) + 4e6
    } else {
      x_right   <- NA
      y_top     <- NA
    }

    # FIX D3: ellipse only valid for 2022-2025 Ukraine calibration.
    # Show only if year range matches AND user asks for it.
    default_range <- identical(as.integer(input$years), c(2022L, 2025L))
    show_ellipse  <- isTRUE(input$show_ellipse) && default_range &&
                     "Ukraine" %in% input$funds

    theta      <- seq(0, 2 * pi, length.out = 200)
    ellipse_df <- data.frame(
      x = 9 + 4.2 * cos(theta),
      y = 10^(6.45 + 0.55 * sin(theta))
    )

    # Search highlight layer
    search_term  <- trimws(if (is.null(input$org_search)) "" else input$org_search)
    has_search   <- nchar(search_term) > 0
    data_search  <- if (has_search) {
      data %>% filter(grepl(search_term, OrganizationName, ignore.case = TRUE))
    } else {
      data[0, ]
    }

    # Click-selected org
    sel_org  <- selected_org()
    data_sel <- if (!is.null(sel_org) && grepl("|", sel_org, fixed = TRUE)) {
      parts <- strsplit(sel_org, "|", fixed = TRUE)[[1]]
      data %>% filter(PooledFundName == parts[1], OrganizationName == parts[2])
    } else {
      data[0, ]
    }

    # ---- build ggplot ----------------------------------------
    p <- ggplot(data,
                aes(x     = n_grants,
                    y     = median_size,
                    color = dot_group,
                    size  = total_usd,
                    text  = tooltip,
                    key   = paste0(PooledFundName, "|", OrganizationName))) +
      geom_point(alpha = 0.7, stroke = 0)

    if (show_ellipse) {
      p <- p +
        geom_path(data = ellipse_df,
                  aes(x = x, y = y),
                  inherit.aes = FALSE,
                  color = "#bb3e03", linewidth = 0.9, linetype = "solid") +
        annotate("text",
                 x = 9, y = 10^6.9,
                 label = "The UHF Exception",
                 hjust = 0.5, vjust = 1,
                 size = 4, fontface = "bold.italic",
                 color = "#bb3e03")
    }

    if (nrow(data_search) > 0) {
      p <- p +
        geom_point(data = data_search,
                   aes(x = n_grants, y = median_size),
                   inherit.aes = FALSE,
                   shape = 21, color = "#FFD700", fill = NA,
                   size = 6, stroke = 2, alpha = 1)
    }

    if (nrow(data_sel) > 0) {
      p <- p +
        geom_point(data = data_sel,
                   aes(x = n_grants, y = median_size),
                   inherit.aes = FALSE,
                   shape = 21, color = "#222222", fill = NA,
                   size = 8, stroke = 2.5, alpha = 1)
    }

    p <- p +
      scale_y_log10(
        labels = label_dollar(scale_cut = cut_short_scale()),
        breaks = c(1e4, 5e4, 1e5, 5e5, 1e6, 5e6, 1e7)
      ) +
      scale_x_continuous(
        labels = label_comma(),
        breaks = c(1, 2, 3, 5, 10, 15, 20, 30, 50, 75, 100)
      ) +
      scale_color_manual(
        values = dot_colors, name = NULL,
        guide  = guide_legend(override.aes = list(size = 4))
      ) +
      scale_size_continuous(
        name   = paste0("Total disbursed (", yrs_label, ")"),
        range  = c(2, 14),
        labels = label_dollar(scale_cut = cut_short_scale()),
        breaks = c(1e6, 5e6, 1e7, 3e7, 5e7, 1e8),
        trans  = "sqrt"
      ) +
      coord_cartesian(xlim = c(0.5, x_right), ylim = c(NA, y_top)) +
      labs(
        x = paste0("Number of grants received (", yrs_label, ")"),
        y = "Median grant size (USD, log scale)",
        caption = "Source: CBPF ProjectSummary dataset, Feb 2026 extract."
      ) +
      theme_minimal(base_size = 13, base_family = "Inter") +
      theme(
        legend.position      = c(0.02, 0.98),
        legend.justification = c(0, 1),
        legend.background    = element_rect(fill = alpha("white", 0.85),
                                            colour = "grey85", linewidth = 0.3),
        legend.margin        = margin(4, 6, 4, 6),
        panel.grid.minor     = element_blank(),
        plot.caption         = element_text(colour = "#718096", size = 9)
      )

    # ---- convert to plotly -----------------------------------
    ggplotly(p, tooltip = "text", source = "dotchart") %>%
      layout(
        hoverlabel = list(
          bgcolor = "white",
          font    = list(size = 12, family = "Inter, Segoe UI, Arial"),
          align   = "left"
        ),
        margin = list(t = 10, b = 50, l = 10, r = 10)
      ) %>%
      config(
        displayModeBar         = TRUE,
        modeBarButtonsToRemove = c("select2d", "lasso2d", "autoScale2d"),
        displaylogo            = FALSE,
        toImageButtonOptions   = list(
          format   = "png",
          filename = paste0("grant_size_chart_", yrs_label),
          width    = 1400L,
          height   = 700L
        )
      )
  })
}

# ===========================================================
shinyApp(ui, server)
