FROM ubuntu:26.04@sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4

ENV PUID=7351
ENV PGID=2431

RUN apt-get update \
    && apt-get install -y gosu --no-install-recommends \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Optional: pre-create a user and group to simulate a base image that already ships with one.
# Uncomment to test the "Found user / Found group" path in entrypoint.sh.
# Comment back out to test the "NOT found, creating it" path.
# RUN groupadd steam --gid ${PGID} \
#     && useradd -g steam -m -d /home/steam -s /bin/bash steam --uid ${PUID}

COPY --chmod=744 entrypoint.sh /

ENTRYPOINT ["./entrypoint.sh"]