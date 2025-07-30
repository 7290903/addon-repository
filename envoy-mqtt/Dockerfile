FROM debian:bullseye-slim

# Устанавливаем зависимости и переменные окружения для Envoy (решение проблем с tcmalloc)
ENV DEBIAN_FRONTEND=noninteractive
ENV TCMALLOC_HEAP_LIMIT_MB=128
ENV TCMALLOC_LARGE_ALLOC_REPORT_THRESHOLD=1048576
ENV LD_PRELOAD=""

# Установка Envoy Proxy + утилит
RUN apt-get update && \
    apt-get install -y curl ca-certificates gnupg jq wget lsb-release && \
    curl -sL 'https://getenvoy.io/gpg' | gpg --dearmor -o /usr/share/keyrings/envoy-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/envoy-archive-keyring.gpg] https://packages.tetratelabs.io/public/envoy/deb/$(lsb_release -cs) $(lsb_release -cs) main" \
      | tee /etc/apt/sources.list.d/envoy.list && \
    apt-get update && \
    apt-get install -y getenvoy-envoy && \
    rm -rf /var/lib/apt/lists/*

# Установка yq (арх зависит от архитектуры)
RUN ARCH=$(uname -m) && \
    case "$ARCH" in \
        aarch64)  YQ_BINARY="yq_linux_arm64" ;; \
        armv7l)   YQ_BINARY="yq_linux_arm" ;; \
        x86_64)   YQ_BINARY="yq_linux_amd64" ;; \
        *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
    esac && \
    curl -L "https://github.com/mikefarah/yq/releases/latest/download/${YQ_BINARY}" -o /usr/bin/yq && \
    chmod +x /usr/bin/yq

# Копируем файл запуска
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Обеспечиваем запуск от root (нужно для /config и tmpfs)
USER root

# Точка входа
CMD ["/run.sh"]

