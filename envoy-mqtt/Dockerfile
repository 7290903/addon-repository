# ✅ Базовый образ на Debian + Envoy + yq + jq
FROM debian:bullseye-slim

# Установим зависимости и Envoy
RUN apt-get update && \
    apt-get install -y curl gnupg2 lsb-release jq ca-certificates && \
    curl -sL "https://getenvoy.io/gpg" | gpg --dearmor -o /usr/share/keyrings/envoy-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/envoy-archive-keyring.gpg] https://deb.getenvoy.io stable main" > /etc/apt/sources.list.d/envoy-stable.list && \
    apt-get update && \
    apt-get install -y getenvoy-envoy && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Установка yq
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

# ENV для tcmalloc проблем
ENV TCMALLOC_HEAP_LIMIT_MB=64
ENV TCMALLOC_LARGE_ALLOC_REPORT_THRESHOLD=1048576
ENV LD_PRELOAD=""

# Root для доступа к /config
USER root

# Точка входа
CMD ["/run.sh"]
