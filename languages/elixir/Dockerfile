# Elixir toolchain for dswithx: Elixir on the Erlang runtime, with their
# standard libraries and no Hex packages. Packages come from
# snapshot.debian.org at the base image's date, so the pinned versions stay
# installable and the image is reproducible.
FROM debian:trixie-20261027-slim

RUN printf '%s\n' \
      'Types: deb' \
      'URIs: http://snapshot.debian.org/archive/debian/20261027T000000Z' \
      'Suites: trixie trixie-updates' \
      'Components: main' \
      'Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg' \
      > /etc/apt/sources.list.d/debian.sources \
 && apt-get -o Acquire::Check-Valid-Until=false update \
 && apt-get install -y --no-install-recommends elixir=1.18.3.dfsg-1 erlang-base=1:27.3.4.1+dfsg-1+deb13u3 \
 && rm -rf /var/lib/apt/lists/*

COPY run.sh /usr/local/bin/run.sh
USER nobody
