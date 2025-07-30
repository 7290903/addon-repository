FROM envoyproxy/envoy:v1.29-latest

# Установим зависимости
RUN apt-get update && \
    apt-get install -y curl jq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Скачиваем yq для текущей архитектуры
RUN ARCH=$(uname -m) && \
    case "$ARCH" in \
        aarch64) YQ_BINARY="yq_linux_arm64" ;; \
        armv7l)  YQ_BINARY="yq_linux_arm" ;; \
        x86_64) YQ_BINARY="yq_linux_amd64" ;; \
        *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
    esac && \
    curl -L "https://github.com/mikefarah/yq/releases/latest/download/${YQ_BINARY}" -o /usr/bin/yq && \
    chmod +x /usr/bin/yq

# Копируем скрипт запуска
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Root для доступа к /config
USER root

# 🔽 Ограничение prealloc у tcmalloc (важно для ARM/Low-RAM)
ENV TCMALLOC_LARGE_ALLOC_REPORT_THRESHOLD=1048576
ENV TCMALLOC_HEAP_LIMIT_MB=128

CMD ["/run.sh"]


