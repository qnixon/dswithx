# R toolchain for dswithx. Base R only: the official image also ships R's
# "recommended" packages (MASS, lattice, ...) and littler, which are removed so
# implementations can use only base R and its bundled base-priority packages.
FROM r-base:4.6.2

# The image pins APT::Default-Release to "testing" but ships no package lists,
# which makes apt refuse to run; clear it for these removal-only commands.
RUN apt-mark -o APT::Default-Release= manual r-base-core \
 && apt-get -o APT::Default-Release= purge -y r-base r-base-dev r-recommended 'r-cran-*' \
 && apt-get -o APT::Default-Release= autoremove -y

COPY run.sh /usr/local/bin/run.sh
USER nobody
