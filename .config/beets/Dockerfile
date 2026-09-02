# beets 2.13.1, self-built (host Python is PEP 668 externally-managed).
# Build (UID/GID must match host user so /config and /music writes are owned
# by the host user; defaults 1000/1000 = derek):
#   docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) \
#       -t beets-derek:2.13.1 ~/.config/beets
FROM python:3.13-slim

ARG BEETS_VERSION=2.13.1
ARG UID=1000
ARG GID=1000

# ffmpeg               -> replaygain 'ffmpeg' backend (ebur128) + fpcalc decoder
# libchromaprint-tools -> fpcalc binary required by the chroma plugin
RUN apt-get update \
    && apt-get install -y --no-install-recommends ffmpeg libchromaprint-tools \
    && rm -rf /var/lib/apt/lists/*

# Extras map 1:1 to enabled plugins. No replaygain extra (ffmpeg backend needs
# no pip deps), no web extra (no web service).
RUN pip install --no-cache-dir \
    "beets[fetchart,embedart,lyrics,lastgenre,chroma,scrub]==${BEETS_VERSION}"

RUN groupadd --gid "${GID}" beets \
    && useradd --uid "${UID}" --gid "${GID}" --no-create-home --shell /usr/sbin/nologin beets

# BEETSDIR names the dir containing config.yaml (mounted from host); relative
# paths in config.yaml (library.db, state.pickle) resolve under it.
ENV BEETSDIR=/config \
    HOME=/config \
    PYTHONUNBUFFERED=1

USER beets

ENTRYPOINT ["beet"]
CMD ["--help"]
