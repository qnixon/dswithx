# Common Lisp toolchain for dswithx: SBCL (Steel Bank Common Lisp), with no
# Quicklisp and no libraries. Packages come from snapshot.debian.org at the
# base image's date, so the pinned versions stay installable and the image is
# reproducible.
FROM debian:trixie-20261027-slim

RUN printf '%s\n' \
      'Types: deb' \
      'URIs: http://snapshot.debian.org/archive/debian/20261027T000000Z' \
      'Suites: trixie trixie-updates' \
      'Components: main' \
      'Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg' \
      > /etc/apt/sources.list.d/debian.sources \
 && apt-get -o Acquire::Check-Valid-Until=false update \
 && apt-get install -y --no-install-recommends sbcl=2:2.5.2-1 \
 && rm -rf /var/lib/apt/lists/*

ENV HOME=/tmp
COPY run.sh /usr/local/bin/run.sh
USER nobody
