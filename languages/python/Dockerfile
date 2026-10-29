# Python toolchain for dswithx. Standard library only: pip is removed so no
# third-party packages can be installed into this image.
FROM python:3.15.2-slim-trixie

RUN python3 -m pip uninstall --yes pip

ENV PYTHONDONTWRITEBYTECODE=1
COPY run.sh /usr/local/bin/run.sh
USER nobody
