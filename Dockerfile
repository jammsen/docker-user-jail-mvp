FROM ubuntu:latest

ENV PUID=7351
ENV PGID=2431

RUN apt-get update \
    && apt-get install -y gosu --no-install-recommends \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --chmod=744 entrypoint.sh /

ENTRYPOINT ["./entrypoint.sh"]