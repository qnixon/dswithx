# APL toolchain for dswithx: GNU APL, built from the signed GNU source release.
# Build tools come from snapshot.debian.org at the base image's date so the
# image is reproducible, and only the built interpreter is kept.
FROM debian:trixie-20261027-slim AS build

RUN printf '%s\n' \
      'Types: deb' \
      'URIs: http://snapshot.debian.org/archive/debian/20261027T000000Z' \
      'Suites: trixie trixie-updates' \
      'Components: main' \
      'Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg' \
      > /etc/apt/sources.list.d/debian.sources \
 && apt-get -o Acquire::Check-Valid-Until=false update \
 && apt-get install -y --no-install-recommends g++ make \
 && rm -rf /var/lib/apt/lists/*

# apl-2.0.tar.gz from ftp.gnu.org/gnu/apl, signed by its maintainer.
ADD --checksum=sha256:24bbb744fce47e62837234a053bdeecee51b9ea61c82c79f7cc191bc6a54c0a1 \
    https://ftp.gnu.org/gnu/apl/apl-2.0.tar.gz /src/apl.tar.gz
RUN cd /src && tar xzf apl.tar.gz && cd apl-2.0 \
 && ./configure --prefix=/opt/apl \
 && make -j"$(nproc)" \
 && make install

FROM debian:trixie-20261027-slim
COPY --from=build /opt/apl /opt/apl
ENV PATH=/opt/apl/bin:$PATH \
    HOME=/tmp
COPY run.sh /usr/local/bin/run.sh
USER nobody
