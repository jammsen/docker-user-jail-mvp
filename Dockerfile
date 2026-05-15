FROM ubuntu:26.04@sha256:f3d28607ddd78734bb7f71f117f3c6706c666b8b76cbff7c9ff6e5718d46ff64

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