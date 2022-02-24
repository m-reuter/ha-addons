ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

# install packages
# eventually pull pyhpsu master once mqtt is merged from testing
RUN apk add --no-cache \
    ca-certificates \
    git \
    python3 \
    py3-pip \
    \
    && pip3 install \
        --no-cache-dir \
        --prefer-binary \
        --upgrade \
        pip \
        setuptools \
        wheel \
    && pip3 install \
        --no-cache-dir \
        --prefer-binary \
        python-can==3.3.4 \
        serial \
        paho-mqtt \
        pika \
        requests \
        urllib3 \
    && find /usr/local \
        \( -type d -a -name test -o -name tests -o -name '__pycache__' \) \
        -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
        -exec rm -rf '{}' + \
    \
    && cd /opt \
    && git clone https://github.com/Spanni26/pyHPSU.git \
    && cd pyHPSU \
    && git fetch origin pull/51/head:mqtt \
    && git checkout mqtt \
    && chmod +x install.sh \
    && sh install.sh

# Copy data for add-on
COPY pyhpsu.conf /
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
