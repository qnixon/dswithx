# Swift toolchain for dswithx: the Swift compiler with its standard library
# and Foundation, with no Swift Package Manager dependencies. Packages come
# from snapshot.debian.org at the base image's date, so the pinned versions
# stay installable and the image is reproducible.
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
 && apt-get install -y --no-install-recommends swiftlang=6.0.3-2 libc6-dev=2.41-12+deb13u4 \
 && rm -rf /var/lib/apt/lists/*

# The compiler keeps a module cache in the home folder; /tmp is the only
# writable path when the tests run.
ENV HOME=/tmp
COPY run.sh /usr/local/bin/run.sh
USER nobody
