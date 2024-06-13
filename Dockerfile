FROM ubuntu:latest

LABEL maintainer="troy brumley blametroi@gmail.com"
LABEL purpose="an environment for simple fortran development and debugging"

# this establishes a container to run for debugging gfortran code on
# my macbook air, which has an m2 chip. the gdb folks aren't working
# on macos support, and macos has moved into the llvm camp, but there
# isn't a "it just works" llvm fortran compiler available for llvm
# yet.
#
# sources are malik sahil's docker-ubunto-sahil
# and milan curcic's modern-fortran-docker
# both on github.
#
# to build the image:
#
# docker build --rm -f Dockerfile -t <build name> .
#
# to start the container:
#
# docker run -v <path to source or project on host>:/src -it <build name>

# first, install sudo
RUN apt-get -yq update && apt-get -yq install sudo

# second, make a user account for everything else
RUN echo "programmer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN useradd --no-log-init --home-dir /home/programmer --create-home --shell /bin/bash programmer
RUN adduser programmer sudo

# switch to the user account
USER programmer
WORKDIR /home/programmer

# Install necessary tools for Fortran development, debugging, Python, and Mamba
RUN sudo apt-get -yq update && \
    sudo apt-get -yq install git curl bzip2 vim-tiny make cmake pkg-config gfortran gdb python3 python3-pip && \
    sudo apt-get -yq install meson ninja-build && \
    sudo apt-get clean -q

# Install Mamba
RUN curl -fsSL https://micro.mamba.pm/api/micromamba/linux-aarch64/latest | tar -xvj bin/micromamba && \
    sudo mv bin/micromamba /usr/local/bin/micromamba && \
    rm -rf bin

# Create a conda environment directory
RUN mkdir /home/programmer/mamba

# Configure environment variables for Mamba
ENV MAMBA_ROOT_PREFIX=/home/programmer/mamba
ENV PATH=$MAMBA_ROOT_PREFIX/bin:$PATH

# Initialize Micromamba in a non-interactive shell and create a base environment
RUN /usr/local/bin/micromamba shell init -s bash -p $MAMBA_ROOT_PREFIX

COPY env.yml /home/programmer/
RUN micromamba env create -f /home/programmer/env.yml

SHELL ["bash", "-c"]
# use the following if needed to get parts needed for curcic's text:
#
# from apt libcoarrays-dev libopenmpi-dev open-coarrays-bin
#
# and the modern fortran repos
#
# the base stuff
# RUN git clone https://github.com/modern-fortran/tsunami
# RUN git clone https://github.com/modern-fortran/stock-prices
# RUN git clone https://github.com/modern-fortran/weather-buoys
# RUN git clone https://github.com/modern-fortran/generic-procedures
# RUN git clone https://github.com/modern-fortran/countdown
# RUN git clone https://github.com/modern-fortran/tcp-client-server
# RUN git clone https://github.com/modern-fortran/listings
#
# extras
# RUN git clone https://github.com/modern-fortran/neural-fortran
# RUN git clone https://github.com/wavebitscientific/datetime-fortran

# finally, start a terminal session to compile and debug
USER programmer
ENV TERM xterm
CMD ["bash"]
