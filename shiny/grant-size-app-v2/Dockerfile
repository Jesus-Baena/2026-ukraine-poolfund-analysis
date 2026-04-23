FROM rocker/shiny-verse:latest

# Install packages used directly by app.R (pinning can be added later if needed).
RUN R -q -e "install.packages(c('shiny','bslib','dplyr','ggplot2','plotly','readr','scales','tidyr','glue'), repos='https://cloud.r-project.org')"

# Clean default example apps and copy this app as the root Shiny app.
RUN rm -rf /srv/shiny-server/*
COPY . /srv/shiny-server/

# Avoid serving build metadata.
RUN rm -f /srv/shiny-server/Dockerfile

EXPOSE 3838
