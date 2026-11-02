# Java toolchain for dswithx: OpenJDK 21, the long-term-support release, with
# no build tool and no third-party libraries. Packages come from
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
 && mkdir -p /usr/share/man/man1 \
 && apt-get install -y --no-install-recommends openjdk-21-jdk-headless=21.0.12.1+1-1~deb13u1 \
 && rm -rf /var/lib/apt/lists/*

COPY run.sh /usr/local/bin/run.sh
USER nobody
