# ============================================================
# Grant Size vs Number of Grants per Organisation
# Interactive Shiny app — extends the static chart in
# ukraine-poolfund-report.qmd (section #sec-org-dotchart)
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
                            show_col_types = FALSE)
clusters_raw    <- read_csv("data/Cluster_ALL_20260219_100323_UTC.csv",
                            show_col_types = FALSE)

# Full dataset — no year floor, all org types included
grants <- project_summary %>%
  filter(!is.na(Budget), Budget > 0) %>%
  mutate(
    Context = if_else(PooledFundName == "Ukraine", "Ukraine UHF", "Global CBPF"),
    OrgType = case_when(
      OrganizationType == "International NGO" ~ "INGO",
      OrganizationType == "National NGO"      ~ "NNGO",
      OrganizationType == "UN Agency"         ~ "UN Agency",
      OrganizationType == "Others"            ~ "Others",
      TRUE                                    ~ NA_character_
    )
  ) %>%
  filter(!is.na(OrgType))

cl_primary <- clusters_raw %>%
  group_by(ChfId) %>%
  slice_max(Percentage, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  select(ChfId, Cluster) %>%
  mutate(Cluster = case_when(
    Cluster == "Water, Sanitation and Hygiene"     ~ "WASH",
    Cluster == "Emergency Shelter and NFI"         ~ "Shelter & NFI",
    Cluster == "Camp Coordination / Management"    ~ "Camp Coord./Mgmt",
    Cluster == "Coordination and Support Services" ~ "Coord. & Support",
    Cluster == "Emergency Telecommunications"      ~ "Telecoms",
    TRUE ~ Cluster
  ))

grants_cl <- grants %>%
  left_join(cl_primary, by = "ChfId") %>%
  mutate(
    Cluster   = replace_na(Cluster, "Unknown"),
    is_health = Cluster == "Health"
  )

year_min <- min(grants_cl$AllocationYear, na.rm = TRUE)
year_max <- max(grants_cl$AllocationYear, na.rm = TRUE)

# Colour palette — identical to the report
dot_colors <- c(
  "Ukraine UHF"                 = "#f4a261",
  "Global CBPF"                 = "#94d2bd",
  "Health (≥50% health grants)" = "#e63946"
)

# ===========================================================
# UI
# ===========================================================

ui <- fluidPage(

  tags$head(
    tags$style(HTML("
      body { font-family: 'Segoe UI', Arial, sans-serif; background: #f8f9fa; }
      .well { background: #ffffff; border: 1px solid #dee2e6; border-radius: 6px; }
      h2 { color: #005f73; font-weight: 700; margin-bottom: 4px; }
      .subtitle { color: #555; font-size: 0.92em; margin-bottom: 16px; }
      .control-label { font-weight: 600; color: #333; }
      #reset_click { margin-top: 4px; width: 100%; }
      .selected-org-box {
        background: #fff3e0; border: 1px solid #f4a261;
        border-radius: 4px; padding: 6px 10px;
        font-size: 0.88em; color: #333; margin-top: 6px;
      }
    "))
  ),

  div(style = "padding: 10px 15px 4px 15px;",
    tags$h4(style = "color:#005f73; font-weight:700; margin:0;",
            "Grant Size vs Number of Grants per Organisation"),
    tags$small(style = "color:#666;",
               "CBPF global dataset · Feb 2026 extract · All 28 pooled funds")
  ),

  sidebarLayout(
    sidebarPanel(
      width = 3,

      sliderInput("years",
                  "Year range:",
                  min   = year_min,
                  max   = year_max,
                  value = c(2022L, 2025L),
                  step  = 1L,
                  sep   = ""),

      hr(),

      checkboxGroupInput("org_type",
                         "Organisation type:",
                         choices  = c("INGO", "NNGO", "UN Agency", "Others"),
                         selected = c("INGO", "NNGO", "UN Agency")),

      hr(),

      checkboxGroupInput("context",
                         "Context:",
                         choices  = c("Ukraine UHF", "Global CBPF"),
                         selected = c("Ukraine UHF", "Global CBPF")),

      hr(),

      textInput("org_search",
                "Highlight org (partial name):",
                placeholder = "e.g. Médecins, UNHCR…"),

      uiOutput("search_hit_count"),

      hr(),

      checkboxInput("show_ellipse",
                    "Show 'UHF Exception' annotation",
                    value = TRUE),

      checkboxInput("clip_axes",
                    "Focus on Ukraine range",
                    value = TRUE),

      hr(),

      actionButton("reset_click", "Clear selected org",
                   icon = icon("times-circle"), class = "btn-sm btn-outline-secondary"),

      uiOutput("selected_org_info"),

      hr(),

      uiOutput("summary_counts")
    ),

    mainPanel(
      width = 9,
      plotlyOutput("chart", height = "680px"),
      div(style = "font-size:0.8em; color:#888; margin-top:6px; text-align:right;",
          "Click a dot to highlight · Search box adds gold rings · Zoom / pan with mouse")
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
        selected_org(NULL)          # click same dot → deselect
      } else {
        selected_org(click$key)
      }
    }
  })

  observeEvent(input$reset_click, {
    selected_org(NULL)
  })

  # --- aggregated data reactive ------------------------------
  org_stats <- reactive({
    req(length(input$org_type) > 0, length(input$context) > 0)

    grants_cl %>%
      filter(
        AllocationYear >= input$years[1],
        AllocationYear <= input$years[2],
        OrgType  %in% input$org_type,
        Context  %in% input$context,
        !is.na(Budget), Budget > 0,
        !is.na(OrganizationName)
      ) %>%
      group_by(Context, OrganizationName, OrganizationType, OrgType) %>%
      summarise(
        n_grants    = n(),
        median_size = median(Budget),
        total_usd   = sum(Budget),
        pct_health  = mean(Cluster == "Health"),
        .groups     = "drop"
      ) %>%
      mutate(
        dot_group = case_when(
          pct_health >= 0.5        ~ "Health (≥50% health grants)",
          Context == "Ukraine UHF" ~ "Ukraine UHF",
          TRUE                     ~ "Global CBPF"
        ),
        tooltip = glue(
          "<b>{OrganizationName}</b><br>",
          "Type: {OrganizationType}<br>",
          "Context: {Context}<br>",
          "# Grants: {n_grants}<br>",
          "Median size: {dollar(median_size, accuracy = 1, scale_cut = cut_short_scale())}<br>",
          "Total disbursed: {dollar(total_usd, accuracy = 1, scale_cut = cut_short_scale())}<br>",
          "Health share: {percent(pct_health, accuracy = 1)}"
        )
      )
  })

  # --- sidebar info widgets ---------------------------------
  output$summary_counts <- renderUI({
    data <- org_stats()
    n_orgs    <- nrow(data)
    n_ukr     <- sum(data$Context == "Ukraine UHF")
    n_global  <- sum(data$Context == "Global CBPF")
    total_usd <- sum(data$total_usd, na.rm = TRUE)

    div(
      tags$small(
        tags$b(n_orgs), " organisations shown",
        tags$br(),
        tags$b(n_ukr), " Ukraine UHF · ",
        tags$b(n_global), " Global CBPF",
        tags$br(),
        "Total disbursed: ",
        tags$b(dollar(total_usd, scale_cut = cut_short_scale(), accuracy = 0.01))
      )
    )
  })

  output$search_hit_count <- renderUI({
    term <- trimws(input$org_search)
    if (nchar(term) == 0) return(NULL)
    data <- org_stats()
    n <- sum(grepl(term, data$OrganizationName, ignore.case = TRUE))
    div(style = "font-size:0.82em; color:#888; margin-top:2px;",
        glue("{n} org{ifelse(n==1,'','s')} matched"))
  })

  output$selected_org_info <- renderUI({
    sel <- selected_org()
    if (is.null(sel)) return(NULL)
    data <- org_stats()
    row  <- data %>% filter(OrganizationName == sel)
    if (nrow(row) == 0) return(NULL)
    div(
      class = "selected-org-box",
      tags$b("Selected:"), br(),
      sel, br(),
      glue("{row$n_grants[1]} grants · ",
           "{dollar(row$median_size[1], scale_cut=cut_short_scale(), accuracy=0.01)} median · ",
           "{dollar(row$total_usd[1], scale_cut=cut_short_scale(), accuracy=0.01)} total")
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

    # Axis limits: always pin x left at 0.5 so Y-axis sits at the left edge;
    # optionally clip right/top to Ukraine range + buffer
    if (input$clip_axes && any(data$Context == "Ukraine UHF")) {
      ukr_rows  <- data %>% filter(Context == "Ukraine UHF")
      x_right   <- max(ukr_rows$n_grants)    + 3
      y_top     <- max(ukr_rows$median_size) + 4e6
    } else {
      x_right   <- NA
      y_top     <- NA
    }

    # Parametric ellipse (log-y space, same as report)
    theta      <- seq(0, 2 * pi, length.out = 200)
    ellipse_df <- data.frame(
      x = 9 + 4.2 * cos(theta),
      y = 10^(6.45 + 0.55 * sin(theta))
    )

    # Search highlight layer
    search_term  <- trimws(input$org_search)
    has_search   <- nchar(search_term) > 0
    data_search  <- if (has_search) {
      data %>% filter(grepl(search_term, OrganizationName, ignore.case = TRUE))
    } else {
      data[0, ]
    }

    # Click-selected org
    sel_org  <- selected_org()
    data_sel <- if (!is.null(sel_org) && sel_org %in% data$OrganizationName) {
      data %>% filter(OrganizationName == sel_org)
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
                    key   = OrganizationName)) +
      geom_point(alpha = 0.65, stroke = 0)

    # Ellipse annotation
    if (input$show_ellipse) {
      p <- p +
        geom_path(data        = ellipse_df,
                  aes(x = x, y = y),
                  inherit.aes = FALSE,
                  color       = "black",
                  linewidth   = 0.8,
                  linetype    = "solid") +
        annotate("text",
                 x        = 9,
                 y        = 10^6.9,
                 label    = "The UHF Exception",
                 hjust    = 0.5, vjust = 1,
                 size     = 4, fontface = "bold.italic",
                 color    = "black")
    }

    # Gold rings for search matches
    if (nrow(data_search) > 0) {
      p <- p +
        geom_point(data        = data_search,
                   aes(x = n_grants, y = median_size),
                   inherit.aes = FALSE,
                   shape       = 21,
                   color       = "#FFD700",
                   fill        = NA,
                   size        = 6,
                   stroke      = 2,
                   alpha       = 1)
    }

    # Black ring for clicked org
    if (nrow(data_sel) > 0) {
      p <- p +
        geom_point(data        = data_sel,
                   aes(x = n_grants, y = median_size),
                   inherit.aes = FALSE,
                   shape       = 21,
                   color       = "#222222",
                   fill        = NA,
                   size        = 8,
                   stroke      = 2.5,
                   alpha       = 1)
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
        values = dot_colors,
        name   = NULL,
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
        x       = paste0("Number of grants received (", yrs_label, ")"),
        y       = "Median grant size (USD, log scale)",
        caption = "Source: CBPF ProjectSummary dataset, Feb 2026 extract."
      ) +
      theme_minimal(base_size = 13) +
      theme(
        legend.position  = c(0.98, 0.98),
        legend.justification = c(1, 1),
        legend.background = element_rect(fill = alpha("white", 0.85), colour = "grey85", linewidth = 0.3),
        legend.margin    = margin(4, 6, 4, 6),
        panel.grid.minor = element_blank()
      )

    # ---- convert to plotly -----------------------------------
    ggplotly(p, tooltip = "text", source = "dotchart") %>%
      layout(
        hoverlabel = list(
          bgcolor  = "white",
          font     = list(size = 12, family = "Segoe UI, Arial"),
          align    = "left"
        ),
        margin = list(t = 10, b = 50, l = 10, r = 10)
      ) %>%
      config(
        displayModeBar          = TRUE,
        modeBarButtonsToRemove  = c("select2d", "lasso2d", "autoScale2d"),
        displaylogo             = FALSE,
        toImageButtonOptions    = list(
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
