ARG BUILD_FROM=homeassistant/amd64-base:3.18
FROM $BUILD_FROM
ARG PYHPSU_REF=4fcb37d7c28c970073d720923c28dc781eb92a85

ENV LANG=C.UTF-8

# install packages
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
        --upgrade \
        python-can \
        pyserial \
        paho-mqtt \
        pika \
        requests \
        urllib3 \
    && find /usr/local \
        \( -type d -a -name test -o -name tests -o -name '__pycache__' \) \
        -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
        -exec rm -rf '{}' + \
    \
    && mkdir -p /opt/pyHPSU \
    && cd /opt/pyHPSU \
    && git init \
    && git remote add origin https://github.com/Spanni26/pyHPSU.git \
    && git fetch --depth 1 origin "${PYHPSU_REF}" \
    && git checkout --detach FETCH_HEAD \
    && chmod +x install.sh \
    && sh install.sh

# Copy data for add-on
COPY pyhpsu.conf /
COPY mqtt_command_daemon.py /usr/local/bin/mqtt_command_daemon.py
COPY run.sh /
RUN chmod a+x /run.sh /usr/local/bin/mqtt_command_daemon.py

CMD [ "/run.sh" ]
