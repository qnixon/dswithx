# Perl toolchain for dswithx: the perl interpreter and its core modules,
# with no extra modules from CPAN. Packages come from
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
 && apt-get install -y --no-install-recommends perl=5.40.1-6+deb13u1 perl-modules-5.40=5.40.1-6+deb13u1 libperl5.40=5.40.1-6+deb13u1 \
 && rm -rf /var/lib/apt/lists/*

COPY run.sh /usr/local/bin/run.sh
USER nobody
