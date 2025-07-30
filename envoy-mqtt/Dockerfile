FROM envoyproxy/envoy:v1.25.10

# Установим зависимости
RUN apt-get update && \
    apt-get install -y curl jq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Скачиваем yq
RUN ARCH=$(uname -m) && \
    case "$ARCH" in \
        aarch64) YQ_BINARY="yq_linux_arm64" ;; \
        armv7l)  YQ_BINARY="yq_linux_arm" ;; \
        x86_64) YQ_BINARY="yq_linux_amd64" ;; \
        *) echo "Unsupported arch: $ARCH" && exit 1 ;; \
    esac && \
    curl -L "https://github.com/mikefarah/yq/releases/latest/download/${YQ_BINARY}" -o /usr/bin/yq && \
    chmod +x /usr/bin/yq

COPY run.sh /run.sh
RUN chmod +x /run.sh

USER root
CMD ["/run.sh"]
