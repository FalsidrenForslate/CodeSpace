FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG QEMU_VERSION=9.2.1

WORKDIR /build

RUN apt-get update && \
    apt-get install -y \
    curl \
    wget \
    git \
    python3 \
    python3-venv \
    build-essential \
    flex \
    bison \
    autoconf \
    automake \
    pkg-config \
    meson

RUN wget -q https://download.qemu.org/qemu-${QEMU_VERSION}.tar.xz && \
    tar xJf qemu-${QEMU_VERSION}.tar.xz && \
    rm qemu-${QEMU_VERSION}.tar.xz && \
    mv qemu-${QEMU_VERSION} qemu

WORKDIR /build/qemu

RUN apt-get update && \
    apt-get install -y \
    libglib2.0-dev libfdt-dev libpixman-1-dev zlib1g-dev ninja-build \
    git-email \
    libaio-dev libbluetooth-dev libcapstone-dev libbrlapi-dev libbz2-dev \
    libcap-ng-dev libcurl4-gnutls-dev libgtk-3-dev \
    libibverbs-dev libjpeg-dev libncurses5-dev libnuma-dev \
    librbd-dev librdmacm-dev \
    libsasl2-dev libsdl2-dev libseccomp-dev libsnappy-dev libssh-dev \
    libvde-dev libvdeplug-dev libvte-2.91-dev libxen-dev liblzo2-dev \
    valgrind xfslibs-dev \
    libnfs-dev libiscsi-dev

RUN ./configure --prefix=/usr/local --target-list="riscv64-softmmu loongarch64-softmmu riscv64-linux-user loongarch64-linux-user" --disable-werror

RUN make -j$(($(nproc) - 1)) && \
    make install

RUN rm -rf /build/qemu


ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --no-modify-path --profile minimal --default-toolchain nightly-2025-06-17


COPY rust-toolchain.toml rust-toolchain.toml
RUN rustup target add riscv64gc-unknown-none-elf && \
    cargo install toml-cli cargo-binutils && \
    RUST_VERSION=$(toml get -r rust-toolchain.toml toolchain.channel) && \
    Components=$(toml get -r rust-toolchain.toml toolchain.components | jq -r 'join(" ")') && \
    rustup install $RUST_VERSION && \
    rustup component add --toolchain $RUST_VERSION $Components

# 2.4. Set GDB
RUN ln -s /usr/bin/gdb-multiarch /usr/bin/riscv64-unknown-elf-gdb

RUN qemu-system-riscv64 --version && \
    qemu-riscv64 --version && \
    rustup --version && \
    cargo --version && \
    rustc --version && \
    riscv64-unknown-elf-gdb --version

WORKDIR /workspace
