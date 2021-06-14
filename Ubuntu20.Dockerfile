# Adapted from https://solarframework.github.io/install/linux/
FROM ubuntu:20.04

# Install essentials
RUN set -eux && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        git curl file wget zip pkg-config sudo locales
RUN localedef -i en_US -f UTF-8 en_US.UTF-8

ARG DEBIAN_FRONTEND=noninteractive

# Build tools
RUN set -eux && \
    apt-get install -y qt5-default && \
    apt-get install -y g++

# Install brew
# https://stackoverflow.com/a/58293459/2239938
RUN apt-get install build-essential curl file git ruby-full locales --no-install-recommends -y
RUN useradd -m -s /bin/bash linuxbrew && \
    echo 'linuxbrew ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER linuxbrew
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
USER root
ENV PATH="/home/linuxbrew/.linuxbrew/bin:${PATH}"
RUN brew --version

# Install remaken
RUN set -eux && \
    mkdir -p /root/.remaken/ && \
    brew tap b-com/sft && \
    brew install remaken

# Configure remaken
RUN remaken init --tag latest
RUN remaken profile init --cpp-std 17 -b gcc -o linux -a x86_64
ENV LD_LIBRARY_PATH="/root/.linuxbrew/Cellar/python@3.9/3.9.2_1/lib:${LD_LIBRARY_PATH}"
ENV PKG_CONFIG_PATH="/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig"
ENV REMAKEN_RULES_ROOT="/root/.remaken/rules/"

# Configure conan
RUN conan profile new default --detect && \
    conan profile update settings.compiler.libcxx=libstdc++11 default && \
    conan profile update settings.compiler.cppstd=17 default
RUN conan remote add bincrafters https://api.bintray.com/conan/bincrafters/public-conan --insert
RUN conan remote add conan-solar https://artifact.b-com.com/api/conan/solar-conan-local --insert


# Install SolAR dependencies
WORKDIR /tmp
COPY ./packagedependencies.txt /tmp/packagedependencies.txt
COPY ./packagedependencies-linux.txt /tmp/packagedependencies-linux.txt

RUN apt-get install -y autoconf libtool

RUN conan install ffmpeg/4.2.1@bincrafters/stable --build
RUN remaken install packagedependencies.txt
# RUN remaken install -c debug packagedependencies.txt

WORKDIR /root

