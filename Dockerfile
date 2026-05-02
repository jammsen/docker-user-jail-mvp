FROM ubuntu:26.04@sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4

ENV PUID=7351
ENV PGID=2431

RUN apt-get update \
    && apt-get install -y gosu --no-install-recommends \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --chmod=744 entrypoint.sh /

ENTRYPOINT ["./entrypoint.sh"]