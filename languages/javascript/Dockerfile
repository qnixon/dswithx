# JavaScript (Node.js) toolchain for dswithx. Built-in modules only: npm and
# npx are removed so no third-party packages can be installed into this image.
# (This Node release ships no corepack, so there is no yarn or pnpm either.)
FROM node:26.13.0-trixie-slim

RUN rm -rf /usr/local/lib/node_modules/npm /usr/local/bin/npm /usr/local/bin/npx

COPY run.sh /usr/local/bin/run.sh
USER nobody
