ARG BASE=debian:bullseye-slim
FROM ${BASE}

ENV DEBIAN_FRONTEND=noninteractive
ENV RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo
ENV PATH=/opt/cargo/bin:$PATH

# Debian 11 esta archivado: sus repos viven en archive.debian.org (deb.debian.org/debian-security da 404)
RUN rm -f /etc/apt/sources.list.d/* \
    && printf 'deb http://archive.debian.org/debian bullseye main\ndeb http://archive.debian.org/debian-security bullseye-security main\n' > /etc/apt/sources.list \
    && printf 'Acquire::Check-Valid-Until "false";\nAcquire::Retries "5";\n' > /etc/apt/apt.conf.d/99archive

RUN dpkg --add-architecture arm64 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu \
        make file git curl ca-certificates pkg-config cmake \
        libsdl2-dev:arm64 \
    && rm -rf /var/lib/apt/lists/*

# Rust (el toolchain exacto lo fija src/OpenGMK/rust-toolchain.toml y se instala solo al compilar)
RUN curl -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain stable

ENV CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-linux-gnu-gcc \
    CC_aarch64_unknown_linux_gnu=aarch64-linux-gnu-gcc \
    AR_aarch64_unknown_linux_gnu=aarch64-linux-gnu-ar

WORKDIR /workspace
CMD ["bash"]
