ARG GOLANG_RELEASE=1.20.7

FROM debian:bullseye-slim

ARG GOLANG_RELEASE

ENV GOLANG_RELEASE=${GOLANG_RELEASE}

ADD config/prompt /tmp/prompt
ADD scripts /

LABEL org.opencontainers.image.authors "Claude Juif <claude.juif@gmail.com>"
LABEL org.opencontainers.image.title "GoLang $GOLANG_RELEASE"
LABEL org.opencontainers.image.version $GOLANG_RELEASE
LABEL org.opencontainers.image.description "GoLang ${GOLANG_RELEASE} image based on Debian Bullseye. Meant to be use as remote container in VSCode"

# Install base system
RUN set -x; \
    apt update -q -y; \
    DEBIAN_FRONTEND=noninteractive apt upgrade -q -y; \
    DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
    ca-certificates \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    dirmngr \
    openssh-client \
    curl \
    wget \
    make \
    git \
    gnupg \
    sudo \
    zip \
    unzip \
    xz-utils \
    pkg-config

RUN set -x; \
    /install-docker.sh; \
    rm -rf /var/lib/apt/lists/*

# Install go
RUN set -x; \
    cd /tmp; \
    wget -q https://go.dev/dl/go${GOLANG_RELEASE}.linux-amd64.tar.gz; \
    tar -C /usr/local -xzf go${GOLANG_RELEASE}.linux-amd64.tar.gz; \
    echo "PATH=$PATH:/home/godev/go/bin:/usr/local/go/bin" >> /etc/profile

# Setup Go user environement
RUN set -ex; \
    useradd -g users -m -s /bin/bash godev; \
    usermod -aG docker godev; \
    cat /tmp/prompt >> /home/godev/.bashrc; \
    echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config; \
    echo "godev ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/godev; \
    rm -f /tmp/prompt

# Switch to godev user
USER godev

# Install vscode and go tools
RUN set -ex; \
    export PATH=$PATH:/usr/local/go/bin; \
    go install -v golang.org/x/tools/gopls@latest; \
    go install -v github.com/go-delve/delve/cmd/dlv@latest; \
    go install -v honnef.co/go/tools/cmd/staticcheck@latest; \
    /install-vscode.sh; \
    sudo rm -f /install-vscode.sh

CMD ["bash"]