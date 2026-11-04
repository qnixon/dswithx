# Lua toolchain for dswithx: the lua interpreter and its standard library,
# with no extra modules from LuaRocks. Packages come from
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
 && printf 'Acquire::Retries "5";\n' > /etc/apt/apt.conf.d/80-retries \
 && apt-get -o Acquire::Check-Valid-Until=false update \
 && apt-get install -y --no-install-recommends lua5.4=5.4.7-1+b2 liblua5.4-0=5.4.7-1+b2 \
 && rm -rf /var/lib/apt/lists/*

COPY run.sh /usr/local/bin/run.sh
USER nobody
