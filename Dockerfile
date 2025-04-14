FROM rstudio/plumber:v1.2.0

LABEL maintainer='Carter Thunes'

RUN apt-get update && \
    apt-get install -y \
        build-essential=12.10ubuntu1 \
        libcurl4-openssl-dev=8.5.0-2ubuntu10.6 \
        libfontconfig1-dev=2.15.0-1.1ubuntu2 \
        libfribidi-dev=1.0.13-3build1 \
        libharfbuzz-dev=8.3.0-2build2 \
        libfreetype6-dev=2.13.2+dfsg-1build3 \
        libjpeg-dev=8c-2ubuntu11 \
        libpng-dev=1.6.43-5build1 \
        libtiff5-dev=4.5.1+git230720-4ubuntu2.2 \
        pandoc=3.1.3+ds-2

# Use apt-cache to get a dependency file version and add to the list above if necessary
# RUN apt-cache policy pandoc

ARG MRAN=2024-09-11

# Install package dependencies here
RUN R -e "install.packages('devtools', repos='https://packagemanager.posit.co/cran/${MRAN}', method='libcurl')" \
 && R -e "install.packages('dplyr', repos='https://packagemanager.posit.co/cran/${MRAN}', method='libcurl')" \
 && R -e "install.packages('ggplot2', repos='https://packagemanager.posit.co/cran/${MRAN}', method='libcurl')" \
 && R -e "install.packages('scales', repos='https://packagemanager.posit.co/cran/${MRAN}', method='libcurl')" \
 && R -e "install.packages('stringr', repos='https://packagemanager.posit.co/cran/${MRAN}', method='libcurl')" \
 && R -e "install.packages('gridExtra', repos='https://packagemanager.posit.co/cran/${MRAN}', method='libcurl')" \
 && R -e "install.packages('ggiraph', repos='https://packagemanager.posit.co/cran/${MRAN}', method='libcurl')" \
 && R -e "install.packages('manipulateWidget', repos='https://packagemanager.posit.co/cran/${MRAN}', method='libcurl')"


ADD . /RTplot
RUN R -e "devtools::install_local('/RTplot',upgrade = 'never')"

EXPOSE 38000

ENTRYPOINT ["R", "-e", "pr <- plumber::plumb(rev(commandArgs())[1]);pr$handle('GET', '/_ping', function(req, res) {res$setHeader('Content-Type', 'application/json');res$status <- 200L;res$body <- '';res}); pr$run(host='0.0.0.0', port=38000)"]

# Check the /_ping endpoint every 30 seconds.
# --start-period=30s <- add start period after timeout once docker is upgraded
HEALTHCHECK --interval=30s --timeout=5s \
  CMD curl --silent --fail http://0.0.0.0:38000/_ping || exit 1

CMD ["/RTplot/R/RTplotapi.R"]
