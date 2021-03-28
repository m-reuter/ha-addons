ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

# install packages
RUN apk add --no-cache \
    build-base git util-linux-dev cmake \
    json-c-dev libmicrohttpd-dev openssl-dev \
    curl-dev gnutls-dev libgcrypt-dev \
    cyrus-sasl-dev libunistring-dev mosquitto-dev
    

# build libsml and 
# build vzlogger (need to remove -Werror for vzlogger.cpp invalid conversion warning)
RUN git clone -b upgrade_unity_to_v2.5.2 https://github.com/r00t-/libsml.git \
    && cd libsml && make && make install && cd .. \
    && git clone -b avoid_GLOB_BRACE https://github.com/r00t-/vzlogger.git \
    && cd vzlogger \
    && sed -i "s/-Werror/ /g" "./modules/CompilerFlags.cmake" \
    && cmake . -DBUILD_TEST=off -DSML_HOME=../libsml/sml \
    && make && make install


# Copy data for add-on
COPY vzlogger.conf /
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]

