# Image for compiling KAA SDK projects for NodeMCU/ESP8266
# Taken from: https://kaaproject.github.io/kaa/docs/v0.10.0/Programming-guide/Using-Kaa-endpoint-SDKs/C/SDK-ESP8266/


# Create an image based on the latest Ubuntu
FROM ubuntu:latest

# Prerequisites

RUN apt-get -y update
RUN apt-get install -y autoconf libtool libtool-bin bison build-essential gawk git gperf flex texinfo libncurses5-dev libc6-dev python-serial libexpat-dev python-setuptools wget sudo nano cmake

# Add esp user
RUN adduser --disabled-password --gecos "" esp && su esp
RUN echo 'esp:esp' | chpasswd
RUN echo 'root:root' | chpasswd

# Create working directory and chown it to esp user
ENV ESPRESSIF_HOME /opt/Espressif/
RUN export ESPRESSIF_HOME=/opt/Espressif/
RUN mkdir -p ${ESPRESSIF_HOME}
WORKDIR ${ESPRESSIF_HOME}
RUN chown -R esp:esp ${ESPRESSIF_HOME}

# Switch to user esp
USER esp

# Install toolchain 
RUN git clone -b lx106 git://github.com/jcmvbkbc/crosstool-NG.git
WORKDIR crosstool-NG
RUN ./bootstrap && ./configure --prefix=$(pwd)
RUN make

# install must be done by root, switch back afterwards
USER root
RUN make install

USER esp
RUN ./ct-ng xtensa-lx106-elf
RUN ./ct-ng build

# Add path to toolchain binaries to your .bashrc: 
RUN echo "export PATH=$ESPRESSIF_HOME/crosstool-NG/builds/xtensa-lx106-elf/bin:\$PATH" >> ~/.bashrc
RUN cat ~/.bashrc

# Install ESP8266 RTOS SDK
WORKDIR ${ESPRESSIF_HOME}
RUN export ESP_SDK_HOME=$ESPRESSIF_HOME/esp-rtos-sdk
ENV ESP_SDK_HOME ${ESPRESSIF_HOME}/esp-rtos-sdk

RUN git clone https://github.com/espressif/esp_iot_rtos_sdk.git $ESP_SDK_HOME
WORKDIR ${ESP_SDK_HOME}
RUN git checkout 169a436ce10155015d056eab80345447bfdfade5
RUN wget -O lib/libhal.a https://github.com/esp8266/esp8266-wiki/raw/master/libs/libhal.a


# Install esptool
WORKDIR ${ESPRESSIF_HOME}
RUN git clone https://github.com/RostakaGmfun/esptool.git
WORKDIR esptool
RUN python setup.py install --user

# Start with user root
USER root
WORKDIR /opt
