# Julia toolchain for dswithx. Programs use only Base and the standard library
# that ships with Julia. Pkg is part of that standard library, but tests run
# with no network, so it cannot download anything.
FROM julia:1.13.3-trixie

# The filesystem is read-only apart from /tmp, and Julia keeps its compile
# cache under ~/.julia, so the home directory lives there.
ENV HOME=/tmp

COPY run.sh /usr/local/bin/run.sh
USER nobody
