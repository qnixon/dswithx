# Go toolchain for dswithx. Programs use only the standard library: there is no
# go.mod, so nothing outside the standard library can be imported.
FROM golang:1.27.3-trixie

# The container's filesystem is read-only apart from /tmp, so the build cache,
# GOPATH, and home directory all live there. GOTOOLCHAIN=local stops Go from
# trying to download a different toolchain.
ENV GOCACHE=/tmp/go-cache \
    GOPATH=/tmp/go \
    HOME=/tmp \
    GOTOOLCHAIN=local

COPY run.sh /usr/local/bin/run.sh
USER nobody
