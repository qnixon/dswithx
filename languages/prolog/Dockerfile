# Prolog toolchain for dswithx: SWI-Prolog's core system and the libraries
# that come with it, with no packs. Packages come from snapshot.debian.org at
# the base image's date, so the pinned versions stay installable and the
# image is reproducible.
FROM debian:trixie-20261027-slim

RUN printf '%s\n' \
      'Types: deb' \
      'URIs: http://snapshot.debian.org/archive/debian/20261027T000000Z' \
      'Suites: trixie trixie-updates' \
      'Components: main' \
      'Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg' \
      > /etc/apt/sources.list.d/debian.sources \
 && apt-get -o Acquire::Check-Valid-Until=false update \
 && apt-get install -y --no-install-recommends swi-prolog-core=9.2.9+dfsg-1 \
 && rm -rf /var/lib/apt/lists/*

ENV HOME=/tmp
COPY run.sh /usr/local/bin/run.sh
USER nobody
