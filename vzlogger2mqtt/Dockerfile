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
# build vzlogger (need to remove -Werror for vzlogger.cpp)
RUN git clone -b upgrade_unity_to_v2.5.2 https://github.com/r00t-/libsml.git \
    && cd libsml && make && cd .. 
RUN git clone -b avoid_GLOB_BRACE https://github.com/r00t-/vzlogger.git \
    && cd vzlogger \
    && cmake . -DBUILD_TEST=off -DSML_HOME=../libsml/sml
RUN cd /vzlogger/ && make 
RUN cd /vzlogger/src && /usr/bin/c++ -DHAVE_CONFIG_HPP -I/libsml/sml/include -I/vzlogger -I/vzlogger/include -W -Wall \
       -Wextra -Wnon-virtual-dtor -Wno-system-headers -Winit-self -Wmissing-include-dirs -Wno-pragmas \
       -Wredundant-decls -Wno-unused-parameter -std=c++11 -fpermissive -Wno-error=redundant-decls \
       -Wno-ignored-qualifiers -g3 -o CMakeFiles/vzlogger.dir/vzlogger.cpp.o \
       -c /vzlogger/src/vzlogger.cpp 
RUN cd /vzlogger/  && make && cd ..


# Copy data for add-on
COPY vzlogger.conf /
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]

# Run CMD when started
#CMD /usr/local/bin/vzlogger --config /cfg/vzlogger.conf
