ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

# install packages
#RUN apt-get update && \
#    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
RUN apk add --no-cache \
    ca-certificates \
    git \
    python3 \
    py3-pip 
RUN pip3 install --no-cache --upgrade pip setuptools wheel 
RUN pip3 install python-can serial paho-mqtt pika requests urllib3


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

