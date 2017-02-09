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
RUN usermod -a -G sudo esp

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
RUN ./ct-ng xtensa-lx106-elf && ./ct-ng build

# Add path to toolchain binaries to your .bashrc: 
RUN echo "export PATH=$ESPRESSIF_HOME/crosstool-NG/builds/xtensa-lx106-elf/bin:\$PATH" >> ~/.bashrc

# Install ESP8266 RTOS SDK
WORKDIR ${ESPRESSIF_HOME}
RUN export ESP_SDK_HOME=$ESPRESSIF_HOME/esp-rtos-sdk
ENV ESP_SDK_HOME ${ESPRESSIF_HOME}/esp-rtos-sdk

RUN git clone https://github.com/espressif/esp_iot_rtos_sdk.git $ESP_SDK_HOME
WORKDIR ${ESP_SDK_HOME}
RUN git checkout 169a436ce10155015d056eab80345447bfdfade5
RUN wget -O lib/libhal.a https://github.com/esp8266/esp8266-wiki/raw/master/libs/libhal.a
WORKDIR $ESP_SDK_HOME/include/lwip/arch
RUN sed -i "s/#include \"c_types.h\"/\/\/#include \"c_types.h\"/" cc.h

# Install esptool
WORKDIR ${ESPRESSIF_HOME}
RUN git clone https://github.com/RostakaGmfun/esptool.git
WORKDIR esptool

# Copy adjusted esptool over git file
COPY esptool.py ${ESPRESSIF_HOME}/esptool

USER root
RUN python setup.py install
USER esp

# Clone sample app
ENV KAA_HOME /opt/kaa
ENV KAA_ESP_SAMPLE ${KAA_HOME}/doc/Programming-guide/Using-Kaa-endpoint-SDKs/C/SDK-ESP8266/attach/esp8266-sample
RUN export KAA_HOME=/opt/kaa

USER root
RUN mkdir -p ${KAA_HOME}
RUN chown -R esp:esp ${KAA_HOME}
USER esp

WORKDIR ${KAA_HOME}
RUN git clone https://github.com/kaaproject/kaa.git $KAA_HOME
RUN git checkout tags/v0.10.0 -b v0.10.0
COPY eagle.app.v6.ld ${KAA_ESP_SAMPLE}/ld

# Link sampe app to sample directory
ENV SAMPLE_APP_HOME /opt/sample_app
USER root
RUN mkdir -p ${SAMPLE_APP_HOME}
RUN chown -R esp:esp ${SAMPLE_APP_HOME}
USER esp

RUN ln -s ${KAA_ESP_SAMPLE} ${SAMPLE_APP_HOME}

# Start with user esp
USER esp
WORKDIR /opt
