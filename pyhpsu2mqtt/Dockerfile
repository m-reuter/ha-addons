ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

# install packages
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    ca-certificates \
    git \
    python3 \
    python3-can \
    python3-serial \
    python3-mysqldb \
    python3-paho-mqtt \
    python3-pika \
    python3-requests \
    python3-urllib3 \
    && rm -rf /var/lib/apt/lists/*

# install pyHPSU
RUN cd /opt \
    && git clone https://github.com/Spanni26/pyHPSU.git \
    && cd pyHPSU \
    && git fetch origin pull/44/head:mqtt \
    && git checkout mqtt \
    && chmod +x install.sh \
    && sh install.sh


# Copy data for add-on
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]

